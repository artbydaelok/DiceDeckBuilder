extends Node3D

var pressed := false

var rotation_momentum_velocity := Vector2.ZERO

@onready var dice_mesh: MeshInstance3D = $DiceMesh
@export var camera: Camera3D

var active_side : StaticBody3D

var rotation_speed : float = 0.005

func _ready() -> void:
	GameEvents.side_updated_item.connect(_on_side_updated_item)
	GameEvents.dice_viewer_rotation_speed_updated.connect(_on_rotation_speed_updated)

func _input(event: InputEvent) -> void:
	if pressed and event is InputEventMouseMotion:
		var rotation_amount = Vector2(event.relative.y * rotation_speed , event.relative.x * rotation_speed)
		global_rotation.x += rotation_amount.x
		dice_mesh.global_rotation.y += rotation_amount.y
		
		#IDEA: Decelerate rotation after mouse is released, keeping momentum.
		# We can use the previous frames to keep track of how fast the player was rotating the dice, and keep the rotation speed for a short while after they release letting it decelerate until it reaches zero.

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
	var item_sprite_node = dice_mesh.get_child(side).get_node("ItemSprite")
	var number_cover_sprite_node = dice_mesh.get_child(side).get_node("NumberCoverSprite")
	item_sprite_node.texture = item.card_artwork
	item_sprite_node.visible = true
	number_cover_sprite_node.visible = true

func _on_rotation_speed_updated(new_speed):
	rotation_speed = new_speed * 0.01
