extends RigidBody3D

const EXPLOSION_BLAST = preload("res://vfx/explosion_blast.tscn")
const FLOOR_INDICATOR = preload("res://enemy/boss/floor_indicator.tscn")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var floor_indicator

signal exploded(this_barrel)

# This is used for reference to block off the tile. 
var spawn_pos : Vector3

func _ready() -> void:
	place_warning.call_deferred()

func place_warning():
	floor_indicator = FLOOR_INDICATOR.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(floor_indicator)
	floor_indicator.global_position = global_position + Vector3(0, -9.85, 0)

func explode():
	# Spawn VFX and Hitbox
	var blast = EXPLOSION_BLAST.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position
	exploded.emit(self)
	if floor_indicator != null:
		floor_indicator.queue_free()
	
	# Remove Blocked Position from player node
	get_tree().get_first_node_in_group("player").remove_blocked_pos(Vector2(spawn_pos.x / 2, spawn_pos.z / 2))
	# Destroy Grenade
	queue_free()


func _on_bullet_and_player_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy_projectiles"):
		body.queue_free()
	explode()


func _on_body_entered(body: Node) -> void:
	if floor_indicator != null:
		floor_indicator.queue_free()
	animation_player.play("landing")
	get_tree().get_first_node_in_group("player").add_blocked_pos(Vector2(spawn_pos.x / 2, spawn_pos.z / 2))


func _on_other_triggers_area_entered(area: Area3D) -> void:
	explode()
