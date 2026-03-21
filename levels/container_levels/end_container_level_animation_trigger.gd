extends Area3D

@export var player : Player
@export var player_cutscene_actor : Node3D
@export var sfx : AudioStreamPlayer

@export var custom_pivot : Node3D
@export var custom_pivot_offset : Vector3 = Vector3.ZERO


func _ready() -> void:
	area_entered.connect(_on_player_entered)

func _on_player_entered(area):
	trigger_animation()

func trigger_animation():
	GameEvents.cutscene_started.emit(true)
	await player.roll_finished
	# Makes player cutscene actor visible
	player_cutscene_actor.visible = true
	player_cutscene_actor.global_position = player.global_position
	
	custom_pivot.global_position = player_cutscene_actor.global_position + Vector3(0, 1.0, 0)
	player_cutscene_actor.reparent(custom_pivot)
		
	# Makes player actor invisible
	player.visible = false
	
	var initial_pos = global_position
	var initial_rot = global_rotation
	
	player_cutscene_actor.free_falling = true
	player_cutscene_actor.falling_rotation_velocity = Vector3(-4, 0, 0)
	
	var tween = create_tween()
	tween.tween_property(custom_pivot, "global_position", initial_pos + Vector3(0, -25, -15), 3.0)
	get_tree().get_first_node_in_group("game_camera").apply_shake(1.0)
	sfx.play()
	
