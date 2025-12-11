extends Node

# This node should be able to be attached to any other node.

## This is the node that has all the functions you want to trigger. Defaults to the parent of this node.
@export var acting_node : Node

## Choose whether the following functions should be triggered when using an item, or when an item is on top..
@export_enum("Trigger when an item is used.", "Trigger when item is on top.") var behavior: int = 0

## The key is the item id you want to react to, the value is the callable name you want to trigger when that item has been used.
@export var items_to_callables : Dictionary[String, String]

func _ready() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	var card_system : CardSystem = get_tree().get_first_node_in_group("card_system")
	
	if acting_node == null:
		acting_node = get_parent()

	match behavior:
		0: # Trigger on item use
			card_system.item_used.connect(_on_item_used)
		1: # Trigger when item on top
			pass
		
func _on_item_used(item_used : Card):
	var item_id : String = item_used.ability_id
	if items_to_callables.has(item_id):
		var _func = Callable(acting_node, items_to_callables[item_id])
		_func.call()
