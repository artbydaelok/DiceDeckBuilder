extends Node
class_name HealthComponent

## HealthComponent
##
## Drop this as a child of any node that needs health, damage, and death.
## Connect its signals to handle visuals, SFX, and scene changes in the parent.
##
## Usage:
##   health_component.apply_damage(10)
##   health_component.heal(5)
##   health_component.damaged.connect(_on_damaged)
##   health_component.died.connect(_on_died)

## Maximum health. Also used as starting health.
@export var max_health: int = 100

## How long (in seconds) the owner is invulnerable after taking damage.
@export var invulnerability_duration: float = 1.0

var health: int
var is_dead: bool = false
var invulnerable: bool = false

## Emitted when damage is applied. amount is the damage dealt.
signal damaged(amount: float)
## Emitted when health is restored.
signal healed(amount: float)
## Emitted whenever health changes for any reason.
signal health_updated(new_health: float)
## Emitted once when health reaches zero.
signal died


func _ready() -> void:
	health = max_health
	health_updated.emit(health)


func apply_damage(amount: float) -> void:
	if invulnerable or is_dead:
		return
	invulnerable = true
	health -= amount
	health = clampf(health, 0, max_health)
	damaged.emit(amount)
	health_updated.emit(health)

	if health <= 0:
		is_dead = true
		died.emit()

	await get_tree().create_timer(invulnerability_duration).timeout
	invulnerable = false


func heal(amount: float) -> void:
	if health >= max_health or is_dead:
		return
	health += amount
	health = clampf(health, 0, max_health)
	healed.emit(amount)
	health_updated.emit(health)
