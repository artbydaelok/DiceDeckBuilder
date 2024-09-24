extends Ability

const BOW_AND_ARROW_MESH = preload("res://abilities/bow_and_arrow/bow_and_arrow_mesh.tscn")


func initialize():
	var bow = BOW_AND_ARROW_MESH.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(bow)
	bow.global_position = player.global_position + Vector3(0, 2.5, 0)
