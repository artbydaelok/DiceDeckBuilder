extends Node3D

var pressed := false

@onready var dice_mesh: MeshInstance3D = $DiceMesh
@export var camera: Camera3D

var active_side : StaticBody3D

func _ready() -> void:
	GameEvents.side_updated_item.connect(_on_side_updated_item)

func _input(event: InputEvent) -> void:
	if pressed and event is InputEventMouseMotion:
		global_rotation.x += event.relative.y * 0.005
		dice_mesh.global_rotation.y += event.relative.x * 0.005
		
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("left_click"):
		pressed = true
	if Input.is_action_just_released("left_click"):
		pressed = false
	if Input.is_action_just_pressed("right_click"):
		shoot_ray()

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result = space.intersect_ray(ray_query)
	
	if not raycast_result.is_empty():
		active_side = raycast_result["collider"]
		
		reset_selection()
		active_side.get_node("SelectionSprite").visible = true
		GameEvents.side_editing_started.emit(active_side.get_index())

func reset_selection():
	for child in dice_mesh.get_children():
		child.get_node("SelectionSprite").visible = false

func _on_side_updated_item(side: int, item: Card):
	var sprite_node = dice_mesh.get_child(side).get_node("ItemSprite")
	sprite_node.texture = item.card_artwork
	sprite_node.visible = true
