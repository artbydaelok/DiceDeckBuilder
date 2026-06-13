extends Node
class_name CreatureAnimator
## Procedural "juice" for models that have no hand-keyframed rig. Add it as a child of
## a creature (e.g. an Enemy) and point `visual` at the model node. It animates the
## model entirely in code — idle bob, spawn pop, hop, hit-react squash, death splat —
## so simple enemies feel alive with zero keyframing.
##
## Auto-wiring (when `auto_wire` is on):
##   • spawn pop + idle bob start automatically
##   • a `damaged` signal on the parent → hit_react()
##   • a sibling component's `step_started` signal (e.g. GridMoverComponent) → hop()
##   • death is driven by the parent: Enemy.on_died() calls play_death() and frees
##     once `death_finished` fires.
##
## Everything is squash/stretch on the model's local transform, so it rides along with
## the creature's real (tile) movement.

@export var visual: Node3D                  # the model to animate; auto-found if left empty
@export var auto_wire: bool = true          # hook the parent's damaged/move signals automatically

@export_group("Idle bob")
@export var idle_bob: bool = true
@export var bob_height: float = 0.07
@export var bob_speed: float = 1.4          # cycles per second

@export_group("Hop")
@export var auto_hop_on_move: bool = true   # hop whenever a sibling mover takes a step
@export var hop_height: float = 0.5

signal death_finished

var _base_pos := Vector3.ZERO
var _base_scale := Vector3.ONE
var _idling := false
var _t := 0.0
var _oneshot: Tween


func _ready() -> void:
	if visual == null:
		visual = _find_visual()
	if visual == null:
		push_warning("CreatureAnimator: no `visual` assigned/found on " + str(get_parent()))
		set_process(false)
		return
	_base_pos = visual.position
	_base_scale = visual.scale
	if auto_wire:
		_wire()
	spawn_pop()


func _process(delta: float) -> void:
	if not _idling:
		return
	_t += delta
	visual.position.y = _base_pos.y + sin(_t * bob_speed * TAU) * bob_height


# ── One-shots ──────────────────────────────────────────────────────────────────

## Scale in from nothing with an overshoot. Auto-played on spawn.
func spawn_pop(time := 0.3) -> void:
	_idling = false
	visual.scale = _base_scale * 0.01
	_oneshot = _fresh()
	_oneshot.tween_property(visual, "scale", _base_scale, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_oneshot.tween_callback(_start_idle)


## Crouch → leap (stretch) → land (squash). Pair with the creature's real tile move.
func hop(height := -1.0, time := 0.32) -> void:
	if height < 0.0:
		height = hop_height
	_idling = false
	_oneshot = _fresh()
	_oneshot.tween_property(visual, "scale", _sq(0.85), time * 0.18)
	_oneshot.tween_property(visual, "scale", _sq(1.12), time * 0.22)
	_oneshot.parallel().tween_property(visual, "position:y", _base_pos.y + height, time * 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_oneshot.tween_property(visual, "position:y", _base_pos.y, time * 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_oneshot.parallel().tween_property(visual, "scale", _sq(0.9), time * 0.2)
	_oneshot.tween_property(visual, "scale", _base_scale, time * 0.15)
	_oneshot.tween_callback(_start_idle)


## A snappy hit reaction (scale punch). Overlays the idle bob without disturbing it.
func hit_react() -> void:
	var tw := create_tween()
	tw.tween_property(visual, "scale", _sq(0.7), 0.06)
	tw.tween_property(visual, "scale", _base_scale, 0.2) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Gasp up, spin, then splat flat. Emits death_finished when done (caller frees).
func play_death(time := 0.45) -> void:
	_idling = false
	_oneshot = _fresh()
	_oneshot.tween_property(visual, "scale", _sq(1.3), time * 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_oneshot.parallel().tween_property(visual, "rotation:y", visual.rotation.y + TAU, time)
	_oneshot.tween_property(visual, "scale", Vector3(_base_scale.x * 1.5, 0.001, _base_scale.z * 1.5), time * 0.8) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_oneshot.tween_callback(func(): death_finished.emit())


# ── Internals ──────────────────────────────────────────────────────────────────

func _wire() -> void:
	var p := get_parent()
	if p == null:
		return
	if p.has_signal("damaged"):
		p.damaged.connect(func(_amount = 0): hit_react())
	if auto_hop_on_move:
		for c in p.get_children():
			if c != self and c.has_signal("step_started"):
				c.step_started.connect(func(_dir): hop())
				break


func _start_idle() -> void:
	if idle_bob:
		_idling = true


func _fresh() -> Tween:
	if _oneshot != null and _oneshot.is_valid():
		_oneshot.kill()
	return create_tween()


## Volume-preserving squash/stretch of the base scale. k<1 squashes (short + wide),
## k>1 stretches (tall + thin).
func _sq(k: float) -> Vector3:
	var inv := 1.0 / sqrt(k)
	return Vector3(_base_scale.x * inv, _base_scale.y * k, _base_scale.z * inv)


func _find_visual() -> Node3D:
	var p := get_parent()
	if p == null:
		return null
	for n in ["Visuals", "Visual", "Mesh", "Model"]:
		var c = p.get_node_or_null(n)
		if c is Node3D:
			return c
	return null
