extends Node3D

@onready var pepper_anim: Sprite3D = $PepperAnim
const BULLET_PROJECTILE = preload("res://enemy/boss/salt_and_pepper/bullet_projectile.tscn")

@onready var left_gun: Marker3D = $PepperAnim/LeftGun
@onready var right_gun: Marker3D = $PepperAnim/RightGun

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var entities_layer
signal finished_shooting

var player 

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	player = get_tree().get_first_node_in_group("player")

func begin_attack():
	pepper_anim.play("show_guns")


func _on_pepper_anim_animation_finished() -> void:
	pass # Replace with function body.

func shoot(left_side: bool = false):
	var bullet = BULLET_PROJECTILE.instantiate()
	entities_layer.add_child(bullet)
	
	if left_side:
		bullet.global_position = left_gun.global_position
		var direction = pepper_anim.global_position.direction_to(left_gun.global_position)
		bullet.shoot(Vector3(direction.x, 0, direction.z), 12.0)
	else:
		bullet.global_position = right_gun.global_position
		var direction = pepper_anim.global_position.direction_to(right_gun.global_position)
		bullet.shoot(Vector3(direction.x, 0, direction.z), 12.0)
		
func begin_rotation():
	pepper_anim.rotate_y(PI/5)
	if pepper_anim.rotation.y < 0.0:
		disappear()

func appear():
	animation_player.play("spawn")
	player.add_blocked_pos(Vector2(0, 0))
	if player.grid_pos == Vector2(0,0):
		var rnd_dir = [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT].pick_random()
		player.roll(rnd_dir)

func disappear():
	animation_player.play("despawn")
	await animation_player.animation_finished
	finished_shooting.emit()
	player.remove_blocked_pos(Vector2(0, 0))

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"spawn":
			animation_player.play("shots")
