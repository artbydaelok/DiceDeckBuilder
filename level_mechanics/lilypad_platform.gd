extends Node3D

@onready var water_block_detect: Area3D = $WaterBlockDetect

var water_block_node : StaticBody3D

# When the player places the lily pad, it disables any static bodies where it has been placed.

func _ready() -> void:
	water_block_detect.body_entered.connect(_on_water_block_detected)
	
func _on_water_block_detected(body: Node3D):
	water_block_node = body
	water_block_node.disable_collision()

func destroy():
	if water_block_node != null:
		water_block_node.enable_collision()
