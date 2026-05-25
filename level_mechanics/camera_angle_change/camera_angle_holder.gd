#@tool
extends Marker3D

@export var camera_3d: Camera3D

var starting_offset : Vector3 
var player : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent() == get_tree().get_first_node_in_group("player"):
		await get_tree().process_frame
		set_player()
		
		reparent(player.get_parent(), true)
	
	if camera_3d: camera_3d.queue_free()
	
func set_player():
	player = get_tree().get_first_node_in_group("player")
	starting_offset = global_position - player.mesh.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if camera_3d:
			global_position = camera_3d.global_position
		return
	if player != null:
		global_position = player.mesh.global_position + starting_offset
