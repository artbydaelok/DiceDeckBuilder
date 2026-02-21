extends Node
class_name SaveSystem

signal update_player_data(player_data:PlayerData)

const OPTIONS_SAVE_PATH := "user://options_data.tres"
const SAVE_PATH = "user://game_save.sav"
const SECURITY_KEY = "a24542a81874eb33776acfaa561dce67"

@export var player_data : PlayerData = PlayerData.new()
#@export var options_data : OptionsData = OptionsData.new()

func verify_save_directory(path: String):
	DirAccess.make_dir_absolute(path)
	
func _ready():
	#DirAccess.remove_absolute(SAVE_PATH)
	load_player_data()
	
func save_player_data():
	json_save()
	
#func save_options_data():
	#json_save_options()
	
func load_player_data():
	json_load()
	
#func load_options_data():
	#json_load_options()
	
func clear_player_data():
	DirAccess.remove_absolute(SAVE_PATH)
	player_data = PlayerData.new()
	
func clear_options_data():
	DirAccess.remove_absolute(OPTIONS_SAVE_PATH)
	#options_data = OptionsData.new()

func json_save():
	print("json_save")
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, SECURITY_KEY)
	#var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print(FileAccess.get_open_error())
		return
		
	var equipped_cards: Array[String] = []
	var inventory_cards: Array[String] = []
	
	for card in player_data.equipped_cards:
		if card == null:
			equipped_cards.append("")
		else:
			print(card)
			equipped_cards.append(card.resource_path)
	
	for card in player_data.inventory_cards:
		if card == null:
			inventory_cards.append("")
		else:
			inventory_cards.append(card.resource_path)
		
	var data = \
		{
			"general": {
				"patch_number" = player_data.patch_number,
				"is_mobile" = player_data.is_mobile,
				"using_controller" = player_data.using_controller
			},
			
			"player_stats": {
				"health" = player_data.health,
			},
			
			"inventory": {
				"equipped_cards": equipped_cards,
				"inventory_cards": inventory_cards,
			},
			
			"progression": {
				"current_level"= player_data.current_level,
				"tutorial_completed"= player_data.tutorial_completed,
				"unlocked_checkpoints" = player_data.unlocked_checkpoints,
				"level_one_completed"= player_data.level_one_completed,
				"level_two_completed"= player_data.level_two_completed,
				"level_three_completed"= player_data.level_three_completed,
				"level_four_completed"= player_data.level_four_completed,
				"level_five_completed"= player_data.level_five_completed
			},
			
			"demo": {
				"is_demo"= player_data.is_demo,
				"demo_completed"= player_data.demo_completed
			}
		}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

func make_empty_save():
	var fresh_player_data = PlayerData.new()

	var fresh_save_data = \
		{
			"general": {
				"patch_number" = fresh_player_data.patch_number,
				"is_mobile" = fresh_player_data.is_mobile
			},
			
			"player_stats": {
				"health" = fresh_player_data.health,
			},
			
			"inventory": {
				"equipped_cards": ["", "", "", "", "", ""],
				"inventory_cards": [],
			},
			
			"progression": {
				"current_level"= fresh_player_data.current_level,
				"tutorial_completed"= fresh_player_data.tutorial_completed,
				"unlocked_checkpoints" = player_data.unlocked_checkpoints,
				"level_one_completed"= fresh_player_data.level_one_completed,
				"level_two_completed"= fresh_player_data.level_two_completed,
				"level_three_completed"= fresh_player_data.level_three_completed,
				"level_four_completed"= fresh_player_data.level_four_completed,
				"level_five_completed"= fresh_player_data.level_five_completed
			},
			
			"demo": {
				"is_demo"= fresh_player_data.is_demo,
				"demo_completed"= fresh_player_data.demo_completed
			}
		}
	
	return fresh_save_data
	
func check_missing_keys(data_to_compare : Dictionary):
	# This creates a fresh save file to compare which keys are missing
	var fresh_save_to_compare = make_empty_save()
	
	for key in fresh_save_to_compare.general.keys():
		if key not in data_to_compare.general.keys():
			print(key + " not in Save File. Adding it now.")
			data_to_compare.general[key] = fresh_save_to_compare.general[key]
			
	for key in fresh_save_to_compare.player_stats.keys():
		if key not in data_to_compare.player_stats.keys():
			print(key + " not in Save File. Adding it now.")
			data_to_compare.player_stats[key] = fresh_save_to_compare.player_stats[key]
			
	for key in fresh_save_to_compare.progression.keys():
		if key not in data_to_compare.progression.keys():
			print(key + " not in Save File. Adding it now.")
			data_to_compare.progression[key] = fresh_save_to_compare.progression[key]
			
	for key in fresh_save_to_compare.demo.keys():
		if key not in data_to_compare.demo.keys():
			print(key + " not in Save File. Adding it now.")
			data_to_compare.demo[key] = fresh_save_to_compare.demo[key]
			
	return data_to_compare

func json_load():
	print("json_load")
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, SECURITY_KEY)
		#var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file == null:
			print(FileAccess.get_open_error())
			return
			
		var content = file.get_as_text()
		file.close()
		
		var loaded_data = JSON.parse_string(content)
		loaded_data = check_missing_keys(loaded_data)
			
		var equipped_cards: Array[Card] = []
		var inventory_cards: Array[Card] = []
		var unlocked_checkpoints: Dictionary = {}
		
		if loaded_data.inventory.equipped_cards.size() > 0:
			for card in loaded_data.inventory.equipped_cards:
				if card == "" || card == null:
					equipped_cards.append(null)
				else:
					var c : Card = load(card)
					equipped_cards.append(c)
			
		for card in loaded_data.inventory.inventory_cards:
			if card != "" || card != null:
				inventory_cards.append(load(card))
			
		player_data.health = loaded_data.player_stats.health
		player_data.equipped_cards = equipped_cards
		player_data.inventory_cards = inventory_cards
		player_data.patch_number = loaded_data.general.patch_number
		player_data.using_controller = loaded_data.general.using_controller
		player_data.is_mobile = loaded_data.general.is_mobile
		player_data.current_level = loaded_data.progression.current_level
		player_data.tutorial_completed = loaded_data.progression.tutorial_completed
		player_data.unlocked_checkpoints = loaded_data.progression.unlocked_checkpoints
		player_data.level_one_completed = loaded_data.progression.level_one_completed
		player_data.level_two_completed = loaded_data.progression.level_two_completed
		player_data.level_three_completed = loaded_data.progression.level_three_completed
		player_data.level_four_completed = loaded_data.progression.level_four_completed
		player_data.level_five_completed = loaded_data.progression.level_five_completed
		player_data.is_demo = loaded_data.demo.is_demo
		player_data.demo_completed = loaded_data.demo.demo_completed
		
		update_player_data.emit(player_data)
		
func _on_card_system_card_slotted(card: Card, slot: int) -> void:
	player_data.equipped_cards[slot] = card
	save_player_data()
