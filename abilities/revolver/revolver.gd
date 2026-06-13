extends Ability
## Revolver.
##   PRIMARY   (LMB / A) → load 6 shots that auto-fire forward, one each of your next
##                         6 moves.
##   SECONDARY (RMB / B) → Fan the Hammer: dump ALL remaining loaded bullets at once,
##                         fanned across the half-circle in front of you. Needs a loaded
##                         revolver (CardSystem gates it free otherwise).

@onready var revolver_mesh: Node3D = $RevolverMesh

const BULLET_PROJECTILE = preload("uid://4w0fpalmk12o")

const FAN_DAMAGE := 5
const FAN_SPEED := 12.0
const FAN_ARC := PI   # half-circle (180°) in front

var starting_shots : int = 6
var current_shots : int = 0

var disabled = false


func initialize():
	if is_secondary:
		_fan_the_hammer()
		return

	self_destroy_timer.queue_free()
	player.active_revolver = self
	player.player_moved.connect(shoot)
	current_shots = starting_shots
	revolver_mesh.global_position = player.global_position + (Vector3.UP * 2.0)


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


## Fire every remaining loaded bullet at once, fanned across the front half-circle.
func _fan_the_hammer():
	if revolver_mesh:
		revolver_mesh.visible = false  # the fan has no gun visual yet (polish later)
	var src = player.active_revolver
	if not is_instance_valid(src):
		return  # nothing loaded
	var n: int = src.current_shots
	src.current_shots = 0
	src.queue_free()              # the per-move revolver is spent
	player.active_revolver = null
	if n <= 0:
		return

	var origin: Vector3 = player.global_position + (Vector3.UP * 2.0)
	for i in range(n):
		var t := (float(i) / float(n - 1)) if n > 1 else 0.5
		var angle := lerpf(-FAN_ARC / 2.0, FAN_ARC / 2.0, t)
		var dir := Vector3.FORWARD.rotated(Vector3.UP, angle)
		var bullet: BulletProjectile = BULLET_PROJECTILE.instantiate()
		entities_layer.add_child(bullet)
		bullet.setup(FAN_DAMAGE, true, origin, dir, FAN_SPEED)


# Clear the player's active-revolver pointer when the loaded (primary) revolver ends.
func _notification(what):
	if what == NOTIFICATION_PREDELETE and not is_secondary \
			and is_instance_valid(player) and player.active_revolver == self:
		player.active_revolver = null
