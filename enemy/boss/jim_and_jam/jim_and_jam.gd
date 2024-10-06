extends Enemy

const COLUMN_SHATTER_VFX = preload("res://enemy/boss/jim_and_jam/column_shatter_vfx.tscn")

@onready var hammer_attack_timer: Timer = $HammerAttackTimer
var hammer_hit_count = 3

@onready var decision_timer: Timer = $DecisionTimer

func _on_hammer_attack_timer_timeout() -> void:
	# Instantiates the hitbox and shatter vfx.
	var attack = COLUMN_SHATTER_VFX.instantiate()
	entities_layer.add_child(attack)
	
	# Reduces the hammer hit count.
	hammer_hit_count -= 1
	print(hammer_hit_count)
	# And if the hammer hit count is at zero, then stop triggering more hits.
	if hammer_hit_count == 0:
		hammer_attack_timer.stop()
		decision_timer.start()

func _on_decision_timer_timeout() -> void:
	# Performs one of the multiple attacks:
	var random_attack = randi() % 1
	
	# Hammer Attack
	match random_attack:
		0:
			hammer_hit_count = 3
			hammer_attack_timer.start()
