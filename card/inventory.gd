extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	GameEvents.connect("dice_moved", on_dice_moved)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_dice_moved(_index):
	for c in $HBoxContainer.get_children():
		c.color = Color.WHITE
	$HBoxContainer.get_child(_index - 1).color = Color.YELLOW
