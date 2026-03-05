extends Ability

@onready var lantern_mesh: Node3D = $LanternMesh

func tick(delta):
	lantern_mesh.global_position = player.mesh.global_position + Vector3(0, 3, 0)
