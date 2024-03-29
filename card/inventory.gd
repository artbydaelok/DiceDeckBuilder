extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	GameEvents.dice_moved.connect(on_dice_moved)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_dice_moved(_index):
	for c in get_children():
		c.color = Color.WHITE
	get_child(_index - 1).color = Color.YELLOW
