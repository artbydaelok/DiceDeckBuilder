extends Node

@export var duration : float = 1.0
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = duration
	timer.start()
	

func _on_timer_timeout() -> void:
	get_parent().queue_free()


## Stop the auto-free (e.g. while an ability is held/charging and manages its own lifetime).
func cancel() -> void:
	timer.stop()
