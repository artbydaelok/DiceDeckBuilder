extends Level

@onready var forest_demon: Node3D = $BaseLevel/ForestDemon

@onready var axe_mesh: Node3D = %AxeMesh
const AXE_THROW = preload("uid://cwh8hm762xo3n")
@onready var axe_dialogue_trigger: Node3D = $BaseLevel/AxeObtainLocation/AxeDialogueTrigger

@onready var mother_nature_trigger_area_0: Node3D = $BaseLevel/MotherNatureTriggerArea0

@onready var red_negative_light_tweener: TweenProperty = $BaseLevel/RedNegativeLight/RedNegativeLightTweener
@onready var mother_nature_tween: TweenProperty = $BaseLevel/Player/MotherNatureLight/MotherNatureTween

# IDEALLY THIS WOULD ONLY HAPPEN IF THE PLAYER DOESN'T HAVE THE AXE
func obtain_axe():
	axe_mesh.queue_free()
	card_system.set_slot_to_item(player.up_side, AXE_THROW)
	axe_dialogue_trigger.queue_free()
	
func turn_red():
	red_negative_light_tweener.play()

func show_mother_nature():
	mother_nature_tween.final_value = 25.0
	mother_nature_tween.from_value = 0.0
	mother_nature_tween.play()
	forest_demon.appear()

func hide_mother_nature():
	mother_nature_tween.final_value = 0.0
	mother_nature_tween.from_value = 25.0
	mother_nature_tween.play()
	mother_nature_trigger_area_0.queue_free()
