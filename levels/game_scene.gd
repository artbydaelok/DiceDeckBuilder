extends CanvasLayer
class_name Level

var player: Player
var user_interface: CanvasLayer

@onready var card_system: CardSystem = $CardSystem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#DialogueManager.show_dialogue_balloon(HUB_LEVEL_DIALOGUE, "start")
	user_interface = get_tree().get_first_node_in_group("user_interface")
	player = get_tree().get_first_node_in_group("player")
	
	GameEvents.current_level = self

	level_start()

func level_start():
	pass
