extends Level

@onready var area_3d: Area3D = $Area3D

const CRUSHED_ICE = preload("uid://b13o3b5bar26b")
const SYNTHESIZING_PAIN = preload("uid://rc2w17xatnjy")
const MONEY_PROBLEMS_V_1 = preload("uid://f1buplcjvh7g")


func level_start():
	area_3d.body_entered.connect(_on_test_trigger)
	
func _on_test_trigger(body):
	ProjectMusicController.play_stream(CRUSHED_ICE)
