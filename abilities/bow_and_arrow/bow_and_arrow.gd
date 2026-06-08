extends Ability
## Bow & Arrow — PRIMARY input, two-phase charge using the rigged bow GLB.
## Hold to draw (the pull animation is driven by the charge, not its own clock),
## release to loose. Charge scales the arrow's speed/damage; a full draw crits.
##
## The GLB has one clip, "Armature|pull and realease": it pulls then releases.
## While charging we freeze it (speed 0) and seek into the PULL portion from the
## charge; on release we let it play out (the string snaps) and spawn the arrow.

const BOW_MODEL := preload("res://abilities/bow_and_arrow/rigged_bow__arrow.glb")
const ARROW_PROJECTILE := preload("res://abilities/bow_and_arrow/arrow_projectile.tscn")
## The game's existing arrow mesh — used as the visible nocked arrow while drawing.
const ARROW_VISUAL := preload("res://abilities/bow_and_arrow/Arrow.glb")

const PULL_ANIM := "Armature|pull and realease"

# ── Tunables ──────────────────────────────────────────────────────────────────
## Charge seconds for a full draw (keep matched to the arrow's FULL_CHARGE).
const FULL_DRAW_TIME := 1.0
## Clip time of the fully-drawn pose, just before the string releases. TUNE.
const DRAW_END_TIME := 0.6
## Seconds after release (clip resuming) until the string actually looses. TUNE.
const LOOSE_DELAY := 0.12
## Clip length, used to time cleanup of the bow model.
const ANIM_LENGTH := 1.05
## Bow model placement relative to the player. TUNE (Sketchfab scale/orientation varies).
## The raw model is ~50 units tall (limbs) with a 171-unit-long cone, so it needs
## scaling way down to sit near the 2-unit die.
const MODEL_OFFSET := Vector3(0, 2.5, 0)
const MODEL_SCALE := 0.01
## Hide the model's own rigged arrow shaft (it nocks at the wrong spot). We nock
## the game's existing Arrow.glb on the string instead (see the nocked-arrow consts).
const HIDE_MESHES := ["Cone_Material_004_0"]

# ── Nocked arrow (the visible arrow on the string while drawing) ──
## Placement is WORLD-space relative to the player — TUNE on screen.
const ARROW_NOCK_OFFSET := Vector3(0, 2.5, -2.5)   # where it sits when nocked
const ARROW_SCALE := 0.5
const ARROW_DRAW_BACK := 1.5       # how far it pulls back (+Z, toward you) at full draw
const ARROW_LOAD_FRACTION := 0.15  # charge fraction it scales in over (loads onto the string)

# ── Secondary volley (3 arrows lobbed onto a target tile ahead) ──
const ARC_ARROW := preload("res://abilities/bow_and_arrow/arc_arrow.gd")

# Where it lands / damage:
const VOLLEY_DISTANCE := 8.0      # how far ahead (-Z) the center arrow lands (~4 tiles)s
const VOLLEY_SPREAD := 2.0        # left/right tile offset for the two side arrows
const VOLLEY_DAMAGE := 5

# Placement — the bow and the 3 arrows move INDEPENDENTLY:
const VOLLEY_BOW_POS := Vector3(0, 2.5, 1.5)   # ① where the bow sits  (moves the bow ONLY)
const VOLLEY_NOCK_POS := Vector3(0, 2.5, 1.5)  # ② line the arrows up with the grip (left/up/back)
const VOLLEY_NOCK_SLIDE := 2.0            # ③ slide arrows along their LENGTH so the nock sits on the string — RAISE if tails sit past it
const VOLLEY_DRAW_BACK := 0.6                  # ④ how far the arrows pull back as you draw
const VOLLEY_NOCK_UP := 1.5                    # ⑤ how steeply the trio angles up
const VOLLEY_BOW_PITCH := 45.0                 # ⑥ how far the bow tilts up

# Timing:
const VOLLEY_DRAW_TIME := 0.35    # auto-draw time when the card isn't chargeable

var _model: Node3D = null
var _holder: Node3D = null
var _anim: AnimationPlayer = null
var _loosed := false
var _arrow: Node3D = null         # the visible nocked arrow (primary)
var _arrow_base := Vector3.ZERO   # its nocked world position (pulls back from here)
var _nocks: Array = []            # the three nocked arrows for the secondary volley


