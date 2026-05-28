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

	# Position the actor first
	player_cutscene_actor.visible = true
	player_cutscene_actor.global_position = player.global_position

	# Borrow the player's real pivot/mesh — this is the new line
	player_cutscene_actor.borrow_from_player()

	custom_pivot.global_position = player_cutscene_actor.global_position + Vector3(0, 1.0, 0)
	player_cutscene_actor.reparent(custom_pivot)

	# Hide what's left of the player (GridMesh etc.)
	player.visible = false

	player_cutscene_actor.free_falling = true
	player_cutscene_actor.falling_rotation_velocity = Vector3(randf(), randf(), randf()) + Vector3.LEFT*2.0 # Not sure why left sends the player forward.

	var tween = create_tween()
	tween.tween_property(custom_pivot, "global_position", global_position + Vector3(0, -25, -15), 3.0)
	sfx.play()
	
