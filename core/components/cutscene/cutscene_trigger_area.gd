extends Node3D

@export var dialogue_resource : DialogueResource
@export var title_to_play : String = "start"

@export var has_scene_change : bool = false

@onready var player_detection: Area3D = $PlayerDetection

func _ready() -> void:
	player_detection.area_entered.connect(_on_player_detection_body_entered)

func _on_player_detection_body_entered(area: Area3D) -> void:
	GameEvents.cutscene_started.emit(true)
	var d = DialogueManager.show_dialogue_balloon(dialogue_resource, title_to_play)
	
