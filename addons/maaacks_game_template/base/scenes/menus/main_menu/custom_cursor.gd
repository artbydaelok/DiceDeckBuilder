extends Sprite2D

@onready var animation_player: AnimationPlayer = $ClickEffect/AnimationPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	if Input.is_action_just_pressed("left_click"):
		if animation_player.is_playing():
			animation_player.stop()
		animation_player.play("clicked")
