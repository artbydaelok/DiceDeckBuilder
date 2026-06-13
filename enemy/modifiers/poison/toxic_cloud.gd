extends Area3D
## A lingering toxic cloud — damages the player's Hurtbox while inside, over time,
## then fades. Spawned by the Poison modifier when a poisonous enemy dies.

const DAMAGE := 1
const TICK_INTERVAL := 0.7   # seconds between damage ticks
const LIFETIME := 4.0        # how long the cloud emits + damages
const FADE_TIME := 2.0       # after we stop emitting, time for in-flight particles to fade before freeing

## Optional custom death VFX. If set, it plays in place of the placeholder sphere
## (assign it on the ToxicCloud node in toxic_cloud.tscn). The damage area is unaffected.
@export var death_vfx: PackedScene = null

var _inside: Array = []      # Hurtboxes currently in the cloud


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	var tick := Timer.new()
	tick.wait_time = TICK_INTERVAL
	tick.autostart = true
	add_child(tick)
	tick.timeout.connect(_tick)

	# Emit + damage for LIFETIME, then wind down (stop emitting + disable the hitbox)
	# and free once the in-flight particles have faded out.
	get_tree().create_timer(LIFETIME).timeout.connect(_wind_down)

	# Visual: your custom VFX if assigned, otherwise the placeholder sphere.
	var vis := get_node_or_null("Visual")
	if death_vfx != null:
		add_child(death_vfx.instantiate())
		if vis:
			vis.visible = false
	elif vis:
		# Placeholder sphere: pop in, hold, then shrink away (damage area stays constant).
		vis.scale = Vector3.ZERO
		var tw := vis.create_tween()
		tw.tween_property(vis, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(LIFETIME - 0.8)
		tw.tween_property(vis, "scale", Vector3.ZERO, 0.5)


## Stop emitting + disable the hitbox, then free once the in-flight particles fade.
func _wind_down() -> void:
	var p := get_node_or_null("GPUParticles3D")
	if p != null:
		p.emitting = false
	# Hitbox off the moment we stop emitting — no more damage during the fade.
	set_deferred("monitoring", false)
	_inside.clear()
	get_tree().create_timer(FADE_TIME).timeout.connect(queue_free)


func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox and not _inside.has(area):
		_inside.append(area)


func _on_area_exited(area: Area3D) -> void:
	_inside.erase(area)


func _tick() -> void:
	for hb in _inside:
		if is_instance_valid(hb):
			var owner_node = (hb as Hurtbox).hurtbox_owner
			if owner_node != null and owner_node.has_method("apply_damage"):
				owner_node.apply_damage(DAMAGE)
