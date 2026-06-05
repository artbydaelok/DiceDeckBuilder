extends Node3D
class_name DeckZone
## Drop into a level to swap the player onto a puzzle Deck while they're inside the
## zone. On enter → CardSystem.equip_deck(deck); on exit → CardSystem.clear_deck().
## The player's real hand is never touched or saved (see CardSystem.equip_deck).

@onready var player_detection: Area3D = $PlayerDetection

## The deck to equip while the player is inside this zone.
@export var deck: Deck

var card_system: CardSystem


func _ready() -> void:
	card_system = get_tree().get_first_node_in_group("card_system")
	player_detection.area_entered.connect(_on_area_entered)
	player_detection.area_exited.connect(_on_area_exited)


func _on_area_entered(_area: Area3D) -> void:
	if card_system != null and deck != null:
		card_system.equip_deck(deck)


func _on_area_exited(_area: Area3D) -> void:
	if card_system != null:
		card_system.clear_deck()
