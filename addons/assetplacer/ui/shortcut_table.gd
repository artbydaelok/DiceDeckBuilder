# shortcut_table.gd
# © Copyright CookieBadger 2026
@tool
extends GridContainer


func initialize(p_shortcut_string_dict: Dictionary[String, String]) -> void:
	for child in get_children():
		child.queue_free()

	for shortcut: String in p_shortcut_string_dict.keys():
		var name_label := Label.new()
		add_child(name_label)
		name_label.text = shortcut

		var shortcut_label := Label.new()
		add_child(shortcut_label)
		shortcut_label.text = p_shortcut_string_dict[shortcut]
