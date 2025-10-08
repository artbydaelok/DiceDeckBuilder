extends CanvasLayer

const HUB_LEVEL_DIALOGUE = preload("uid://b2og4ilgdg4ke")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogueManager.show_dialogue_balloon(HUB_LEVEL_DIALOGUE, "start")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	GameEvents.cutscene_started.emit(true)
	
func _on_dialogue_ended(dialogue_resource):
	GameEvents.cutscene_ended.emit()
