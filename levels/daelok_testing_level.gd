extends Level

@onready var area_3d: Area3D = $Area3D

const CRUSHED_ICE = preload("uid://b13o3b5bar26b")
const SYNTHESIZING_PAIN = preload("uid://rc2w17xatnjy")
const MONEY_PROBLEMS_V_1 = preload("uid://f1buplcjvh7g")

const SHOP_UI = preload("uid://0n5rso7bt1od")
var shop_ui 


func level_start():
	area_3d.body_entered.connect(_on_test_trigger)
	
func _on_test_trigger(body):
	ProjectMusicController.play_stream(CRUSHED_ICE)
	shop_ui = SHOP_UI.instantiate()
	GameEvents.current_level.user_interface.add_child(shop_ui)
