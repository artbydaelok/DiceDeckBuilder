extends Node

@onready var fire_sound_effect: AudioStreamPlayer3D = $FireSFXPlayer3D
@onready var fire_visual_effect: GPUParticles3D = $FireParticles
@onready var smoke_visual_effect: GPUParticles3D = $SmokeParticles
@onready var fast_travel_ui_prompt: MeshInstance3D = $Interaction_Prompt
@onready var fire_light: OmniLight3D = $FireLight

const FAST_TRAVEL_UI = preload("res://core/checkpoint_system/checkpoint_ui.tscn")

var has_effects: bool = false
var has_player: bool = false
var fast_travel_ui_open: bool = false

func _ready() -> void:
	if fire_sound_effect && fire_visual_effect && smoke_visual_effect && fast_travel_ui_prompt && fire_light:
		has_effects = true
		
	var label: Label3D = Label3D.new()
	label.text = "Test"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
		
func _input(event):
	if !has_player || fast_travel_ui_open: return
	
	if event.is_action_released("use_ability"):
		fast_travel_ui_open = true
		var ui = FAST_TRAVEL_UI.instantiate()
		get_tree().current_scene.add_child(ui)

func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	has_player = true
	fast_travel_ui_prompt.visible = true
	
	if has_effects:
		fire_sound_effect.play()
		fire_visual_effect.restart()
		smoke_visual_effect.restart()
		fire_light.visible = true
		fire_visual_effect.emitting = true
		smoke_visual_effect.emitting = true
		
func _on_area_3d_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	has_player = false
	fast_travel_ui_prompt.visible = false
	
	if has_effects:
		fire_sound_effect.stop()
		fire_light.visible = false
		fire_visual_effect.emitting = false
		smoke_visual_effect.emitting = false
