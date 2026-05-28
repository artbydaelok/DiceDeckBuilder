# settings.gd
# © Copyright CookieBadger 2026
@tool
extends Object

const SETTINGS_PREFIX: String = "Asset_Placer"
const DEFAULT_CATEGORY: String = "Settings"

const USE_SHIFT_SETTING: String = "Use_Shift_instead_of_Alt"
const LIBRARY_SAVE_LOCATION: String = "Library_Save_File_Location"
const SURFACE_COLLISION_MASK: String = "Surface_Placement_Collision_Mask"


static func init_settings() -> void:
	register_setting(DEFAULT_CATEGORY, USE_SHIFT_SETTING, false, TYPE_BOOL)
	register_setting(DEFAULT_CATEGORY, SURFACE_COLLISION_MASK, 0xFFFFFFFF, TYPE_INT, PROPERTY_HINT_LAYERS_3D_PHYSICS)


static func register_setting(p_category: String, p_setting_name: String, p_default_value: Variant, p_type: Variant.Type, p_hint: PropertyHint = PROPERTY_HINT_NONE, p_hint_string: String = "") -> void:
	# Register a new ProjectSetting
	var path := SETTINGS_PREFIX + "/" + p_category + "/" + p_setting_name

	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, p_default_value)
		ProjectSettings.set_initial_value(path, p_default_value)

	var property_info := {"name": path, "type": p_type, "hint": p_hint, "hint_string": p_hint_string}
	ProjectSettings.add_property_info(property_info)


static func get_setting(p_category: String, p_setting_name: String) -> Variant:
	return ProjectSettings.get_setting(SETTINGS_PREFIX + "/" + p_category + "/" + p_setting_name)
