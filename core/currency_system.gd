extends Node
class_name CurrencySystem

signal currency_updated(new_amount)

@onready var add_currency_sfx: AudioStreamPlayer = $AddCurrencySFX
var currency : int = 0

func _ready() -> void:
	load_currency_data.call_deferred()

func load_currency_data():
	currency = SaveSystem.player_data.currency
	
	currency_updated.emit(currency)
	
func add(amount):
	currency += amount
	add_currency_sfx.play()
	SaveSystem.player_data.currency = currency
	update_save_file()
	
	currency_updated.emit(currency)

func update_save_file():
	SaveSystem.save_player_data()
