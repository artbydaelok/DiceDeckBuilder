extends AudioStreamPlayer

func _ready() -> void:
	finished.connect(loop)
	
func loop():
	play()
