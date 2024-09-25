extends ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_first_node_in_group("player").player_health_updated.connect(update_healthbar)

func update_healthbar(new_health):
	value = new_health
