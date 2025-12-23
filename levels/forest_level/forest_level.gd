extends Level

@onready var axe_mesh: Node3D = %AxeMesh
const AXE_THROW = preload("uid://cwh8hm762xo3n")
@onready var axe_dialogue_trigger: Node3D = $BaseLevel/AxeObtainLocation/AxeDialogueTrigger

# IDEALLY THIS WOULD ONLY HAPPEN IF THE PLAYER DOESN'T HAVE THE AXE
func obtain_axe():
	axe_mesh.queue_free()
	card_system.set_slot_to_item(player.up_side, AXE_THROW)
	axe_dialogue_trigger.queue_free()
