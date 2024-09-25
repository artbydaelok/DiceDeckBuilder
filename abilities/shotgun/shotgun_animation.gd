extends Node3D

const SHOTGUN_PELLET = preload("res://abilities/shotgun/shotgun_pellet.tscn")
@onready var pellet_spawn: Marker3D = $PelletSpawn

func spawn_pellets():
	for i in range(2):
		var pellet = SHOTGUN_PELLET.instantiate()
		get_tree().get_first_node_in_group("entities_layer").add_child(pellet)
		pellet.global_position = pellet_spawn.global_position
