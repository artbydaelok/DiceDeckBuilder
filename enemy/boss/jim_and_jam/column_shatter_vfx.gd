extends GPUParticles3D

@onready var hitbox: Hitbox = $Hitbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	await get_tree().create_timer(0.25).timeout
	hitbox.disable()
