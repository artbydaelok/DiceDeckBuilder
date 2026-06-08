extends Ability
## Bear Swipe — close-range claw.
##   PRIMARY   (LMB / A) → heavy frontal swipe: one tile in front, big damage.
##                         (Silent — the roar moved to Growl.)
##   SECONDARY (RMB / B) → Growl: a roar that buffs your NEXT attack by +50%.
##                         No swipe visual here — a rising sprite is added separately
##                         (see the TODO in initialize()).

const BEAR_SWIPE_ANIMATION = preload("res://abilities/bear_swipe/bear_swipe_animation.tscn")
const ROAR_SOUND := preload("res://assets/sounds/bear_roar_and_swipe.wav")

const GROWL_DAMAGE_MULT := 1.5   # the next player attack deals +50%


func initialize():
	if is_secondary:
		# Growl: no swipe visual. Roar + buff the next attack.
		# TODO: spawn the rising buff sprite here once it's added.
		_play_roar()
		player.next_attack_damage_mult = GROWL_DAMAGE_MULT
		return

	# Primary swipe (now silent — the roar belongs to Growl).
	var bear_swipe = BEAR_SWIPE_ANIMATION.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(bear_swipe)
	bear_swipe.global_position = player.global_position + Vector3(0, 2.5, 0)


## Play the bear roar once (used by Growl), independent of the swipe visual.
func _play_roar() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = ROAR_SOUND
	sfx.bus = &"SFX"
	get_tree().get_first_node_in_group("entities_layer").add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()
