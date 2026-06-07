extends Node
## Poison modifier behavior — added under a poisonous enemy. When the enemy dies,
## drops a toxic cloud at its position. (The enemy frees right after `died`, so we
## parent the cloud to the level so it lingers.)

const TOXIC_CLOUD := preload("res://enemy/modifiers/poison/toxic_cloud.tscn")

var _enemy: Node3D = null


func _ready() -> void:
	_enemy = get_parent() as Node3D
	if _enemy != null and _enemy.has_signal("died"):
		_enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	if not is_instance_valid(_enemy):
		return
	var cloud := TOXIC_CLOUD.instantiate()
	var layer := get_tree().get_first_node_in_group("entities_layer")
	if layer == null:
		layer = _enemy.get_parent()
	layer.add_child(cloud)
	cloud.global_position = _enemy.global_position
