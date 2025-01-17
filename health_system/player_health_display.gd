extends ProgressBar

@export var center_warning_sign_scene : PackedScene
@export var user_interface_layer : CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	player.player_health_updated.connect(update_healthbar)
	player.player_died.connect(display_death_message)

func update_healthbar(new_health):
	value = new_health

func display_death_message():
	var c = center_warning_sign_scene.instantiate()
	user_interface_layer.add_child(c)
	c.setup_and_play("YOU DIED")
	c.menu_return = true
