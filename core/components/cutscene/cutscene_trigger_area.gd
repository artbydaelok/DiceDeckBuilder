extends Node3D

@export var dialogue_resource : DialogueResource
@export var title_to_play : String = "start"
@export var one_shot : bool = false
@export var disables_player_movement : bool = true

@onready var player_detection: Area3D = $PlayerDetection


func _ready() -> void:
	player_detection.area_entered.connect(_on_player_detection_body_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_player_detection_body_entered(area: Area3D) -> void:
	GameEvents.cutscene_started.emit(disables_player_movement)
	var d = DialogueManager.show_dialogue_balloon(dialogue_resource, title_to_play)
	
func _on_dialogue_ended(dialogue):
	GameEvents.cutscene_ended.emit.call_deferred()
	if one_shot:
		queue_free()
	
