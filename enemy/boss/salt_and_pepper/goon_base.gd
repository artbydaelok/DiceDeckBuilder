extends Node3D

const BULLET_PROJECTILE = preload("res://enemy/boss/salt_and_pepper/bullet_projectile.tscn")

@export var shoot_left: bool = false
@onready var shoot_timer: Timer = $ShootTimer

var entities_layer 

@onready var bullet_left_spawn: Marker3D = $BulletLeftSpawn
@onready var bullet_right_spawn: Marker3D = $BulletRightSpawn

@export var trigger_area: Area3D

var keep_shooting : bool = false

@onready var attack_delay_timer: Timer = $AttackDelayTimer
@export var shoot_time_offset : float = 0.0

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var shot_sfx: AudioStreamPlayer = $ShotSFX

@export var traffic_light : Node3D

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	if shoot_left:
		animated_sprite_3d.flip_h = true
	trigger_area.body_entered.connect(begin_attack)
	trigger_area.body_exited.connect(stop_attack)

func begin_attack(player):
	if shoot_time_offset > 0.0:
		attack_delay_timer.wait_time = shoot_time_offset
		attack_delay_timer.start()
		await attack_delay_timer.timeout
	shoot_timer.start()
	keep_shooting = true
	
func stop_attack(player):
	keep_shooting = false

func shoot():
	if not traffic_light.is_green: 
		if keep_shooting:
			shoot_timer.start()
		return
		
	var bullet = BULLET_PROJECTILE.instantiate()
	entities_layer.add_child(bullet)
	
	var direction: Vector3 
	if shoot_left:
		direction = Vector3.LEFT
		bullet.global_position = bullet_left_spawn.global_position
	else:
		direction = Vector3.RIGHT
		bullet.global_position = bullet_right_spawn.global_position
	
	shot_sfx.play()
	
	bullet.shoot(direction, 12.0)
	animated_sprite_3d.play("shoot")
	if keep_shooting:
		shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	shoot()


func _on_animated_sprite_3d_animation_finished() -> void:
	if animated_sprite_3d.animation == "shoot()":
		animated_sprite_3d.play("default")
