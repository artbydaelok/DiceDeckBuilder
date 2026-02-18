extends Level

@onready var forest_demon: Node3D = $BaseLevel/ForestDemon
var has_player_killed_frog : bool = false # This variable gets changed from within the frog scripts.

@onready var axe_mesh: Node3D = %AxeMesh
const AXE_THROW = preload("uid://cwh8hm762xo3n")
@onready var axe_dialogue_trigger: Node3D = $BaseLevel/AxeObtainLocation/AxeDialogueTrigger

@onready var mother_nature_trigger_area_0: Node3D = $BaseLevel/MotherNatureTriggerArea0

@onready var red_negative_light_tweener: TweenProperty = $BaseLevel/RedNegativeLight/RedNegativeLightTweener
@onready var mother_nature_tween: TweenProperty = $BaseLevel/Player/MotherNatureLight/MotherNatureTween

# Music
@onready var level_music_player: AudioStreamPlayer = $BackgroundMusicPlayer
const BACKGROUND_MUSIC_PLAYER_SCENE = preload("uid://bkcsjsk2ciff")
const MONEY_PROBLEMS_TRACK = preload("uid://f1buplcjvh7g")
var forest_demon_music_player : AudioStreamPlayer


# IDEALLY THIS WOULD ONLY HAPPEN IF THE PLAYER DOESN'T HAVE THE AXE
func obtain_axe():
	axe_mesh.queue_free()
	card_system.set_slot_to_item(player.up_side, AXE_THROW)
	axe_dialogue_trigger.queue_free()
	
func turn_red():
	red_negative_light_tweener.play()

func show_mother_nature():
	# Music
	forest_demon_music_player = BACKGROUND_MUSIC_PLAYER_SCENE.instantiate()
	forest_demon_music_player.stream = MONEY_PROBLEMS_TRACK
	GameEvents.current_level.add_child(forest_demon_music_player)
	
	
	# Visuals
	mother_nature_tween.final_value = 25.0
	mother_nature_tween.from_value = 0.0
	mother_nature_tween.play()
	
	# Trigger areaw
	mother_nature_trigger_area_0.queue_free()
	
	# Triggers animations in the scene
	forest_demon.appear()

func hide_mother_nature():
	# Music
	#forest_demon_music_player.queue_free()
	#ProjectMusicController.play_stream_player(level_music_player)
	
	# Visuals
	mother_nature_tween.final_value = 0.0
	mother_nature_tween.from_value = 25.0
	mother_nature_tween.play()
	
	# Triggers animations in the scene
	forest_demon.disappear()
