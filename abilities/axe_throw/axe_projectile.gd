extends RigidBody3D

@onready var axe: Node3D = $Axe
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var hitbox_shape: CollisionShape3D = %HitboxShape

var player 

var stuck = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = player.global_position + Vector3(0, 2, 0)
	linear_velocity = Vector3(0, 7.5, -30)
	
	collision_shape.disabled = false
	hitbox_shape.disabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not stuck:
		axe.rotate(Vector3.RIGHT, -PI * 5.0 * delta)

func _on_hitbox_area_entered(area: Area3D) -> void:
	stuck = true
	linear_velocity = Vector3.ZERO
	gravity_scale = 0
	
	$AxeHitSFX.play()
	#TODO: Add sparks and other particles to make the impact feel better.
	
	await get_tree().create_timer(0.35).timeout
	queue_free()
