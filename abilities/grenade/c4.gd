extends Node3D
## A planted C4 charge — the Grenade's secondary. Plant it at your feet; it ARMS
## (glows) once you step off its tile, then the grenade secondary detonates it.
## Reuses the grenade's explosion blast. Built entirely in code so there's no scene
## to manage; swap the placeholder mesh for a real C4 model when you have one.

const EXPLOSION_BLAST := preload("res://vfx/explosion_blast.tscn")

var _player: Node = null
var _armed := false
var _placed_tile := Vector2.ZERO
var _mat: StandardMaterial3D
var _t := 0.0


## Call before adding to the tree.
func setup(p: Node) -> void:
	_player = p


func _ready() -> void:
	# Placeholder visual: a khaki brick that glows red once armed.
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.5, 1.0)
	mi.mesh = box
	mi.position.y = 0.25  # sit on the ground
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.32, 0.28, 0.16)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.1, 0.0)
	_mat.emission_energy_multiplier = 0.0  # dark until armed
	mi.material_override = _mat
	add_child(mi)

	if _player != null:
		_placed_tile = _tile()
		if _player.has_signal("roll_finished"):
			_player.roll_finished.connect(_on_roll_finished)


func _process(delta: float) -> void:
	if _armed:
		_t += delta
		_mat.emission_energy_multiplier = 1.5 + sin(_t * 8.0)  # blink while live


func _tile() -> Vector2:
	return Vector2(_player.x_grid_pos, _player.y_grid_pos)


## Arms once the player has stepped off the tile it was planted on.
func _on_roll_finished() -> void:
	if not _armed and _tile() != _placed_tile:
		_armed = true


## Remote-detonate: blast at this spot, then remove the charge.
func detonate() -> void:
	var blast = EXPLOSION_BLAST.instantiate()
	if "is_player_attack" in blast:
		blast.is_player_attack = true
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position + Vector3(0, 0.5, 0)
	queue_free()
