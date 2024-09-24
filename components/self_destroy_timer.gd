extends Node

@export var duration : float = 1.0
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = duration
	timer.start()
	

func _on_timer_timeout() -> void:
	get_parent().queue_free()
