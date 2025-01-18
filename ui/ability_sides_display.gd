extends Control

@export var player: Node
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var left: Sprite2D = $Background/Left
@onready var extra_left: Sprite2D = $Background/ExtraLeft
@onready var right: Sprite2D = $Background/Right
@onready var extra_right: Sprite2D = $Background/ExtraRight
@onready var bottom: Sprite2D = $Background/Bottom
@onready var extra_bottom: Sprite2D = $Background/ExtraBottom
@onready var top: Sprite2D = $Background/Top
@onready var extra_top: Sprite2D = $Background/ExtraTop
@onready var center: Sprite2D = $Background/Center

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.player_moved.connect(play_animation)
	player.roll_finished.connect(update_sprites)
	await get_tree().create_timer(0.1).timeout
	update_sprites()
	
func play_animation(dir : Vector3):
	update_sprites()
	var _d = Vector2(dir.x, dir.z)
	match _d:
		Vector2.LEFT:
			animation_player.play("roll_left")
		Vector2.UP:
			animation_player.play("roll_forward")
		Vector2.DOWN:
			animation_player.play("roll_backward")
		Vector2.RIGHT:
			animation_player.play("roll_right")



func update_sprites():
	# Matches the active texture to the center.
	center.texture = player.mesh.get_child(player.up_side).get_child(0).texture
	
	var opposite_texture 
	
	match player.up_side:
		0: # 1, opposite is 6
			# Sets the opposite side's texture
			opposite_texture = player.mesh.get_child(5).get_child(0).texture

			var two_pos = round(player.side_two.global_position - player.global_position)
			if two_pos.x > 0: 
				right.texture = player.side_two.get_child(0).texture
				left.texture = player.side_five.get_child(0).texture
			elif two_pos.x < 0:
				left.texture = player.side_two.get_child(0).texture
				right.texture = player.side_five.get_child(0).texture
			elif two_pos.z < 0:
				top.texture = player.side_two.get_child(0).texture
				bottom.texture = player.side_five.get_child(0).texture
			elif two_pos.z > 0:
				bottom.texture = player.side_two.get_child(0).texture
				top.texture = player.side_five.get_child(0).texture
			
			var three_pos = round(player.side_three.global_position - player.global_position)
			if three_pos.x > 0: 
				right.texture = player.side_three.get_child(0).texture
				left.texture = player.side_four.get_child(0).texture
			elif three_pos.x < 0:
				left.texture = player.side_three.get_child(0).texture
				right.texture = player.side_four.get_child(0).texture
			elif three_pos.z < 0:
				top.texture = player.side_three.get_child(0).texture
				bottom.texture = player.side_four.get_child(0).texture
			elif three_pos.z > 0:
				bottom.texture = player.side_three.get_child(0).texture
				top.texture = player.side_four.get_child(0).texture
			
		1: # 2, opposite is 5
			opposite_texture = player.mesh.get_child(4).get_child(0).texture
			var one_pos = round(player.side_one.global_position - player.global_position)
			if one_pos.x > 0: 
				right.texture = player.side_one.get_child(0).texture
				left.texture = player.side_six.get_child(0).texture
			elif one_pos.x < 0:
				left.texture = player.side_one.get_child(0).texture
				right.texture = player.side_six.get_child(0).texture
			elif one_pos.z < 0:
				top.texture = player.side_one.get_child(0).texture
				bottom.texture = player.side_six.get_child(0).texture
			elif one_pos.z > 0:
				bottom.texture = player.side_one.get_child(0).texture
				top.texture = player.side_six.get_child(0).texture
			
			var three_pos = round(player.side_three.global_position - player.global_position)
			if three_pos.x > 0: 
				right.texture = player.side_three.get_child(0).texture
				left.texture = player.side_four.get_child(0).texture
			elif three_pos.x < 0:
				left.texture = player.side_three.get_child(0).texture
				right.texture = player.side_four.get_child(0).texture
			elif three_pos.z < 0:
				top.texture = player.side_three.get_child(0).texture
				bottom.texture = player.side_four.get_child(0).texture
			elif three_pos.z > 0:
				bottom.texture = player.side_three.get_child(0).texture
				top.texture = player.side_four.get_child(0).texture
	
			
		2: # 3, opposite is 4
			opposite_texture = player.mesh.get_child(3).get_child(0).texture
			var one_pos = round(player.side_one.global_position - player.global_position)
			if one_pos.x > 0: 
				right.texture = player.side_one.get_child(0).texture
				left.texture = player.side_six.get_child(0).texture
			elif one_pos.x < 0:
				left.texture = player.side_one.get_child(0).texture
				right.texture = player.side_six.get_child(0).texture
			elif one_pos.z < 0:
				top.texture = player.side_one.get_child(0).texture
				bottom.texture = player.side_six.get_child(0).texture
			elif one_pos.z > 0:
				bottom.texture = player.side_one.get_child(0).texture
				top.texture = player.side_six.get_child(0).texture
				
			var two_pos = round(player.side_two.global_position - player.global_position)
			if two_pos.x > 0: 
				right.texture = player.side_two.get_child(0).texture
				left.texture = player.side_five.get_child(0).texture
			elif two_pos.x < 0:
				left.texture = player.side_two.get_child(0).texture
				right.texture = player.side_five.get_child(0).texture
			elif two_pos.z < 0:
				top.texture = player.side_two.get_child(0).texture
				bottom.texture = player.side_five.get_child(0).texture
			elif two_pos.z > 0:
				bottom.texture = player.side_two.get_child(0).texture
				top.texture = player.side_five.get_child(0).texture
			
		3: # 4, opposite is 3
			opposite_texture = player.mesh.get_child(2).get_child(0).texture
			var five_pos = round(player.side_five.global_position - player.global_position)
			if five_pos.x > 0: 
				right.texture = player.side_five.get_child(0).texture
				left.texture = player.side_two.get_child(0).texture
			elif five_pos.x < 0:
				left.texture = player.side_five.get_child(0).texture
				right.texture = player.side_two.get_child(0).texture
			elif five_pos.z < 0:
				top.texture = player.side_five.get_child(0).texture
				bottom.texture = player.side_two.get_child(0).texture
			elif five_pos.z > 0:
				bottom.texture = player.side_five.get_child(0).texture
				top.texture = player.side_two.get_child(0).texture
			
			var six_pos = round(player.side_six.global_position - player.global_position)
			if six_pos.x > 0: 
				right.texture = player.side_six.get_child(0).texture
				left.texture = player.side_one.get_child(0).texture
			elif six_pos.x < 0:
				left.texture = player.side_six.get_child(0).texture
				right.texture = player.side_one.get_child(0).texture
			elif six_pos.z < 0:
				top.texture = player.side_six.get_child(0).texture
				bottom.texture = player.side_one.get_child(0).texture
			elif six_pos.z > 0:
				bottom.texture = player.side_six.get_child(0).texture
				top.texture = player.side_one.get_child(0).texture
			
		4: # 5, opposite is 2
			opposite_texture = player.mesh.get_child(1).get_child(0).texture
			var four_pos = round(player.side_four.global_position - player.global_position)
			if four_pos.x > 0: 
				right.texture = player.side_four.get_child(0).texture
				left.texture = player.side_three.get_child(0).texture
			elif four_pos.x < 0:
				left.texture = player.side_four.get_child(0).texture
				right.texture = player.side_three.get_child(0).texture
			elif four_pos.z < 0:
				top.texture = player.side_four.get_child(0).texture
				bottom.texture = player.side_three.get_child(0).texture
			elif four_pos.z > 0:
				bottom.texture = player.side_four.get_child(0).texture
				top.texture = player.side_three.get_child(0).texture
				
			var six_pos = round(player.side_six.global_position - player.global_position)
			if six_pos.x > 0: 
				right.texture = player.side_six.get_child(0).texture
				left.texture = player.side_one.get_child(0).texture
			elif six_pos.x < 0:
				left.texture = player.side_six.get_child(0).texture
				right.texture = player.side_one.get_child(0).texture
			elif six_pos.z < 0:
				top.texture = player.side_six.get_child(0).texture
				bottom.texture = player.side_one.get_child(0).texture
			elif six_pos.z > 0:
				bottom.texture = player.side_six.get_child(0).texture
				top.texture = player.side_one.get_child(0).texture
			
		5: # 6, opposite is 1
			opposite_texture = player.mesh.get_child(0).get_child(0).texture
			var four_pos = round(player.side_four.global_position - player.global_position)
			if four_pos.x > 0: 
				right.texture = player.side_four.get_child(0).texture
				left.texture = player.side_three.get_child(0).texture
			elif four_pos.x < 0:
				left.texture = player.side_four.get_child(0).texture
				right.texture = player.side_three.get_child(0).texture
			elif four_pos.z < 0:
				top.texture = player.side_four.get_child(0).texture
				bottom.texture = player.side_three.get_child(0).texture
			elif four_pos.z > 0:
				bottom.texture = player.side_four.get_child(0).texture
				top.texture = player.side_three.get_child(0).texture
			
			var five_pos = round(player.side_five.global_position - player.global_position)
			if five_pos.x > 0: 
				right.texture = player.side_five.get_child(0).texture
				left.texture = player.side_two.get_child(0).texture
			elif five_pos.x < 0:
				left.texture = player.side_five.get_child(0).texture
				right.texture = player.side_two.get_child(0).texture
			elif five_pos.z < 0:
				top.texture = player.side_five.get_child(0).texture
				bottom.texture = player.side_two.get_child(0).texture
			elif five_pos.z > 0:
				bottom.texture = player.side_five.get_child(0).texture
				top.texture = player.side_two.get_child(0).texture
			
			
	extra_bottom.texture = opposite_texture
	extra_left.texture = opposite_texture
	extra_right.texture = opposite_texture
	extra_top.texture  = opposite_texture
	
	animation_player.play("RESET")
	