func initialize() -> void:
	# We manage the model's lifetime ourselves.
	if self_destroy_timer != null and self_destroy_timer.has_method("cancel"):
		self_destroy_timer.cancel()

	# Holder owns placement/scale/rotation so nothing inside the GLB can fight it.
	_holder = Node3D.new()
	entities_layer.add_child(_holder)
	var orient := _bow_basis()
	var pos := player.global_position + MODEL_OFFSET
	if is_secondary:
		orient = Basis(Vector3.RIGHT, deg_to_rad(VOLLEY_BOW_PITCH)) * orient  # tilt up for the volley
		pos = player.global_position + VOLLEY_BOW_POS                         # bow placement (arrows are separate)
	var b := orient.scaled(Vector3.ONE * MODEL_SCALE)
	_holder.global_transform = Transform3D(b, pos)

	_model = BOW_MODEL.instantiate()
	# Hide only the oversized aim-spike; keep the bow + rigged arrow visible.
	for mesh_node in _model.find_children("*", "MeshInstance3D", true, false):
		if str(mesh_node.name) in HIDE_MESHES:
			(mesh_node as Node3D).visible = false
	_holder.add_child(_model)

	# Nock the game's Arrow.glb on the string (loads in + pulls back with the draw).
	if is_charging:
		_arrow_base = player.global_position + ARROW_NOCK_OFFSET
		_arrow = ARROW_VISUAL.instantiate()
		entities_layer.add_child(_arrow)
		_update_arrow(0.0)   # places + hides the nocked arrow (orientation via _arrow_basis)

	_anim = _model.get_node_or_null("AnimationPlayer")
	if _anim:
		_anim.play(PULL_ANIM)

	if is_secondary:
		if _anim:
			_anim.speed_scale = 0.0   # the draw is driven by the charge
		_setup_volley_nocks()
		_update_volley_draw(0.0)
		if not is_charging:
			# instant fallback (card not chargeable): auto-draw then loose.
			var tw := create_tween()
			tw.tween_method(_update_volley_draw, 0.0, FULL_DRAW_TIME, VOLLEY_DRAW_TIME)
			tw.tween_callback(_loose_volley)
			get_tree().create_timer(VOLLEY_DRAW_TIME + ANIM_LENGTH).timeout.connect(_free_all)
	elif _anim:
		if is_charging:
			_anim.speed_scale = 0.0   # we drive the pull manually from the charge
			_set_draw(0.0)
		else:
			# Instant fire fallback: play through and loose.
			_anim.speed_scale = 1.0
			_loose_after_delay()
			get_tree().create_timer(ANIM_LENGTH).timeout.connect(_free_all)


## Orientation of the bow, set directly (no Euler → no gimbal lock). Columns are
## where the model's local X / Y / Z axes point in world space. The raw model aims
## along -X with limbs along Y; this lays it horizontal, aiming forward (-Z):
##   local X (→ aim) → world Z,  local Y (limbs) → world X,  local Z (face) → world Y.
## If it comes out backwards/upside-down, flip a column's sign.
func _bow_basis() -> Basis:
	return Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))


## Driven each frame by CardSystem while held — maps charge seconds to the pull pose.
func set_charge_progress(seconds: float) -> void:
	if is_secondary:
		_update_volley_draw(seconds)
	else:
		_set_draw(seconds)


func _set_draw(seconds: float) -> void:
	if _anim == null:
		return
	var t := clampf(seconds / FULL_DRAW_TIME, 0.0, 1.0)
	_anim.seek(t * DRAW_END_TIME, true)
	_update_arrow(t)


## Loads the nocked arrow onto the string (scales in) then pulls it back with the draw.
## Sets the whole transform each frame so the orientation is never lost to a 0 scale.
func _update_arrow(t: float) -> void:
	if not is_instance_valid(_arrow):
		return
	var s := clampf(t / ARROW_LOAD_FRACTION, 0.0, 1.0)
	var pos := _arrow_base + Vector3(0, 0, ARROW_DRAW_BACK * t)
	var b := _arrow_basis().scaled(Vector3.ONE * ARROW_SCALE * s)
	_arrow.global_transform = Transform3D(b, pos)


## Points the nocked arrow forward (-Z), down-range. Arrow.glb's shaft runs along
## its local +X (it flies -Z in arrow_projectile with a +90° Y rotation), so we map
## local +X → world -Z. Flip a column's sign if it ends up pointing the wrong way.
func _arrow_basis() -> Basis:
	return Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))


