extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Console.add_command("load_level", load_level, ["Level Name"])
	Console.add_command("obtain_item", obtain_item, ["Item ID", "Slot"])

func load_level(level_id: String):
	match level_id: 
		"hub":
			SceneLoader.load_scene("res://levels/hub_level.tscn")
		"hell":
			SceneLoader.load_scene("res://levels/fire_demon_level.tscn")
		"forest":
			SceneLoader.load_scene("res://levels/forest_level.tscn")
		"street":
			SceneLoader.load_scene("res://levels/salt_and_pepper_level.tscn")

func obtain_item(item_id : String, slot : String):
	var card_system : CardSystem = get_tree().get_first_node_in_group("card_system")
	var player : Player = get_tree().get_first_node_in_group("player")
	var item = card_system.CARD_ABILITIES_RESOURCES[item_id]
	card_system.set_slot_to_item(slot.to_int(), item)
