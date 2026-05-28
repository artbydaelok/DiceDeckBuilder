extends Node3D

@onready var pepper_anim: Sprite3D = $PepperAnim
const BULLET_PROJECTILE = preload("res://enemy/boss/salt_and_pepper/bullet_projectile.tscn")

@onready var left_gun: Marker3D = $PepperAnim/LeftGun
@onready var right_gun: Marker3D = $PepperAnim/RightGun

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var entities_layer
signal finished_shooting

var player
var _blocker: StaticBody3D = null

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	player = get_tree().get_first_node_in_group("player")

func begin_attack():
	pepper_anim.play("show_guns")


func _on_pepper_anim_animation_finished() -> void:
	pass # Replace with function body.

func shoot(left_side: bool = false):
	var bullet : BulletProjectile = BULLET_PROJECTILE.instantiate()
	entities_layer.add_child(bullet)
	var direction : Vector3
	var spawn_pos : Vector3
	
	if left_side:
		spawn_pos = left_gun.global_position
		direction = pepper_anim.global_position.direction_to(left_gun.global_position)
	else:
		spawn_pos = right_gun.global_position
		direction = pepper_anim.global_position.direction_to(right_gun.global_position)
		
	bullet.setup(4, false,spawn_pos ,Vector3(direction.x, 0, direction.z), 12.0)
	
	$ShotSFX.pitch_scale = randf_range(1.2, 1.6)
	$ShotSFX.play()
	
func begin_rotation():
	pepper_anim.rotate_y(PI/5)
	if pepper_anim.rotation.y < 0.0:
		disappear()

func appear():
	animation_player.play("spawn")
	_spawn_blocker()
	if player.grid_pos == Vector2(0,0):
		var rnd_dir = [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.RIGHT].pick_random()
		player.roll(rnd_dir)

func disappear():
	animation_player.play("despawn")
	await animation_player.animation_finished
	_remove_blocker()
	finished_shooting.emit()

func _spawn_blocker() -> void:
	_blocker = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape.shape = box
	_blocker.add_child(shape)
	get_parent().add_child(_blocker)
	_blocker.global_position = global_position

func _remove_blocker() -> void:
	if _blocker != null:
		_blocker.queue_free()
		_blocker = null

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"spawn":
			animation_player.play("shots")
