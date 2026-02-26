extends Control

## This are the items that the shop will sell.
@export var shop_items : Array[Card]
@onready var shop_item_container: GridContainer = %ShopItemContainer
@onready var close_button: Button = %CloseButton

const SHOP_ITEM_DISPLAY = preload("uid://c2833a2kd0xk8")

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	GameEvents.menu_entered.emit()
	setup()

func setup():
	for item in shop_items:
		var item_display = SHOP_ITEM_DISPLAY.instantiate()
		item_display.item_data = item
		shop_item_container.add_child(item_display)
		item_display.setup()

func _on_close_button_pressed():
	GameEvents.menu_exited.emit()
	queue_free()
