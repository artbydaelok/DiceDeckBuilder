extends Node3D

const OPENING_CUSTCENE = preload("uid://mrq3y0iqiqdg")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	begin_opening_cutscene()
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func begin_opening_cutscene():
	animation_player.play("0_intro")
	
func begin_dialogue():
	DialogueManager.show_dialogue_balloon(OPENING_CUSTCENE, "start")

func _on_got_dialogue(line: DialogueLine):
	if line.tags.size() > 0:
		var tag = line.tags.get(0)
		match tag:
			"chilling_noises":
				animation_player.play("1_chilling_noises")
			"first_groan":
				animation_player.play("2_first_groan")
			"portal_spawn":
				animation_player.play("3_portal_appears")
			"remote_stolen":
				animation_player.play("4_remote_stolen")
			"second_groan":
				animation_player.play("5_second_groan")
			"dice_starts_levitating":
				animation_player.play("6_player_starts_levitating")
			"player_gets_abducted":
				animation_player.play("7_player_gets_abducted")
			"enter_vortex":
				animation_player.play("8_enter_vortex")
			"warp":
				animation_player.play("9_warp_out")

func _on_dialogue_ended(dialogue_resource : DialogueResource):
	#go_to_hub()
	pass

func go_to_hub():
	SceneLoader.load_scene("res://levels/hub_level.tscn")
