extends RigidBody3D

@onready var axe: Node3D = $Axe
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var hitbox_shape: CollisionShape3D = %HitboxShape

var player : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = player.global_position + Vector3(0, 2, 0)
	linear_velocity = Vector3(0, 10, -30)
	
	collision_shape.disabled = false
	hitbox_shape.disabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	axe.rotate(Vector3.RIGHT, -PI * 5.0 * delta)
