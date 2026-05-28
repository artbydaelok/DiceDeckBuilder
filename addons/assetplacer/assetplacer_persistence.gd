# assetplacer_persistence.gd
# © Copyright CookieBadger 2026
@tool
extends Object

const PluginData = preload("res://addons/assetplacer/data_formats/plugin_data.gd")
const SceneData = preload("res://addons/assetplacer/data_formats/scene_data.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")

const SAVE_FOLDER: String = ".assetplacerGD"
const SAVE_FILE_NAME: String = "data"

static var instance: AssetPlacerPersistence:
	get:
		if !_instance:
			initialize()
		return _instance

static var _instance: AssetPlacerPersistence

var save_folder_path := "user://" + SAVE_FOLDER
var data_path := "user://%s/%s.tres" % [SAVE_FOLDER, SAVE_FILE_NAME]

var _current_scene_path: String:
	get:
		var root := EditorInterface.get_edited_scene_root()
		if root:
			return root.get_scene_file_path()
		return ""

var _plugin_data: PluginData
var _dirty: bool = false


static func initialize() -> void:
	_instance = AssetPlacerPersistence.new()
	_instance._load_plugin_data()


static func cleanup() -> void:
	_instance.free()
	_instance = null


func store_global_data(p_key: String, p_value: Variant) -> void:
	_create_plugin_data_if_not_exists()
	var old_value_exists := _plugin_data.global_data.has(p_key)
	var old_value_equals: bool = old_value_exists && (_plugin_data.global_data[p_key] == p_value)
	_dirty = _dirty or !old_value_equals
	_plugin_data.global_data[p_key] = p_value


func load_global_data(key: String, p_default_value: Variant, p_expected_type: Variant.Type) -> Variant:
	_create_plugin_data_if_not_exists()
	if _plugin_data.global_data.has(key):
		var variant: Variant = _plugin_data.global_data[key]
		if typeof(variant) == p_expected_type:
			return variant
		printerr(
			(
				"AssetPlacerPlugin: Loaded data is of wrong type. Expected type: %d (%s), Received Type: %d (%s)"
				% [p_expected_type, type_string(p_expected_type), typeof(variant), type_string(typeof(variant))]
			)
		)
	return p_default_value


func load_scene_data(p_key: String, p_default_value: Variant, p_expected_type: int) -> Variant:
	_create_plugin_data_if_not_exists()
	if _plugin_data.scene_data.has(_current_scene_path):
		var scene_data: Variant = _plugin_data.scene_data[_current_scene_path]
		if scene_data.data.has(p_key):
			var variant: Variant = scene_data.data[p_key]
			if typeof(variant) == p_expected_type:
				return variant
			var converted: Variant = _try_variant_conversion(variant, p_expected_type)
			if converted:
				push_warning(
					(
						"AssetPlacerPlugin: Loaded data for scene_data[%s] was of wrong type, but could be converted. Expected type: %d (%s), Received Type: %d (%s). Data was converted and loaded."
						% [p_key, p_expected_type, type_string(p_expected_type), typeof(variant), type_string(typeof(variant))]
					)
				)
				return converted
			printerr("AssetPlacerPlugin: Error loading scene_data[%s]. Type mismatch: %d != %d" % [p_key, typeof(variant), p_expected_type])
	return p_default_value


func _try_variant_conversion(p_data: Variant, p_expected_type: int) -> Variant:
	if typeof(p_data) == TYPE_ARRAY:
		if TYPE_PACKED_BYTE_ARRAY <= p_expected_type and p_expected_type <= TYPE_PACKED_VECTOR4_ARRAY:
			return Array(p_data)
	elif p_expected_type == TYPE_ARRAY:
		match typeof(p_data):
			TYPE_PACKED_BYTE_ARRAY:
				return PackedByteArray(p_data)
			TYPE_PACKED_INT32_ARRAY:
				return PackedInt32Array(p_data)
			TYPE_PACKED_INT64_ARRAY:
				return PackedInt64Array(p_data)
			TYPE_PACKED_FLOAT32_ARRAY:
				return PackedFloat32Array(p_data)
			TYPE_PACKED_FLOAT64_ARRAY:
				return PackedFloat64Array(p_data)
			TYPE_PACKED_STRING_ARRAY:
				return PackedStringArray(p_data)
			TYPE_PACKED_VECTOR2_ARRAY:
				return PackedVector2Array(p_data)
			TYPE_PACKED_VECTOR3_ARRAY:
				return PackedVector3Array(p_data)
			TYPE_PACKED_COLOR_ARRAY:
				return PackedColorArray(p_data)
			TYPE_PACKED_VECTOR4_ARRAY:
				return PackedVector4Array(p_data)
	elif p_expected_type == TYPE_NODE_PATH:
		if typeof(p_data) == TYPE_STRING:
			return NodePath(p_data)
	elif p_expected_type == TYPE_STRING:
		if typeof(p_data) == TYPE_NODE_PATH:
			return str(p_data)
	return null


func store_scene_data(p_key: String, p_value: Variant) -> void:
	var scene_key := _current_scene_path
	if scene_key == null:
		return

	_create_plugin_data_if_not_exists()
	if not _plugin_data.scene_data.has(scene_key):
		_plugin_data.scene_data[scene_key] = SceneData.new()

	var scene_data := _plugin_data.scene_data[scene_key]
	var old_value_exists := scene_data.data.has(p_key)
	var old_value_equals: bool = old_value_exists && typeof(scene_data.data[p_key]) == typeof(p_value) && scene_data.data[p_key] == p_value
	_dirty = _dirty or !old_value_equals
	scene_data.data[p_key] = p_value


func _create_plugin_data_if_not_exists() -> void:
	if _plugin_data == null or _plugin_data.scene_data == null or _plugin_data.global_data == null:
		_plugin_data = PluginData.new()


func _load_plugin_data() -> void:
	_check_save_folder_exists()
	var success := false
	if ResourceLoader.exists(data_path):
		_plugin_data = ResourceLoader.load(data_path)
		success = _plugin_data is PluginData
	if not success:
		_plugin_data = PluginData.new()
		var e := ResourceSaver.save(_plugin_data, data_path)
		if e != OK:
			printerr("AssetPlacerPlugin: %d error on saving resource data at %s" % [str(e), data_path])
	_dirty = false


# Safety: don't recreate the singleton if it doesnt exist
static func save_plugin_data() -> void:
	if _instance:
		_instance._save_plugin_data()


func _save_plugin_data() -> void:
	if _dirty:
		var err := ResourceSaver.save(_plugin_data, data_path)
		if err != OK:
			printerr("AssetPlacerPlugin: Error saving file at " + data_path + ": " + str(err))
		else:
			_dirty = false


func get_show_license_and_set_false() -> bool:
	var show := _plugin_data.show_license_on_start
	_plugin_data.show_license_on_start = false
	return show


func _check_save_folder_exists() -> void:
	check_folder_exists(save_folder_path)


static func check_folder_exists(p_folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(p_folder_path):
		DirAccess.make_dir_recursive_absolute(p_folder_path)
