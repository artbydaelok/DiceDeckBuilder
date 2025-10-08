extends Node3D

const INTRO_SEQUENCE = preload("uid://db38wbqk61xvt")


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
func _on_dialogue_ended(dialogue_resource):
	GameEvents.cutscene_ended.emit()


func _on_player_detection_body_entered(body: Node3D) -> void:
	GameEvents.cutscene_started.emit(true)
	var d = DialogueManager.show_dialogue_balloon(INTRO_SEQUENCE, "start")
