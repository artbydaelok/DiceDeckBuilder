extends FogVolume

@export var trigger_areas : Array[Area3D]

var starting_density : float = 25.0
var target_density : float = 1.0
var tween : Tween

func _ready() -> void:
	starting_density = material.density
	
	for trigger_area in trigger_areas: 
		trigger_area.body_entered.connect(_on_trigger_area_entered)
		trigger_area.body_exited.connect(_on_trigger_area_exited)
		
# TODO: This is the most basic setup, but this could be much better.
func _on_trigger_area_entered(body : Node3D):
	if body.is_in_group("player"):
		var _initial_value = material.density
		if tween: 
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "material:density", target_density, 1.0)

func _on_trigger_area_exited(body : Node3D):
	if body.is_in_group("player"):
		print("Trigger exited")
		if tween: 
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "material:density", starting_density, 1.5)
