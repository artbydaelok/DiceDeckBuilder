extends Node3D

var speed = 3
@onready var hitbox_collision: CollisionShape3D = $Hitbox/HitboxCollision

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += Vector3(0, 0, speed * delta)

func flip_sprite():
	$FireSpriteFront.flip_h = bool(randi() % 2)
	$FireSpritBack.flip_h = bool(randi() % 2)


func _on_hitbox_area_entered(area: Area3D) -> void:
	await get_tree().create_timer(0.1).timeout
	hitbox_collision.disabled = true
