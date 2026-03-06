extends Node

@onready var picture_taker_viewport: SubViewport = $PictureTakerViewport

@export var picture_path : String = "res://test_picture.png"
@export var enabled_on_startup : bool = false
@export var player_input_photo : bool = false

func _ready() -> void:
	if enabled_on_startup:
		take_picture()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_P) and player_input_photo:
		take_picture()

func take_picture():
	var texture = picture_taker_viewport.get_texture()
	await RenderingServer.frame_post_draw
	
	var image = texture.get_image()
	
	image.save_png(picture_path)
