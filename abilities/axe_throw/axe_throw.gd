extends Ability
## Axe — a single ability scene with two uses, chosen by is_secondary:
##   PRIMARY (LMB / A) → Chop: melee strike on the tile in front (damages enemies,
##                       breaks obstacles).
##   SECONDARY (RMB / B) → Throw: ranged arc that flies over the adjacent tile and
##                         lands 2–3 tiles ahead.
## This is the reference pattern for two-input items: one scene, branch on input.

const AXE_PROJECTILE := preload("res://abilities/axe_throw/axe_projectile.tscn")
const HITBOX_SCENE := preload("res://core/components/hitbox.tscn")
const AXE_MODEL := preload("res://assets/3d_models/AxeByQuaternius.glb")
const WHOOSH_SFX := preload("uid://dt5rflcx7hcoa")
const HIT_SFX := preload("uid://5csvisk68nfn")

const CHOP_DAMAGE := 6
const ACTIVE_TIME := 0.18          # how long the chop hitbox stays live
const CHOP_HIT_DELAY := 0.15       # wait before the hitbox activates, so it lands with the blade
const FRONT := Vector3(0, 0, -2)   # one tile ahead in world space

# ── Chop visual (guillotine swing around an anchor inside the player) ──
## Anchor (pivot) position relative to the player — keep it inside the die.
const CHOP_PIVOT_OFFSET := Vector3(0, 2.0, 0)
## Axe offset from the anchor — the lever arm. Points up at rest so the swing
## starts above the player (out of the camera) and sweeps down to the front.
const CHOP_ARM := Vector3(0, 1.4, 0)
## The axe model's own orientation on the arm — tune so the blade faces outward.
## Y=90 matches the axe-throw model's facing (its basis is a +90° Y rotation), so
## the blade points forward (−Z) instead of left. Flip to -90 if it faces away.
const CHOP_AXE_EULER := Vector3(0, -90, 0)
const CHOP_AXE_SCALE := 1.0
const CHOP_START_DEG := 25.0    # anchor pitch at windup (up & slightly back)
const CHOP_END_DEG := -110.0    # anchor pitch at impact (forward & down)
const CHOP_SWING_TIME := 0.25
## How long the axe stays at the end of the swing before despawning (like the thrown axe sticking).
const CHOP_STUCK_TIME := 0.35

var _chop_anchor: Node3D


func initialize() -> void:
	if is_secondary:
		_throw()
	else:
		_chop()


# ── Secondary: ranged arc throw ───────────────────────────────────────────────
func _throw() -> void:
	var axe = AXE_PROJECTILE.instantiate()
	axe.player = player
	entities_layer.add_child(axe)


# ── Primary: melee chop ───────────────────────────────────────────────────────
func _chop() -> void:
	_spawn_chop_visual()
	_play_sfx(WHOOSH_SFX)
	# Delay the hitbox so it goes live as the blade reaches the bottom of the swing.
	get_tree().create_timer(CHOP_HIT_DELAY).timeout.connect(_spawn_chop_hitbox)


func _spawn_chop_hitbox() -> void:
	var hitbox: Hitbox = HITBOX_SCENE.instantiate()
	hitbox.damage = CHOP_DAMAGE
	hitbox.collision_mask = 48  # EnemyHurtbox (layer 5) + Breakable (layer 6)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 2.0, 1.8)  # one tile
	shape.shape = box
	hitbox.add_child(shape)
	hitbox.area_entered.connect(_on_chop_hit)

	entities_layer.add_child(hitbox)
	hitbox.global_position = player.global_position + FRONT + Vector3(0, 0.5, 0)

	# Hitbox lives independently of this ability node; free it after the active window.
	get_tree().create_timer(ACTIVE_TIME).timeout.connect(hitbox.queue_free)


## Guillotine chop: the axe sits on a lever arm off an anchor inside the player.
## Rotating the anchor about its X axis sweeps the axe from above the player
## (visible, clear of the camera) down and forward into the tile in front.
## Pose/angles are placeholder — tune the consts above to taste.
func _spawn_chop_visual() -> void:
	var anchor := Node3D.new()
	_chop_anchor = anchor
	entities_layer.add_child(anchor)
	anchor.global_position = player.global_position + CHOP_PIVOT_OFFSET
	anchor.rotation_degrees = Vector3(CHOP_START_DEG, 0, 0)

	var axe := AXE_MODEL.instantiate()
	anchor.add_child(axe)              # axe rides the arm; rotating anchor swings it
	axe.position = CHOP_ARM
	axe.rotation_degrees = CHOP_AXE_EULER
	axe.scale = Vector3.ONE * CHOP_AXE_SCALE

	var t := anchor.create_tween()
	t.tween_property(anchor, "rotation_degrees", Vector3(CHOP_END_DEG, 0, 0), CHOP_SWING_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(_on_swing_done)


## Break obstacles the chop overlaps. (Enemy damage is handled by the Hitbox itself.)
func _on_chop_hit(area: Area3D) -> void:
	var target := area.get_parent()
	if target and target.has_method("axe_hit"):
		target.axe_hit()


## End of the swing: thunk on landing (like the thrown axe), then leave the axe at
## the end pose for a beat before despawning.
func _on_swing_done() -> void:
	if not is_instance_valid(_chop_anchor):
		return
	_play_sfx(HIT_SFX)
	get_tree().create_timer(CHOP_STUCK_TIME).timeout.connect(_chop_anchor.queue_free)


func _play_sfx(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = &"SFX"
	entities_layer.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
