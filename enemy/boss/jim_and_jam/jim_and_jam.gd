extends Enemy

const COLUMN_SHATTER_VFX = preload("res://enemy/boss/jim_and_jam/column_shatter_vfx.tscn")
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var hurtbox: Area3D = $Hurtbox

@onready var hammer_attack_timer: Timer = $HammerAttackTimer
var hammer_hit_count = 3

@onready var decision_timer: Timer = $DecisionTimer

@onready var dotted_line: MeshInstance3D = $AnimatedSprite3D/DottedLine

func _on_hammer_attack_timer_timeout() -> void:
	var _x = randi_range(-2, 2) * 2 - 2.5
	animated_sprite_3d.global_position.x = _x
	hurtbox.global_position.x = _x
	
	%JamSmallCollision.disabled = false
	animated_sprite_3d.play("hammer_down")
	dotted_line.visible = true

func hammer_down_attack():
	# Instantiates the hitbox and shatter vfx.
	var attack = COLUMN_SHATTER_VFX.instantiate()
	entities_layer.add_child(attack)
	
	attack.global_position.x = animated_sprite_3d.global_position.x + 2.5
	
	# Reduces the hammer hit count.
	hammer_hit_count -= 1
	print(hammer_hit_count)
	# And if the hammer hit count is at zero, then stop triggering more hits.
	if hammer_hit_count == 0:
		hammer_attack_timer.stop()
		decision_timer.start()
		await get_tree().create_timer(0.75).timeout
		animated_sprite_3d.play("default")
		animated_sprite_3d.global_position.x = 0
		hurtbox.global_position.x = 0 
		dotted_line.visible = false
		

func _on_decision_timer_timeout() -> void:
	# Performs one of the multiple attacks:
	var random_attack = randi() % 1
	
	# Hammer Attack
	match random_attack:
		0:
			hammer_hit_count = 3
			hammer_attack_timer.start()
			


func _on_animated_sprite_3d_animation_finished() -> void:
	if animated_sprite_3d.animation == "hammer_down":
		animated_sprite_3d.play("hammer_down_after")
		%JamSmallCollision.disabled = true
		hammer_down_attack()
	#if animated_sprite_3d.animation == "hammer_down_after":
		#%JamSmallCollision.disabled = false
