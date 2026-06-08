extends Control
## HUD readout of the active (top-face) item's two actions, shown next to the
## mouse-input icons. Refreshes whenever the top face changes or items change.
##
## Each label prefers the card's short action name (primary_action_name /
## secondary_action_name) and falls back to card_name. The secondary row hides when
## the item has no secondary; the whole display hides on an empty face or in deck mode.

@onready var _primary_label: Label = %PrimaryLabel
@onready var _secondary_label: Label = %SecondaryLabel
@onready var _secondary_row: Control = %SecondaryLabel.get_parent()  # AltContainer (label + RMouseIcon)

var _card_system: CardSystem
var _player: Node


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_card_system = get_tree().get_first_node_in_group("card_system")

	# Refresh on every "active item changed" source.
	GameEvents.dice_moved.connect(_on_dice_moved)        # top face rolled / flipped
	GameEvents.card_equipped.connect(_on_card_equipped)  # item equipped to a slot
	if _card_system != null:
		_card_system.inventory_updated.connect(_refresh) # deck swaps / inventory edits

	_refresh.call_deferred()


func _on_dice_moved(_top_face: int) -> void:
	_refresh()


func _on_card_equipped(_card: Card, _slot: int) -> void:
	_refresh()


func _refresh() -> void:
	var card := _active_card()

	# Nothing to show on an empty face or while a puzzle deck is equipped.
	if card == null:
		visible = false
		return
	visible = true

	_primary_label.text = _label_for(card.primary_action_name, card)

	var has_secondary := not card.secondary_ability_id.is_empty()
	_secondary_row.visible = has_secondary
	if has_secondary:
		_secondary_label.text = _label_for(card.secondary_action_name, card)


## Short action name, falling back to the item's name when unset.
func _label_for(action_name: String, card: Card) -> String:
	return action_name if action_name != "" else card.card_name


## The card on the current top face, or null (empty face / deck mode / not ready).
func _active_card() -> Card:
	if _card_system == null or _player == null:
		return null
	if _card_system.deck_mode_active:
		return null  # puzzle faces are inputs, not abilities
	var slot: int = _player.up_side
	if slot < 0 or slot >= _card_system.hand.size():
		return null
	return _card_system.hand[slot]
