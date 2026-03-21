extends Node3D

@onready var player_detection: Area3D = $PlayerDetection
@export var item_data : Card

var player : Player 
var card_system : CardSystem

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	card_system = get_tree().get_first_node_in_group("card_system")
	player_detection.area_entered.connect(_on_player_entered)
	
func _on_player_entered(area):
	card_system.obtain_new_item(item_data)
