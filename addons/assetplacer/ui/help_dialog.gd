# help_dialog.gd
# © Copyright CookieBadger 2026
@tool
extends AcceptDialog


func init_shortcut_table(p_shortcut_string_dict: Dictionary[String, String]) -> void:
	get_node("%ShortcutsTable").initialize(p_shortcut_string_dict)
