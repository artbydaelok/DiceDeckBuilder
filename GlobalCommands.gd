extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Console.add_command("load_level", load_level, ["Level Name"], 1, "Loads a level.")
	Console.add_command("obtain_item", obtain_item, ["Item ID", "Slot"], 1, "Gives the player an item assigned to a specific slot. If called without a slot, it will assign it to the top side.")
	Console.add_command("clear_save", clear_save, [], 0, "Deletes the save file and replaces it with a fresh new one.")
	Console.add_command("clear_inventory", clear_inventory, [], 0, "Removes all items that player owns both equipped and in storage.")
	Console.add_command("set_money", set_money, ["Amount"], 1, "Sets the currency to an amount.")
	Console.add_command("set_camera", set_camera, ["Zone Name"], 1, "Switches to a CameraZone by node name.")
	Console.add_command("list_cameras", list_cameras, [], 0, "Lists all CameraZone nodes in the current scene.")
	
func set_money(amount):
	var cs : CurrencySystem= get_tree().get_first_node_in_group("currency_system")
	cs.set_money(amount)
	
func load_level(level_id: String):
	match level_id: 
		"hub":
			SceneLoader.load_scene("res://levels/hub_level.tscn")
		"hell":
			SceneLoader.load_scene("res://levels/fire_demon_level.tscn")
		"forest":
			SceneLoader.load_scene("res://levels/forest_level/forest_level.tscn")
		"street":
			SceneLoader.load_scene("res://levels/salt_and_pepper_level.tscn")

func obtain_item(item_id : String, slot : String):
	var card_system : CardSystem = get_tree().get_first_node_in_group("card_system")
	var player : Player = get_tree().get_first_node_in_group("player")
	var item = card_system.CARD_ABILITIES_RESOURCES[item_id]
	print(slot)
	if slot:
		card_system.set_slot_to_item(slot.to_int(), item)
	else:
		card_system.set_slot_to_item(player.up_side, item)

func clear_save():
	SaveSystem.clear_player_data()
	
func clear_inventory():
	var card_system : CardSystem = get_tree().get_first_node_in_group("card_system")
	card_system.clear_inventory()

func _get_all_camera_zones() -> Array:
	var zones: Array = []
	_collect_camera_zones(get_tree().get_root(), zones)
	return zones

func _collect_camera_zones(node: Node, zones: Array) -> void:
	if node is CameraZone:
		zones.append(node)
	for child in node.get_children():
		_collect_camera_zones(child, zones)

func set_camera(zone_name: String) -> void:
	var zones := _get_all_camera_zones()
	for zone in zones:
		if zone.name == zone_name:
			CameraZoneManager.enter_zone(zone)
			Console.print_info("Switched to camera zone: %s" % zone_name)
			return
	Console.print_error("No CameraZone found with name: %s" % zone_name)

func list_cameras() -> void:
	var zones := _get_all_camera_zones()
	if zones.is_empty():
		Console.print_info("No CameraZone nodes found in the current scene.")
		return
	Console.print_info("Available camera zones:")
	for zone in zones:
		Console.print_line("  - %s" % zone.name)
