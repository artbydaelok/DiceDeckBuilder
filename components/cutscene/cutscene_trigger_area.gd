extends Node3D

@export var dialogue_resource : DialogueResource
@export var title_to_play : String = "start"

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
func _on_dialogue_ended(dialogue_resource):
	GameEvents.cutscene_ended.emit()


func _on_player_detection_body_entered(body: Node3D) -> void:
	GameEvents.cutscene_started.emit(true)
	var d = DialogueManager.show_dialogue_balloon(dialogue_resource, title_to_play)
