extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_spawn_marker: Marker3D = $BulletSpawnMarker

signal anim_shot_frame

func animate_shoot():
	animation_player.play("shoot")

func get_bullet_spawn_position() -> Vector3:
	return bullet_spawn_marker.global_position
