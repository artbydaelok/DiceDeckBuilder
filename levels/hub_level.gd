extends "res://levels/game_scene.gd"

@onready var cutscene_animation_player: AnimationPlayer = %CutsceneAnimationPlayer

@onready var player_camera_3d: Camera3D = $BaseLevel/Camera3D
@onready var ui: CanvasLayer = $UI

const HUB_LEVEL_DIALOGUE = preload("uid://b2og4ilgdg4ke")
const DICE_INVENTORY_EDITOR = preload("uid://crbwh26bogcfr")

# This should only work in the HUB level.
var inventory_ui : Control
var inventory_open : bool

@export var first_time_cutscene : bool = false

# Called when the node enters the scene tree for the first time.
func level_start() -> void:
	if first_time_cutscene:
		GameEvents.cutscene_started.emit(true)
		cutscene_animation_player.play("0_first_time")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("view_deck") and not inventory_open:
		player._disable_input()
		inventory_open = true
		inventory_ui = DICE_INVENTORY_EDITOR.instantiate()
		user_interface.add_child(inventory_ui)
	elif event.is_action_pressed("view_deck") and inventory_open:
		player._enable_input()
		inventory_open = false
		inventory_ui.queue_free()
		
	#FIXME: When player exits out using the "Close" button in the menu, inventory_open should be set to false.
		
func end_cutscene():
	GameEvents.cutscene_ended.emit()
	player_camera_3d.current = true
	ui.visible = true
