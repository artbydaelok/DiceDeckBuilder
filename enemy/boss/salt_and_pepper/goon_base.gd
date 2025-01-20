extends Node3D

const BULLET_PROJECTILE = preload("res://enemy/boss/salt_and_pepper/bullet_projectile.tscn")

@export var shoot_left: bool = false
@onready var shoot_timer: Timer = $ShootTimer

var entities_layer 

@onready var bullet_left_spawn: Marker3D = $BulletLeftSpawn
@onready var bullet_right_spawn: Marker3D = $BulletRightSpawn

@export var trigger_area: Area3D

var keep_shooting : bool = false

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	trigger_area.body_entered.connect(begin_attack)
	trigger_area.body_exited.connect(stop_attack)

func begin_attack(player):
	shoot_timer.start()
	keep_shooting = true
	
func stop_attack(player):
	keep_shooting = false

func shoot():
	var bullet = BULLET_PROJECTILE.instantiate()
	entities_layer.add_child(bullet)
	
	var direction: Vector3 
	if shoot_left:
		direction = Vector3.LEFT
		bullet.global_position = bullet_left_spawn.global_position
	else:
		direction = Vector3.RIGHT
		bullet.global_position = bullet_right_spawn.global_position
	
	bullet.shoot(direction, 12.0)
	
	if keep_shooting:
		shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	shoot()
