extends Node
## Static quest definitions for Oddside. Registered as the `QuestDatabase` autoload.
##
## Quest *definitions* live here and are never saved — only per-player progress is
## persisted (PlayerData.quest_progress). This means quests can be added or edited
## without breaking existing saves.
##
## Each entry in QUESTS:
##   "title":         display title
##   "description":   body text. Card/item names get keyword-highlighted by QuestTextParser.
##   "category":      "main" | "side" | "challenge"  (controls which tab it shows in)
##   "type":          how progress is computed (see below)
##   "field":         (type-dependent) which data field to read
##   "target":        amount needed to complete
##   "reward_coins":  coins granted on claim (via CurrencySystem)
##   "reward_card":   (optional) res:// path to a Card resource granted on claim, "" = none
##   "requires":      prerequisite quest ids; quest is hidden until all are completed. [] = always
##
## Quest types and how progress is computed (see QuestManager):
##   "player_data_bool"   — reads a bool field on PlayerData (0 or 1). Use "field".
##   "enemy_kills"        — reads PlayerData.kills_by_type[field] for a specific enemy. Use "field".
##   "total_kills"        — sums every value in PlayerData.kills_by_type.
##   "enemy_types_met"    — counts distinct enemy ids killed at least once.
##   "all_slots_equipped" — counts non-null slots in PlayerData.equipped_cards (max 6).
##   "currency"           — reads PlayerData.currency.
##   "event"              — progress accumulated by QuestManager signal handlers, stored in save.

const CATEGORY_ORDER := {
	"main": 0,
	"side": 1,
	"challenge": 2,
}

const QUESTS := {
	# ── Main ──────────────────────────────────────────────────────────────────
	"q_tutorial": {
		"title": "First Roll",
		"description": "Finish the tutorial and learn to roll.",
		"category": "main",
		"type": "player_data_bool",
		"field": "tutorial_completed",
		"target": 1,
		"reward_coins": 50,
		"requires": [],
	},
	"q_level_one": {
		"title": "Into the Odd",
		"description": "Clear the first level.",
		"category": "main",
		"type": "player_data_bool",
		"field": "level_one_completed",
		"target": 1,
		"reward_coins": 100,
		"requires": ["q_tutorial"],
	},
	"q_level_two": {
		"title": "Deeper Still",
		"description": "Clear the second level.",
		"category": "main",
		"type": "player_data_bool",
		"field": "level_two_completed",
		"target": 1,
		"reward_coins": 150,
		"requires": ["q_level_one"],
	},

	# ── Side ──────────────────────────────────────────────────────────────────
	"q_first_equip": {
		"title": "Loadout",
		"description": "Equip a card to one of your dice faces.",
		"category": "side",
		"type": "event",
		"target": 1,
		"reward_coins": 30,
		"requires": [],
	},
	"q_full_loadout": {
		"title": "Fully Loaded",
		"description": "Equip a card to all six dice faces.",
		"category": "side",
		"type": "all_slots_equipped",
		"target": 6,
		"reward_coins": 150,
		"requires": ["q_first_equip"],
	},
	"q_saver": {
		"title": "Pocket Change",
		"description": "Save up 500 coins.",
		"category": "side",
		"type": "currency",
		"target": 500,
		"reward_coins": 50,
		"requires": [],
	},

	# ── Challenge ─────────────────────────────────────────────────────────────
	"q_first_blood": {
		"title": "First Blood",
		"description": "Defeat your first enemy.",
		"category": "challenge",
		"type": "total_kills",
		"target": 1,
		"reward_coins": 20,
		"requires": [],
	},
	"q_slayer": {
		"title": "Slayer",
		"description": "Defeat 25 enemies.",
		"category": "challenge",
		"type": "total_kills",
		"target": 25,
		"reward_coins": 200,
		"requires": ["q_first_blood"],
	},
	"q_bestiary": {
		"title": "Know Thy Enemy",
		"description": "Defeat at least one of four different enemy types.",
		"category": "challenge",
		"type": "enemy_types_met",
		"target": 4,
		"reward_coins": 100,
		"requires": ["q_first_blood"],
	},
}
