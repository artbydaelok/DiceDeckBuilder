extends Sprite3D

@export var side : int 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_sprite(new_texture : Texture2D):
	texture = new_texture
