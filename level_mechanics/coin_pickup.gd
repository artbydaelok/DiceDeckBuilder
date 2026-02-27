extends Node3D

@onready var coin_mesh: Node3D = %CoinMesh
@onready var pickup_area: Area3D = $PickupArea

var currency_system : CurrencySystem

func _ready() -> void:
	pickup_area.area_entered.connect(_on_pickup_entered)
	currency_system = get_tree().get_first_node_in_group("currency_system")
	
func _process(delta: float) -> void:
	coin_mesh.rotate_y(10 * delta)

func _on_pickup_entered(body):
	currency_system.add(10)
	queue_free()
