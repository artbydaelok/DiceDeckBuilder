extends Node3D

@export var light_on : bool = false

func _ready() -> void:
	if not light_on:
		$SpotLight3D.visible = false

func turn_light_on():
	$SpotLight3D.visible = true

func turn_light_off():
	$SpotLight3D.visible = false


func _on_area_3d_area_entered(area):
	turn_light_on()
