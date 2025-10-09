extends CanvasLayer

const HUB_LEVEL_DIALOGUE = preload("uid://b2og4ilgdg4ke")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DialogueManager.show_dialogue_balloon(HUB_LEVEL_DIALOGUE, "start")
	GameEvents.cutscene_started.emit(true)
