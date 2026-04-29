extends Control

@export var player: Node
@export var card_system: Node

@onready var v_extra_slot: Control = $VLine/VExtraSlot
@onready var v_center_slot: Control = $VLine/VCenterSlot
@onready var forward_slot: Control = $VLine/TopSlot
@onready var back_slot: Control = $VLine/BottomSlot
@onready var h_extra_slot: Control = $HLine/HExtraSlot
@onready var h_center_slot: Control = $HLine/HCenterSlot
@onready var left_slot: Control = $HLine/LeftSlot
@onready var right_slot: Control = $HLine/RightSlot


@onready var v_line: Control = $VLine
@onready var h_line: Control = $HLine

var slot_size : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.player_moved.connect(play_animation)
	#player.roll_finished.connect(update_sprites)
	card_system.card_drawn.connect(update_sprites)
	card_system.inventory_updated.connect(update_sprites)
	
	slot_size = h_extra_slot.size
	
	await get_tree().create_timer(0.1).timeout
	update_sprites()
	
func play_animation(dir : Vector3):
	var _d = Vector2(dir.x, dir.z)
	
	# Step 1: Dealing with center panel and choosing which line will move.
	var line_to_move : Control
	var starting_pos : Vector2
	
	if dir.z != 0:						# If direction is vertical
		h_center_slot.visible = false	# hide center slot from Horizontal Line 
		v_center_slot.visible = true	# make the center slot from Vertical line visible
		line_to_move = v_line
		if dir.z == 1:
			v_extra_slot.position.y = forward_slot.position.y - slot_size.y
		elif dir.z == -1: 
			v_extra_slot.position.y = back_slot.position.y + slot_size.y
		
	elif dir.x != 0:					# If direction is horizontal
		v_center_slot.visible = false	# hide center slot from Vertical Line 
		h_center_slot.visible = true	# make the center slot from Vertical line visible
		line_to_move = h_line
		if dir.x == 1: 
			h_extra_slot.position.x = left_slot.position.x - slot_size.x
		elif dir.x == -1: 
			h_extra_slot.position.x = right_slot.position.x + slot_size.x
	
	starting_pos = line_to_move.position
	# Step 2: Animating the row moving in the direction the player moved.
	var position_tween := create_tween()
	var move_vector := Vector2(dir.x * slot_size.x, dir.z * slot_size.y)
	
	position_tween.tween_property(line_to_move, "position", starting_pos + move_vector, 0.225)
	
	await player.roll_finished
	
	line_to_move.position = starting_pos
	update_sprites()


func update_sprites():
	h_center_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.top)
	v_center_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.top)
	forward_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.front)
	back_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.back)
	left_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.left)
	right_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.right)
	h_extra_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.bottom)
	v_extra_slot.get_node("Panel/ItemIcon").texture = player.get_side_texture(player.faces.bottom)
