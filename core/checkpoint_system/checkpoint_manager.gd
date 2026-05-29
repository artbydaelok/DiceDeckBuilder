extends Node3D

var save_system: SaveSystem
@export var checkpoint_data: CheckpointData

## The CameraZone that should become active when fast-traveling to this checkpoint.
## Assign in the inspector to whichever CameraZone covers this campfire.
@export var camera_zone: CameraZone

@onready var fire_sound_effect: AudioStreamPlayer3D = $FireSFXPlayer3D
@onready var fire_visual_effect: GPUParticles3D = $FireParticles
@onready var smoke_visual_effect: GPUParticles3D = $SmokeParticles
@onready var fast_travel_ui_prompt: Label3D = $InteractionPromptLabel
@onready var fire_light: OmniLight3D = $FireLight
@onready var player_detection: Area3D = $PlayerDetection

const FAST_TRAVEL_UI = preload("res://core/checkpoint_system/checkpoint_ui.tscn")

var has_effects: bool = false
var has_player: bool = false
var ui: CheckpointUI

var player: Player


func _ready() -> void:
	if fire_sound_effect && fire_visual_effect && smoke_visual_effect && fast_travel_ui_prompt && fire_light:
		has_effects = true

	if !save_system:
		save_system = get_tree().get_root().find_child("SaveSystem", true, false)

	if !save_system:
		push_warning("CheckpointManager: save_system is missing or null")

	player = get_tree().get_first_node_in_group("player")

	player_detection.area_entered.connect(_on_player_entered)
	player_detection.area_exited.connect(_on_player_exited)

	# Same-level fast travel: activate camera zone when this checkpoint is selected.
	GameEvents.checkpoint_fast_traveled.connect(_on_checkpoint_fast_traveled)

	# Cross-level fast travel: if this scene was loaded because of this checkpoint,
	# activate the camera zone now that the scene is ready.
	if GameEvents.is_checkpoint_transfer and GameEvents.current_checkpoint_data == checkpoint_data:
		_activate_camera_zone()


func _input(event: InputEvent) -> void:
	if !has_player: return
	if event.is_action_released("interact"):
		if !ui:
			ui = FAST_TRAVEL_UI.instantiate()
			get_tree().current_scene.add_child(ui)


func _on_player_entered(player_trigger_area: Area3D) -> void:
	# ── Auto-fill level data from runtime context ────────────────────────────
	# level_name, level_path, and spawn_point no longer need to be manually set
	# in the inspector. They are written here on first touch and saved to disk
	# in editor builds so the fast-travel UI can read them from the .tres later.
	# Fill from runtime context — no manual setup needed in the inspector.
	# These are always recomputed when the player touches the checkpoint,
	# so they're correct in both editor and exported builds.
	checkpoint_data.level_name = GameEvents.current_level.level_name
	checkpoint_data.level_path = GameEvents.current_level.scene_file_path
	checkpoint_data.spawn_point = global_position

	# ── Unlock in save data ──────────────────────────────────────────────────
	if !save_system.player_data.unlocked_checkpoints.has(checkpoint_data.level_name):
		save_system.player_data.unlocked_checkpoints.set(
			checkpoint_data.level_name,
			[checkpoint_data.resource_path]
		)
	else:
		var checkpoints: Array = save_system.player_data.unlocked_checkpoints[checkpoint_data.level_name]
		if !checkpoints.has(checkpoint_data.resource_path):
			checkpoints.append(checkpoint_data.resource_path)

	player.heal_player(player.health_component.max_health)
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


func _on_player_exited(player_trigger_area: Area3D) -> void:
	has_player = false
	fast_travel_ui_prompt.visible = false

	if has_effects:
		fire_sound_effect.stop()
		fire_light.visible = false
		fire_visual_effect.emitting = false
		smoke_visual_effect.emitting = false


# ── Camera zone ──────────────────────────────────────────────────────────────

func _on_checkpoint_fast_traveled(data: CheckpointData) -> void:
	if data == checkpoint_data:
		_activate_camera_zone()


func _activate_camera_zone() -> void:
	if camera_zone:
		CameraZoneManager.enter_zone(camera_zone)
	else:
		push_warning("CheckpointManager: camera_zone not assigned on " + name + ". Camera will not switch on fast travel.")
