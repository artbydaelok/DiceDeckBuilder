extends Node
## Tracks quest progress and grants rewards. Registered as the `QuestManager` autoload.
##
## Progress is stored in SaveSystem.player_data.quest_progress, keyed by quest id:
##   { "q_first_blood": { "progress": 1, "completed": true, "claimed": false }, ... }
##
## Derived quest types (player_data_bool, enemy_kills, total_kills, enemy_types_met,
## all_slots_equipped, currency) are recomputed on demand from PlayerData. "event"
## quests accumulate progress via signal handlers and store it in the entry.
##
## Public API:
##   get_progress(quest_id)  -> { "progress": int, "completed": bool, "claimed": bool }
##   check_all()             -> recompute every derived quest; emit updates. Call on hub entry.
##   claim_reward(quest_id)  -> grant coins/card, mark claimed. Returns true on success.
##   is_unlocked(quest_id)   -> true if all "requires" prerequisites are completed.
##
## Signals:
##   quest_updated(quest_id)    progress or claim state changed
##   quest_completed(quest_id)  just reached its target

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

# Maps a GameEvents signal to the "event" quest(s) it advances by 1.
const EVENT_QUEST_HOOKS := {
	"card_equipped": ["q_first_equip"],
}

const QUEST_LOG_SCENE := preload("res://ui/quest_log/quest_log.tscn")

var _log_layer: CanvasLayer
var _log_instance: Control


func _ready() -> void:
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.card_equipped.connect(_on_card_equipped)
	SceneLoader.scene_loaded.connect(_on_scene_loaded)

	_log_layer = CanvasLayer.new()
	_log_layer.layer = 64
	add_child(_log_layer)

	# Derived quests may already be satisfied by the loaded save.
	check_all.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_quest_log"):
		toggle_log()
		get_viewport().set_input_as_handled()


# ── Public API ────────────────────────────────────────────────────────────────

func get_progress(quest_id: String) -> Dictionary:
	var def: Dictionary = QuestDatabase.QUESTS.get(quest_id, {})
	if def.is_empty():
		return {"progress": 0, "completed": false, "claimed": false}

	var entry := _entry(quest_id)
	var target := int(def.get("target", 1))
	var prog: int = clampi(_compute_progress(quest_id, def, entry), 0, target)
	var completed := prog >= target

	# Persist a one-way completion latch so claimed quests stay completed.
	if completed and not entry.get("completed", false):
		entry["completed"] = true

	return {
		"progress": prog,
		"completed": completed or entry.get("completed", false),
		"claimed": entry.get("claimed", false),
	}


func check_all() -> void:
	for quest_id in QuestDatabase.QUESTS.keys():
		var was_completed: bool = _entry(quest_id).get("completed", false)
		var p := get_progress(quest_id)
		quest_updated.emit(quest_id)
		if p["completed"] and not was_completed:
			quest_completed.emit(quest_id)
	SaveSystem.save_player_data()


func claim_reward(quest_id: String) -> bool:
	var p := get_progress(quest_id)
	if not p["completed"] or p["claimed"]:
		return false

	_grant_rewards(QuestDatabase.QUESTS[quest_id])
	_entry(quest_id)["claimed"] = true
	SaveSystem.save_player_data()
	quest_updated.emit(quest_id)
	return true


func is_unlocked(quest_id: String) -> bool:
	var def: Dictionary = QuestDatabase.QUESTS.get(quest_id, {})
	for req in def.get("requires", []):
		if not get_progress(req)["completed"]:
			return false
	return true


# ── Quest log UI ──────────────────────────────────────────────────────────────

func toggle_log() -> void:
	if is_instance_valid(_log_instance):
		_log_instance.queue_free()
		_log_instance = null
		return
	_log_instance = QUEST_LOG_SCENE.instantiate()
	_log_layer.add_child(_log_instance)


# ── Progress computation ──────────────────────────────────────────────────────

func _compute_progress(quest_id: String, def: Dictionary, entry: Dictionary) -> int:
	match def.get("type", ""):
		"player_data_bool":
			return 1 if SaveSystem.player_data.get(def.get("field", "")) else 0
		"enemy_kills":
			return int(SaveSystem.player_data.kills_by_type.get(def.get("field", ""), 0))
		"total_kills":
			var total := 0
			for v in SaveSystem.player_data.kills_by_type.values():
				total += int(v)
			return total
		"enemy_types_met":
			var types := 0
			for v in SaveSystem.player_data.kills_by_type.values():
				if int(v) > 0:
					types += 1
			return types
		"all_slots_equipped":
			var filled := 0
			for card in SaveSystem.player_data.equipped_cards:
				if card != null:
					filled += 1
			return filled
		"currency":
			return int(SaveSystem.player_data.currency)
		"event":
			return int(entry.get("progress", 0))
		_:
			return 0


# ── Save-entry helpers ────────────────────────────────────────────────────────

## Returns the stored progress entry for a quest, creating a default if missing.
func _entry(quest_id: String) -> Dictionary:
	var store: Dictionary = SaveSystem.player_data.quest_progress
	if not store.has(quest_id):
		store[quest_id] = {"progress": 0, "completed": false, "claimed": false}
	return store[quest_id]


# ── Rewards ───────────────────────────────────────────────────────────────────

func _grant_rewards(def: Dictionary) -> void:
	var coins := int(def.get("reward_coins", 0))
	if coins > 0:
		var currency = get_tree().get_first_node_in_group("currency_system")
		if currency != null:
			currency.add(coins)
		else:
			# No live currency node (e.g. in a menu) — write straight to the save.
			SaveSystem.player_data.currency += coins
			SaveSystem.save_player_data()

	var card_path: String = def.get("reward_card", "")
	if card_path != "":
		var card: Card = load(card_path)
		var card_system = get_tree().get_first_node_in_group("card_system")
		if card_system != null:
			card_system.obtain_new_item(card)
		else:
			SaveSystem.player_data.inventory_cards.append(card)
			SaveSystem.save_player_data()


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_enemy_killed(enemy_id: String) -> void:
	var kills: Dictionary = SaveSystem.player_data.kills_by_type
	kills[enemy_id] = int(kills.get(enemy_id, 0)) + 1
	SaveSystem.save_player_data()
	check_all()


func _on_card_equipped(card, _slot: int) -> void:
	# Only count real equips, not slot clears.
	if card != null:
		for quest_id in EVENT_QUEST_HOOKS["card_equipped"]:
			_bump_event(quest_id)
	check_all()


func _on_scene_loaded() -> void:
	check_all()


## Advances an "event" quest by one step and emits the right signals.
func _bump_event(quest_id: String, amount: int = 1) -> void:
	var def: Dictionary = QuestDatabase.QUESTS.get(quest_id, {})
	if def.get("type", "") != "event":
		return
	var entry := _entry(quest_id)
	var target := int(def.get("target", 1))
	if int(entry.get("progress", 0)) >= target:
		return
	entry["progress"] = int(entry.get("progress", 0)) + amount
	var newly_completed: bool = int(entry["progress"]) >= target and not entry.get("completed", false)
	if newly_completed:
		entry["completed"] = true
	SaveSystem.save_player_data()
	quest_updated.emit(quest_id)
	if newly_completed:
		quest_completed.emit(quest_id)
