extends "res://levels/game_scene.gd"

@onready var cutscene_animation_player: AnimationPlayer = %CutsceneAnimationPlayer

@onready var player_camera_3d: Camera3D = $BaseLevel/Camera3D

const HUB_LEVEL_DIALOGUE = preload("uid://b2og4ilgdg4ke")


@export var first_time_cutscene : bool = false

# Called when the node enters the scene tree for the first time.
func level_start() -> void:
	if first_time_cutscene:
		GameEvents.cutscene_started.emit(true)
		cutscene_animation_player.play("0_first_time")
		
func end_cutscene():
	GameEvents.cutscene_ended.emit()
	player_camera_3d.current = true
	ui.visible = true