func on_charge_release() -> void:
	if is_secondary:
		_loose_volley()
		get_tree().create_timer(ANIM_LENGTH).timeout.connect(_free_all)
		return
	if _anim:
		_anim.speed_scale = 1.0   # resume from the drawn pose → the string snaps
	_loose_after_delay()
	get_tree().create_timer(ANIM_LENGTH).timeout.connect(_free_all)


func on_charge_cancel() -> void:
	_free_all()


# ── Internals ─────────────────────────────────────────────────────────────────

func _loose_after_delay() -> void:
	get_tree().create_timer(LOOSE_DELAY).timeout.connect(_loose)


func _loose() -> void:
	if _loosed:
		return
	_loosed = true
	if is_instance_valid(_arrow):
		_arrow.queue_free()   # the nocked visual hands off to the flying projectile
	var arrow = ARROW_PROJECTILE.instantiate()
	entities_layer.add_child(arrow)
	if is_instance_valid(_model):
		arrow.global_position = _model.global_position
	else:
		arrow.global_position = player.global_position + MODEL_OFFSET
	if "charge" in arrow:
		arrow.charge = charge


## Secondary: spawn the three arrows angled toward their lob targets (hidden until
## the draw loads them in).
func _setup_volley_nocks() -> void:
	for entry in _volley_nock_data():
		var nock := ARROW_VISUAL.instantiate()
		entities_layer.add_child(nock)
		_nocks.append({"node": nock, "dir": entry[0], "pos": entry[1]})


## [direction, nock-position] for each of the three volley arrows (angled up + spread).
func _volley_nock_data() -> Array:
	var from := player.global_position + VOLLEY_NOCK_POS
	var target := player.global_position + Vector3(0, 0, -VOLLEY_DISTANCE)
	var data := []
	for off in [Vector3.ZERO, Vector3(-VOLLEY_SPREAD, 0, 0), Vector3(VOLLEY_SPREAD, 0, 0)]:
		var dir: Vector3 = ((target + off - from).normalized() + Vector3.UP * VOLLEY_NOCK_UP).normalized()
		data.append([dir, from])
	return data


## Draws the bow + loads the three nocked arrows from the charge, so they SIT
## nocked while held (like the primary shot) until release.
func _update_volley_draw(seconds: float) -> void:
	var t := clampf(seconds / FULL_DRAW_TIME, 0.0, 1.0)
	if _anim:
		_anim.seek(t * DRAW_END_TIME, true)
	var s := clampf(t / ARROW_LOAD_FRACTION, 0.0, 1.0)
	for n in _nocks:
		var node = n["node"]
		if is_instance_valid(node):
			var dir: Vector3 = n["dir"]
			# Rest at VOLLEY_NOCK_POS (n["pos"]), then pull back
			# along −dir as it draws. Keep the _aim_basis(dir) rotation so it stays on-axis.
			var pos: Vector3 = n["pos"] + dir * (VOLLEY_NOCK_SLIDE - VOLLEY_DRAW_BACK * t)
			node.global_transform = Transform3D(_aim_basis(dir).scaled(Vector3.ONE * ARROW_SCALE * s), pos)


## Orient an arrow so its head leads along `dir`. Arrow.glb's head points down its
## local -X, so local +X maps to -dir.
func _aim_basis(dir: Vector3) -> Basis:
	var x := -dir.normalized()
	var up_ref := Vector3.UP if absf(x.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var z := x.cross(up_ref).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)


## Loose the volley: drop the nocked arrows, snap the string, fire the three arcs.
func _loose_volley() -> void:
	for n in _nocks:
		if is_instance_valid(n["node"]):
			n["node"].queue_free()
	_nocks.clear()
	if _anim:
		_anim.speed_scale = 1.0   # release

	var from := player.global_position + VOLLEY_NOCK_POS
	var target := player.global_position + Vector3(0, 0, -VOLLEY_DISTANCE)
	for off in [Vector3.ZERO, Vector3(-VOLLEY_SPREAD, 0, 0), Vector3(VOLLEY_SPREAD, 0, 0)]:
		var a = ARC_ARROW.new()
		a.setup(from, target + off, VOLLEY_DAMAGE)
		entities_layer.add_child(a)


func _free_all() -> void:
	if is_instance_valid(_holder):
		_holder.queue_free()
	if is_instance_valid(_arrow):
		_arrow.queue_free()
	for n in _nocks:
		if is_instance_valid(n["node"]):
			n["node"].queue_free()
	queue_free()
