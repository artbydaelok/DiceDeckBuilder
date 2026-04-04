extends Ability

@onready var revolver_mesh: Node3D = $RevolverMesh

const BULLET_PROJECTILE = preload("uid://4w0fpalmk12o")

var starting_shots : int = 6
var current_shots : int = 0

var disabled = false

func initialize():
	self_destroy_timer.queue_free()
	player.player_moved.connect(shoot)
	current_shots = starting_shots
	
	var spawn_pos : Vector3 = player.global_position + (Vector3.UP * 2.0)
	revolver_mesh.global_position = spawn_pos


func shoot(player_moved_direction : Vector3):
	if disabled : return
	current_shots -= 1
	var bullet : BulletProjectile = BULLET_PROJECTILE.instantiate()
	var spawn_pos : Vector3 = player.global_position + (Vector3.UP * 2.0)
	revolver_mesh.global_position = spawn_pos
	revolver_mesh.animate_shoot()
	
	await revolver_mesh.anim_shot_frame # Signal emitted/called from animation player
	
	entities_layer.add_child(bullet)
	var bullet_pos = revolver_mesh.get_bullet_spawn_position()
	bullet.setup(5, true, bullet_pos, Vector3.FORWARD, 12.0)
	if current_shots <= 0:
		disabled = true
		await get_tree().create_timer(1.0).timeout
		queue_free()
