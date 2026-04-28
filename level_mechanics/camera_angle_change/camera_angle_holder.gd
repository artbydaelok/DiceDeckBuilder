extends Marker3D

@onready var camera_3d: Camera3D = $Camera3D

var starting_offset : Vector3 
var player : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent() == get_tree().get_first_node_in_group("player"):
		await get_tree().process_frame
		set_player()
		reparent(player.get_parent(), true)
	camera_3d.queue_free()
	
func set_player():
	player = get_tree().get_first_node_in_group("player")
	starting_offset = global_position - player.mesh.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player != null:
		global_position = player.mesh.global_position + starting_offset
