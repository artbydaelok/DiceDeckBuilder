extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox
@onready var caught_sfx: AudioStreamPlayer3D = $CaughtSFX
@onready var close_sfx: AudioStreamPlayer3D = $CloseSFX
@onready var activate_sfx: AudioStreamPlayer3D = $ActivateSFX

@onready var visuals: Node3D = $BearTrapRig

var has_caught : bool = false

const TRAP_DAMAGE := 8

func _ready() -> void:
	hitbox.damage = 0  # we resolve capture-vs-damage ourselves (need the node, not just on_hit)
	hitbox.area_entered.connect(_on_area_entered)
	trigger()

func _on_area_entered(area: Area3D) -> void:
	if has_caught or not (area is Hurtbox):
		return
	var target = (area as Hurtbox).hurtbox_owner
	if target == null:
		return

	if target is Enemy and target.capturable:
		has_caught = true
		_capture(target)              # store its identity + remove it from the board
	elif target is Enemy or target is Player:
		has_caught = true
		if target.has_method("apply_damage"):
			target.apply_damage(TRAP_DAMAGE)  # bosses / the player just take damage
	else:
		return

	hitbox.queue_free()
	caught_sfx.play()
	trigger()

	await get_tree().create_timer(5.0).timeout

	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3.ZERO, 1.5)
	await tween.finished
	queue_free()

## Record what we caught so the trap's release secondary can re-summon it.
func _capture(enemy) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p != null:
		p.captured_creature = {
			"scene_path": enemy.scene_file_path,
			"enemy_id": enemy._resolve_enemy_id(),
		}
	enemy.queue_free()

func trigger():
	close_sfx.play()
	animation_player.play("Trigger")

func activate():
	animation_player.play_backwards("Trigger")
	var tween := create_tween()
	var initial_position := global_position
	
	activate_sfx.play()
	
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", initial_position + Vector3(0, 1.5, 0), 0.25)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", initial_position + Vector3(0, -2, 0), 0.25)
