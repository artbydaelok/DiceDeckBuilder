extends Area3D
## A lingering toxic cloud — damages the player's Hurtbox while inside, over time,
## then fades. Spawned by the Poison modifier when a poisonous enemy dies.

const DAMAGE := 1
const TICK_INTERVAL := 0.7   # seconds between damage ticks
const LIFETIME := 4.0        # how long the cloud lingers

var _inside: Array = []      # Hurtboxes currently in the cloud


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	var tick := Timer.new()
	tick.wait_time = TICK_INTERVAL
	tick.autostart = true
	add_child(tick)
	tick.timeout.connect(_tick)

	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

	# Pop in, hold, then shrink away (visual only — the damage area stays constant).
	var vis := get_node_or_null("Visual")
	if vis:
		vis.scale = Vector3.ZERO
		var tw := vis.create_tween()
		tw.tween_property(vis, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(LIFETIME - 0.8)
		tw.tween_property(vis, "scale", Vector3.ZERO, 0.5)


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
