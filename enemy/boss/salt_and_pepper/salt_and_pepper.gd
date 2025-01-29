extends Enemy



@export var traffic_light : Node3D

# Salt Variables
@onready var salt_sprite: AnimatedSprite3D = $SaltSprite
@export var salt_trigger_area: Area3D

# Pepper Variables
@onready var pepper_sprite: AnimatedSprite3D = $PepperSprite
@onready var pepper_animations: AnimationPlayer = $PepperAnimations
@export var pepper_spray: Node3D
@export var pepper_trigger_area: Area3D

enum BOSS_STATE {
	RED_MIDDLE,
	RED_SALT,
	RED_PEPPER,
	
	GREEN_MIDDLE,
	GREEN_SALT,
	GREEN_PEPPER
}

var boss_state = BOSS_STATE.RED_MIDDLE

func initialize() -> void:
	salt_trigger_area.body_entered.connect(on_salt_area_triggered)
	salt_trigger_area.body_exited.connect(on_salt_area_left)
	pepper_trigger_area.body_entered.connect(on_pepper_area_triggered)
	pepper_trigger_area.body_exited.connect(on_pepper_area_left)
	traffic_light.green_light.connect(on_green_light)
	traffic_light.red_light.connect(on_red_light)
	
	pepper_spray.finished_shooting.connect(on_pepper_spray_done)
	
func on_green_light():
	match boss_state:
		BOSS_STATE.RED_MIDDLE:
			boss_state = BOSS_STATE.GREEN_MIDDLE
		BOSS_STATE.RED_SALT:
			boss_state = BOSS_STATE.GREEN_SALT
		BOSS_STATE.RED_PEPPER:
			boss_state = BOSS_STATE.GREEN_PEPPER

func on_red_light():
	match boss_state:
		BOSS_STATE.GREEN_MIDDLE:
			boss_state = BOSS_STATE.RED_MIDDLE
		BOSS_STATE.GREEN_SALT:
			boss_state = BOSS_STATE.RED_SALT
		BOSS_STATE.GREEN_PEPPER:
			boss_state = BOSS_STATE.RED_PEPPER
			pepper_animations.play("PepperSpin")
		

func on_salt_area_triggered(player):
	if traffic_light.is_green:
		boss_state = BOSS_STATE.GREEN_SALT
	else:
		boss_state = BOSS_STATE.RED_SALT

func on_salt_area_left(player):
	if traffic_light.is_green:
		boss_state = BOSS_STATE.GREEN_MIDDLE
	else:
		boss_state = BOSS_STATE.RED_MIDDLE
	
func on_pepper_area_triggered(player):
	if traffic_light.is_green:
		boss_state = BOSS_STATE.GREEN_PEPPER
	else:
		boss_state = BOSS_STATE.RED_PEPPER

func on_pepper_area_left(player):
	if traffic_light.is_green:
		boss_state = BOSS_STATE.GREEN_MIDDLE
	else:
		boss_state = BOSS_STATE.RED_MIDDLE


func salt_grenade_attack():
	salt_sprite.play("throw_bombs")

func stop_salt_grenades():
	salt_sprite.play("default")

func on_pepper_spray_done():
	pepper_animations.play("PepperSpinBack")

func _on_pepper_animations_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"PepperSpin":
			pepper_spray.appear()
