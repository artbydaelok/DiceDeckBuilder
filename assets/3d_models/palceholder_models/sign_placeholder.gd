extends Node3D
@onready var small_text_top = $small_text_top
@onready var main_text = $main_text
@onready var small_text_bottom = $small_text_bottom

@export var toptext : String
@export var maintext : String
@export var bottomtext : String

func _ready():
	small_text_top.text = toptext
	main_text.text = maintext
	small_text_bottom.text = bottomtext
