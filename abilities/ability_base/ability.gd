extends Node
class_name Ability

@onready var self_destroy_timer: Node = $SelfDestroyTimer

var entities_layer : Node3D
var player : Player

## Which input fired this ability. Set by CardSystem before the node enters the
## tree, so initialize() can branch: false = primary (LMB/A), true = secondary (RMB/B).
## A single ability scene can implement both uses by reading this flag.
var is_secondary : bool = false

## Seconds the input was held before firing (0 for instant abilities). Set by
## CardSystem before the node enters the tree. Chargeable abilities read this to
## scale power / crit / projectile count.
var charge : float = 0.0

## True when this ability was spawned for a hold/charge (so initialize() should
## show the held/charging state and wait for on_charge_release()/on_charge_cancel()).
var is_charging : bool = false


## Called when the player releases the charge. Override to fire. `charge` holds the
## final held time (set by CardSystem just before this is called).
func on_charge_release() -> void:
	pass

## Called if the charge is cancelled (rolled away, interrupted). Default: clean up.
func on_charge_cancel() -> void:
	queue_free()


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	initialize()
	
func initialize():
	pass
	
func _process(delta: float) -> void:
	tick(delta)
	
func tick(delta):
	pass
