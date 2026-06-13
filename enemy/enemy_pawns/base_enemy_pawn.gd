extends CharacterBody3D
class_name Enemy

@export var max_health: int = 1
var current_health: int

## Identifies this enemy's type for kill tracking / quests. If left blank,
## it is auto-derived from the scene filename (see _resolve_enemy_id()).
@export var enemy_id: String = ""

## If true (default), the Bear Trap can capture this enemy and re-summon it as a
## one-shot charging ally. Set false on bosses / enemies that shouldn't be trappable.
@export var capturable: bool = true

## Modifiers applied to this enemy at spawn — visual sheen + behavior + stat tweaks.
## Drop e.g. the Poison modifier here to make a Poisonous variant.
@export var modifiers: Array[EnemyModifier] = []

signal died
## Emitted when the enemy takes damage but survives (drives hit-react juice, etc).
signal damaged(amount: int)

## How fast the enemy will move per second or per player move. By default 2.0 is one "tile".
@export var move_speed = 2.0

var player : Player
var initial_height: float

## Set true BEFORE adding to the tree to spawn this enemy as a friendly one-shot
## charging ally (Bear Trap's release) instead of a hostile enemy.
var is_ally: bool = false

# Ally charge tunables (Bear Trap release).
const ALLY_HITBOX := preload("res://core/components/hitbox.tscn")
const ALLY_CHARGE_TILES := 4
const ALLY_CHARGE_TIME := 0.6
const ALLY_DAMAGE := 6

func _ready() -> void:
	if is_ally:
		_setup_ally()  # friendly puppet — skip all the hostile enemy setup below
		return
	_apply_modifiers()  # may change max_health before we read it
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	player.roll_finished.connect(_on_player_rolled)
	player.player_moved.connect(_on_player_moved)
	initial_height = global_position.y

	initialize()


## Apply each modifier's stat tweaks, visual overlay, and behavior node.
func _apply_modifiers() -> void:
	for mod in modifiers:
		if mod == null:
			continue
		max_health = int(round(max_health * mod.health_mult))
		move_speed *= mod.speed_mult
		if mod.overlay_material != null:
			for m in find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).material_overlay = mod.overlay_material
		if mod.behavior_scene != null:
			add_child(mod.behavior_scene.instantiate())

#region # OVERRIDABLE FUNCTIONS
func initialize(): # OVERRIDABLE FUNCTION
	pass

# Triggers when player begins moving
func _on_player_moved(direction: Vector3): # OVERRIDABLE FUNCTION
	pass

# Triggers when player is done moving
func _on_player_rolled(): # OVERRIDABLE FUNCTION
	pass

func tick(delta): # OVERRIDABLE FUNCTION
	pass

func on_died() -> void:
	# If a CreatureAnimator is attached, play its death splat first, then free.
	# Duck-typed so the base doesn't hard-depend on the component.
	var anim = _creature_animator()
	if anim != null:
		set_physics_process(false)  # stop moving while it plays out
		for hb in find_children("*", "Hitbox", true, false):
			hb.set_deferred("monitoring", false)
		for hb in find_children("*", "Hurtbox", true, false):
			hb.set_deferred("monitoring", false)
		anim.death_finished.connect(queue_free)
		anim.play_death()
	else:
		queue_free()

func _creature_animator() -> Node:
	for c in get_children():
		if c.has_method("play_death") and c.has_signal("death_finished"):
			return c
	return null
#endregion # OVERRIDABLE FUNCTIONS

func apply_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		GameEvents.enemy_killed.emit(_resolve_enemy_id())
		died.emit()
		on_died()
	else:
		damaged.emit(amount)

## Returns the type id used for kill tracking. Prefers the exported enemy_id,
## then the scene filename (e.g. "frog_enemy"), then the node name.
func _resolve_enemy_id() -> String:
	if enemy_id != "":
		return enemy_id
	if scene_file_path != "":
		return scene_file_path.get_file().get_basename()
	return name.to_lower()

func _physics_process(delta: float) -> void:
	if is_ally:
		return  # ally movement is tween-driven (see release_charge)
	tick(delta)
	move_and_slide()


## Friendly setup: strip the hostile combat parts and add a hitbox that hurts ENEMIES.
## The captured creature's model/visuals carry over, so it looks like what you trapped.
func _setup_ally() -> void:
	for n in find_children("*", "Hitbox", true, false):
		n.queue_free()   # remove the player-damaging hitbox
	for n in find_children("*", "Hurtbox", true, false):
		n.queue_free()   # no friendly fire / no being targeted

	var hb: Hitbox = ALLY_HITBOX.instantiate()
	hb.damage = ALLY_DAMAGE
	hb.collision_mask = 48  # EnemyHurtbox (layer 5) + Breakable (layer 6)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 2.0, 1.8)
	shape.shape = box
	hb.add_child(shape)
	add_child(hb)


## Charge forward a few tiles (damaging enemies in the path), then vanish.
## Call this AFTER positioning the ally at its spawn spot.
func release_charge() -> void:
	var to := global_position + Vector3(0, 0, -2.0 * ALLY_CHARGE_TILES)  # forward is −Z
	var tw := create_tween()
	tw.tween_property(self, "global_position", to, ALLY_CHARGE_TIME).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(queue_free)

# Movement should be restricted to a grid.

# Some attacks hit only grounded enemies, while others may only hit flying enemies. Some attacks can do both.
