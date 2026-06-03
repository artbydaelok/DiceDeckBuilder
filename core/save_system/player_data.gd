extends Resource
class_name PlayerData



@export var health : int = 10
@export var currency : int = 0
@export var equipped_cards : Array[Card] = [null, null, null, null, null, null]
@export var inventory_cards : Array[Card] = []
@export var patch_number : float = 0
@export var using_controller : bool
@export var is_mobile : bool
@export var current_level : String

#region Story Progression
@export var tutorial_completed : bool
@export var level_one_completed : bool
@export var level_two_completed : bool
@export var level_three_completed : bool
@export var level_four_completed : bool
@export var level_five_completed : bool

@export var unlocked_checkpoints: Dictionary
#endregion

#region Level State
# Keyed by level scene name (e.g. "street_01")
# Each value is a Dictionary of flags for that level
# e.g. { "visited": true, "log_barrel_broken": true }
@export var level_states: Dictionary = {}
#endregion

#region Quests
# Per-quest progress, keyed by quest id (see QuestDatabase).
# Each value: { "progress": int, "completed": bool, "claimed": bool }
# Quest *definitions* live in QuestDatabase and are never saved — only progress.
@export var quest_progress: Dictionary = {}

# Lifetime kills keyed by enemy id (see Enemy._resolve_enemy_id()).
# e.g. { "frog_enemy": 3, "eyeball": 1 }
@export var kills_by_type: Dictionary = {}
#endregion

#region Demo
@export var is_demo : bool = true
@export var demo_completed : bool
#endregion
