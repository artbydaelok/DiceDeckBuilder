extends ProgressBar

@export var boss : Enemy

func _ready() -> void:
	boss.health_updated.connect(update_healthbar)
	
func update_healthbar(changed_amount : float, new_health : float):
	value = (boss.current_health / boss.max_health) * 100.0
