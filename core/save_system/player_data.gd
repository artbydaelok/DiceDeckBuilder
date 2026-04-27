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

#region Demo
@export var is_demo : bool = true
@export var demo_completed : bool
#endregion
