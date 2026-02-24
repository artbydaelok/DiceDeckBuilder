extends Node3D

@export var save_system: SaveSystem
@export var checkpoint_data: CheckpointData

@onready var fire_sound_effect: AudioStreamPlayer3D = $FireSFXPlayer3D
@onready var fire_visual_effect: GPUParticles3D = $FireParticles
@onready var smoke_visual_effect: GPUParticles3D = $SmokeParticles
@onready var fast_travel_ui_prompt: Label3D = $InteractionPromptLabel
@onready var fire_light: OmniLight3D = $FireLight

const FAST_TRAVEL_UI = preload("res://core/checkpoint_system/checkpoint_ui.tscn")

var has_effects: bool = false
var has_player: bool = false
var ui: CheckpointUI

func _ready() -> void:
	if fire_sound_effect && fire_visual_effect && smoke_visual_effect && fast_travel_ui_prompt && fire_light:
		has_effects = true
		
	if !save_system:
		save_system = get_tree().get_root().find_child("SaveSystem", true, false)
	
	if !save_system:
		push_warning("save_system is missing or null")
	
	# This puts the teleport location in front of the campfire when a player uses fast travel
	checkpoint_data.spawn_point = global_position + Vector3(0, 0, 2)
	
	var label: Label3D = Label3D.new()
	label.text = "Test"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	
		
func _input(event):
	if !has_player: return
	
	if event.is_action_released("interact"):
		if(!ui):
			ui = FAST_TRAVEL_UI.instantiate()
			get_tree().current_scene.add_child(ui)

func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	# If the save system does not have any data for the current level
	if !save_system.player_data.unlocked_checkpoints.has(checkpoint_data.level):
		# then add this first entry to it
		save_system.player_data.unlocked_checkpoints.set(checkpoint_data.level, [checkpoint_data.resource_path])
	else:
		# Otherwise just add it to the existing dictionary
		var checkpoints = save_system.player_data.unlocked_checkpoints[checkpoint_data.level]
		if !checkpoints.has(checkpoint_data.resource_path):
			checkpoints.append(checkpoint_data.resource_path)
		
	save_system.json_save()
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
