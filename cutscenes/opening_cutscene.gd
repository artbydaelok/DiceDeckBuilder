extends Node3D

const OPENING_CUSTCENE = preload("uid://mrq3y0iqiqdg")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	begin_opening_cutscene()
	DialogueManager.got_dialogue.connect(_on_got_dialogue)

func begin_opening_cutscene():
	animation_player.play("intro")
	
func begin_dialogue():
	DialogueManager.show_dialogue_balloon(OPENING_CUSTCENE, "start")

func portal_appears_sequence():
	animation_player.play("portal_appears")
	#DialogueManager.show_dialogue_balloon(OPENING_CUSTCENE, "enter_vortex")

func _on_got_dialogue(line: DialogueLine):
	if line.tags.size() > 0:
		var tag = line.tags.get(0)
		match tag:
			"chilling_noises":
				animation_player.play("chilling_noises")
			"groan":
				animation_player.play("groan")
			"portal_spawn":
				portal_appears_sequence()
			"remote_stolen":
				remote_stolen_sequence()
			"dice_starts_levitating":
				player_levitates_sequence()
			"player_gets_abducted":
				player_abducted_sequence()

func remote_stolen_sequence():
	animation_player.play("remote_stolen")

func player_levitates_sequence():
	animation_player.play("player_starts_levitating")
	
func player_abducted_sequence():
	animation_player.play("player_gets_abducted")
