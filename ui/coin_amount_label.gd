extends Label

var currency_system : CurrencySystem

func _ready() -> void:
	currency_system = get_tree().get_first_node_in_group("currency_system")
	currency_system.currency_updated.connect(_on_currency_updated)
	text = str(currency_system.currency)
	
func _on_currency_updated(new_amount):
	text = str(new_amount)
