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

var player : Node3D

@export var traffic_light : Node3D
@export var boss : Node3D

@export var lamp_post : Node3D

@onready var shoot_warning: AnimationPlayer = $ShootWarning
@onready var dotted_line: MeshInstance3D = $DottedLine
var dotted_line_offset: float = 11;


func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	player = get_tree().get_first_node_in_group("player")
	
	if shoot_left:
		dotted_line.position -= Vector3(dotted_line_offset, 0, 0)
		animated_sprite_3d.flip_h = true
		animated_sprite_3d.play("pepper_default")
		dotted_line.get_active_material(0).set_shader_parameter("speed", -1.0)
	else:
		dotted_line.position += Vector3(dotted_line_offset, 0, 0)
		
	trigger_area.body_entered.connect(begin_attack)
	trigger_area.body_exited.connect(stop_attack)

	traffic_light.red_light.connect(retry_attack)

func retry_attack():
	if not trigger_area.get_overlapping_bodies().has(player):
		return
	else:
		begin_attack(null)

func begin_attack(player):
	lamp_post.turn_light_on()
	if shoot_time_offset > 0.0:
		attack_delay_timer.wait_time = shoot_time_offset
		attack_delay_timer.start()
		await attack_delay_timer.timeout
	shoot_timer.start()
	keep_shooting = true
	shoot_warning.play("shoot_warning")
	
func stop_attack(player):
	lamp_post.turn_light_off()
	keep_shooting = false
	shoot_warning.play_backwards("shoot_warning")

func shoot():
	if traffic_light.is_green:
		keep_shooting = false
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
	if shoot_left:
		animated_sprite_3d.play("pepper_shoot")
	else:
		animated_sprite_3d.play("salt_shoot")
	if keep_shooting:
		shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	shoot()

func _on_animated_sprite_3d_animation_finished() -> void:
	if animated_sprite_3d.animation == "pepper_shoot" or animated_sprite_3d.animation == "salt_shoot":
		if shoot_left:
			animated_sprite_3d.play("pepper_default")
		else:
			animated_sprite_3d.play("salt_default")
