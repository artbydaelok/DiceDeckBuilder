extends CanvasLayer
class_name Level

var player: Player
var user_interface: CanvasLayer

@export var level_name: String = "Level Name"

@onready var card_system: CardSystem = $CardSystem
@onready var ui: CanvasLayer = $UI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#DialogueManager.show_dialogue_balloon(HUB_LEVEL_DIALOGUE, "start")
	user_interface = get_tree().get_first_node_in_group("user_interface")
	player = get_tree().get_first_node_in_group("player")
	
	GameEvents.current_level = self

	level_start()

const DICE_INVENTORY_EDITOR = preload("uid://crbwh26bogcfr")

var inventory_ui : Control
var inventory_open : bool

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("view_deck") and not inventory_open:
		inventory_open = true
		inventory_ui = DICE_INVENTORY_EDITOR.instantiate()
		user_interface.add_child(inventory_ui)
	elif event.is_action_pressed("view_deck") and inventory_open:
		inventory_open = false
		inventory_ui.close_menu()
		
	#FIXME: When player exits out using the "Close" button in the menu, inventory_open should be set to false.

func level_start():
	pass
