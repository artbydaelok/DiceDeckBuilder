extends Node3D

@onready var balloon: Node3D = $Balloon

var start_rotating = true
var rotation_amount = Vector3.ZERO
var rotation_axis = Vector3.LEFT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_amount = randfn(-0.15 * PI, 0.15 * PI)
	rotation_axis = [Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN].pick_random()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if start_rotating:
		balloon.rotate(rotation_axis , rotation_amount * delta)
		
func pop_projectiles():
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		proj.queue_free()
