# asset_palette_controller.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/viewport_3d_controller.gd"

## singletons and statics
const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const AssetPersistentData = preload("res://addons/assetplacer/asset_palette/asset_persistent_data.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")
const AssetInstantiator = preload("res://addons/assetplacer/asset_palette/asset_instantiator.gd")

## references
const AssetPaletteView = preload("res://addons/assetplacer/ui/asset_palette_view.gd")
const DynamicPreviewView = preload("res://addons/assetplacer/ui/dynamic_preview_view.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetLibrary = preload("res://addons/assetplacer/asset_palette/asset_library.gd")
const AssetLibraryData = preload("res://addons/assetplacer/asset_palette/asset_library_data.gd")
const AssetPreviewGenerator = preload("res://addons/assetplacer/asset_palette/preview_generation/asset_preview_generator.gd")
const DynamicPreviewController = preload("res://addons/assetplacer/asset_palette/preview_generation/dynamic_preview_controller.gd")
const AssetZooGenerator = preload("res://addons/assetplacer/asset_palette/asset_zoo_generator.gd")
const AssetPlacerButton = preload("res://addons/assetplacer/ui/assetplacer_button.gd")

const NEW_LIBRARY_NAME: String = "Unnamed Library"
const RES_FILE_ENDING = ".res"
const TRES_FILE_ENDING = ".tres"
const ASSET_LIBRARY_SAVE_FOLDER = ".assetplacer_libraries"

var palette_state: AssetPlacerState.PaletteState:
	get:
		return AssetPlacerState.instance.palette_state

var _asset_palette_view: AssetPaletteView

var _preview_generator: AssetPreviewGenerator
var _dynamic_preview_controller: DynamicPreviewController


static func get_asset_library_dir_path(p_access: FileDialog.Access) -> String:
	var prefix := "user://" if p_access == FileDialog.ACCESS_USERDATA else "res://"
	return prefix + ASSET_LIBRARY_SAVE_FOLDER


static func _can_match_selection(p_selected_nodes: Array, p_root: Node) -> bool:
	return p_selected_nodes.size() == 1 && p_selected_nodes[0].owner == p_root


func cleanup() -> void:
	_preview_generator._cleanup()
	_preview_generator.queue_free()


func initialize(p_asset_palette_view: AssetPaletteView, p_dynamic_preview_view: DynamicPreviewView) -> void:
	_preview_generator = AssetPreviewGenerator.new()
	add_child(_preview_generator)
	_dynamic_preview_controller = DynamicPreviewController.new()

	_asset_palette_view = p_asset_palette_view
	_init_view()
	var opened_libraries: Array[String] = []
	opened_libraries.assign(AssetPlacerPersistence.instance.load_global_data(palette_state.OPENED_LIBRARIES_SAVE_KEY, [], TYPE_ARRAY))
	var last_selected_library: String = AssetPlacerPersistence.instance.load_global_data(palette_state.LAST_SELECTED_SAVE_KEY, "", TYPE_STRING)
	_init_libraries(opened_libraries, last_selected_library)

	palette_state.save_disabled = true
	AssetPlacerState.instance.palette_state.current_library_state_changed.connect(_update_save_disabled)
	AssetPlacerState.instance.palette_state.broken_asset_instantiated.connect(func(asset: Asset3DData) -> void: _reload_asset_preview(asset.path))
	AssetPlacerState.instance.scene_changed.connect(deselect_asset)

	_dynamic_preview_controller.preview_updated.connect(_on_update_dynamic_preview)
	_dynamic_preview_controller.initialize(_preview_generator.get_dynamic_preview_vp(), p_dynamic_preview_view)


# override
func forward_3d_viewport_input(_p_viewport: SubViewport, _p_event: InputEvent, _p_action: InputManager.ActionType) -> void:
	pass


func _init_view() -> void:
	_asset_palette_view.assets_added.connect(_on_add_new_asset)
	_asset_palette_view.asset_selected.connect(_on_select_asset)
	_asset_palette_view.assets_removed.connect(_on_remove_asset)
	_asset_palette_view.asset_transform_reset.connect(_on_reset_asset_transform)
	_asset_palette_view.asset_library_selected_to_load.connect(_on_library_load)
	_asset_palette_view.asset_tab_selected.connect(_on_asset_library_select)
	_asset_palette_view.libraries_reordered.connect(reorder_libraries)
	_asset_palette_view.new_tab_pressed.connect(_on_new_asset_library)
	_asset_palette_view.asset_library_saved.connect(_save_library_at)
	_asset_palette_view.asset_library_removed.connect(_on_remove_asset_library)
	_asset_palette_view.reload_asset_preview.connect(_reload_asset_preview)
	_asset_palette_view.match_selected_pressed.connect(_on_match_selected_pressed)

	_asset_palette_view.generate_zoo.connect(generate_zoo)

	# previews
	_asset_palette_view.reload_library_previews.connect(_on_reload_library_previews)
	_asset_palette_view.default_library_previews.connect(_on_default_library_previews)
	_asset_palette_view.library_preview_perspective_changed.connect(_on_library_preview_perspective_changed)
	_asset_palette_view.asset_preview_perspective_changed.connect(_on_asset_preview_perspective_changed)
	_asset_palette_view.dynamic_preview_shown.connect(_on_show_dynamic_preview)


func _process(p_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	_preview_generator.process()
	_dynamic_preview_controller.process(p_delta)


func generate_zoo(p_library: String) -> void:
	assert(palette_state.library_data_dict.has(p_library), "Data of library %s not found" % [p_library])

	var library_data: AssetLibraryData = palette_state.library_data_dict[p_library]
	var generator := AssetZooGenerator.new()
	add_child(generator)

	generator.generate(p_library, library_data)
	generator.finished.connect(func() -> void: generator.queue_free())


func _on_match_selected_pressed() -> void:
	var edited_scene_root: Node = EditorInterface.get_edited_scene_root()
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()

	if _can_match_selection(selected_nodes, edited_scene_root):
		var selected := selected_nodes[0]

		var asset_path: String
		if selected.scene_file_path:
			asset_path = selected.scene_file_path
		elif selected is MeshInstance3D:
			var resource_path: String = selected.mesh.resource_path
			var mesh_instance_file_endings: Array = [".res", ".tres", ".obj"]
			if resource_path.begins_with("res://") and mesh_instance_file_endings.any(func(s: String) -> bool: return resource_path.ends_with(s)):
				asset_path = resource_path
			else:
				printerr("AssetPlacerPlugin: To add %s as an asset, either save as a scene, or save its Mesh as a Resource." % [selected.name])
				return

		if asset_path:
			if not palette_state.current_library_data or not palette_state.current_library_data.has_asset(asset_path):
				_on_add_new_asset([asset_path])
			palette_state.selected_asset = palette_state.current_library_data.get_asset(asset_path)
			_asset_palette_view.scroll_to_asset_button(asset_path)
		else:
			printerr("AssetPlacerPlugin: To add %s as an asset, save it as a scene first (needs to be an instanced scene)." % [selected.name])


func _on_reload_library_previews(p_library: String) -> void:
	assert(palette_state.library_data_dict.has(p_library), "Data of library %s not found" % [p_library])
	palette_state.switch_library(p_library)
	generate_previews(palette_state.current_library_data, palette_state.current_library_data.asset_data, true)


func _reload_asset_preview(p_path: String) -> void:
	assert(palette_state.current_library_data.get_asset_paths().has(p_path), "Asset %s is not part of current library" % p_path)
	var asset := palette_state.current_library_data.asset_data.filter(func(a: Asset3DData) -> bool: return a.path == p_path)
	generate_previews(palette_state.current_library_data, asset, true)


func _on_remove_asset_library(p_library_name: String) -> void:
	if palette_state.library_data_dict.has(p_library_name):
		var was_current: bool = p_library_name == palette_state.current_library
		palette_state.remove_library(p_library_name)
		if was_current:
			deselect_asset()
			_update_save_disabled()
		_store_opened_libraries()


func reorder_libraries(p_library_titles_reordered: Array[String]) -> void:
	assert(p_library_titles_reordered.size() == palette_state.library_titles_sorted.size())
	palette_state.library_titles_sorted = p_library_titles_reordered
	_store_opened_libraries()


func _store_opened_libraries() -> void:
	# Store libraries in the order they are opened in the tab bar, excluding any that have not been saved yet
	var paths: Array[String]
	paths.assign(palette_state.library_titles_sorted.map(func(l: String) -> String: return palette_state.library_data_dict[l].save_path).filter(func(p: String) -> bool: return !!p))
	AssetPlacerPersistence.instance.store_global_data(palette_state.OPENED_LIBRARIES_SAVE_KEY, paths)


func _on_new_asset_library() -> void:
	var lib_name := _on_new_named_asset_library(NEW_LIBRARY_NAME)
	switch_library(lib_name)


func _on_new_named_asset_library(p_name: String) -> String:
	var library_name := _get_available_library_name(p_name)
	palette_state.add_library(library_name, AssetLibraryData.new())
	return library_name


func _init_libraries(p_opened_libraries: Array[String], p_selected_library: String) -> void:
	if p_opened_libraries.is_empty():
		return
	for library_path: String in p_opened_libraries.filter(func(l: String) -> bool: return !!l):
		load_library(library_path)

	var library := _get_library_name_from_path(p_selected_library)
	if !library:
		library = _get_library_name_from_path(p_opened_libraries[0])
	switch_library(library)


# Returns the name with which the library can be selected in the UI (tab title).
# Not to be confused with the library file name.
func _get_library_name_from_path(p_select_library_path: String) -> String:
	var filter := palette_state.library_data_dict.keys().filter(func(a: String) -> bool: return palette_state.library_data_dict[a].save_path == p_select_library_path)
	return filter[0] if filter.size() > 0 else ""


func _get_file_name_from_path(p_path: String) -> String:
	var file_name_full := p_path.get_file()
	return file_name_full.substr(0, file_name_full.length() - 5)


func _on_asset_library_select(p_tab_title: String) -> void:
	if p_tab_title == palette_state.current_library:
		return
	switch_library(p_tab_title)


func switch_library(p_library_name: String) -> void:
	if p_library_name == palette_state.current_library:
		return
	deselect_asset()
	palette_state.switch_library(p_library_name)

	if palette_state.current_library_data.save_path:
		AssetPlacerPersistence.instance.store_global_data(palette_state.LAST_SELECTED_SAVE_KEY, palette_state.current_library_data.save_path)
	cancel_queued_preview_generation()
	generate_previews(palette_state.current_library_data, palette_state.current_library_data.asset_data, false)

	_update_save_disabled()


func _on_library_load(p_path: String) -> void:
	var library_name: String = load_library(p_path)
	if library_name:
		switch_library(library_name)


func load_library(p_path: String) -> String:
	var library_name := ""
	var asset_library_resource := ResourceLoader.load(p_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if asset_library_resource is AssetLibrary:  # path must be up-to-date
		var existing_library := _get_library_name_from_path(p_path)
		if existing_library.is_empty():
			library_name = _on_new_named_asset_library(_get_file_name_from_path(p_path))
			var library_data := palette_state.library_data_dict[library_name]
			asset_library_resource.unpack_into(library_data)
			palette_state.mark_library_dirty(library_data, false)
			library_data.save_path = p_path
			palette_state.update_library_data(library_name, library_data)
			_update_save_disabled()
			_store_opened_libraries()
		else:
			print("AssetPlacerPlugin: %s is already loaded" % p_path)

	else:
		printerr("AssetPlacerPlugin: Resource found at %s is not a scene library" % [p_path])
	return library_name


func _save_library_at(p_library_key: String, p_path: String, p_change_name: bool) -> void:
	if !palette_state.library_data_dict.has(p_library_key):
		printerr("AssetPlacerPlugin: Error saving asset library '%s'" % p_library_key)

	# check if different library with same file location loaded
	if palette_state.library_data_dict.keys().any(func(lib: String) -> bool: return lib != p_library_key and palette_state.library_data_dict[lib].save_path == p_path):
		printerr("AssetPlacerPlugin: Error saving asset library at %s: A library saved to %s is currently open." % [p_path, p_path])

	# create a SceneLibrary resource and copy the assetPaths into it
	var asset_library_data := palette_state.library_data_dict[p_library_key]
	var asset_library := AssetLibrary.build_asset_library(asset_library_data)
	var folder := p_path.get_base_dir()
	if folder && !folder.is_empty() && !DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)

	var error := ResourceSaver.save(asset_library, p_path)
	if error == OK:
		print_rich("[b]Asset selection saved to: %s[/b]" % p_path)
		palette_state.mark_library_dirty(palette_state.library_data_dict[p_library_key], false)
		palette_state.library_data_dict[p_library_key].save_path = p_path
		if p_change_name:
			_change_library_name(p_library_key, _get_file_name_from_path(p_path))
		_store_opened_libraries()
	else:
		printerr("AssetPlacerPlugin: Error saving asset library: %s" % error)


func _update_save_disabled() -> void:
	if !palette_state.library_data_dict.has(palette_state.current_library):
		palette_state.save_disabled = true
	else:
		var has_changes := palette_state.current_library_data.save_path == null || palette_state.current_library_data.dirty
		palette_state.save_disabled = !has_changes


func _change_library_name(p_old_name: String, p_new_name: String) -> void:
	if p_old_name == p_new_name:
		return
	var available_new_name := _get_available_library_name(p_new_name)
	palette_state.rename_library(p_old_name, available_new_name)


func _on_reset_asset_transform(p_path: String) -> void:
	var data := palette_state.current_library_data.get_asset(p_path)
	palette_state.reset_asset_transform(palette_state.current_library_data, data)


func _on_select_asset(p_path: String) -> void:
	var path_null := p_path == null || p_path.is_empty()
	if (path_null && palette_state.selected_asset == null) || (palette_state.selected_asset && p_path == palette_state.selected_asset.path):
		return

	palette_state.selected_asset = null if path_null else palette_state.current_library_data.get_asset(p_path)


func _is_valid_file(p_file_path: String) -> bool:
	const SCENE_FILE_ENDING := ".tscn"
	const COMPRESSED_SCENE_FILE_ENDING := ".scn"
	const OBJ_FILE_ENDING = ".obj"
	const GLTF_FILE_ENDING = ".gltf"
	const GLB_FILE_ENDING = ".glb"
	const FBX_FILE_ENDING = ".fbx"
	const COLLADA_FILE_ENDING = ".dae"
	const BLEND_FILE_ENDING = ".blend"
	const MESH_FILE_ENDING = ".mesh"

	var valid_endings := [
		SCENE_FILE_ENDING,
		COMPRESSED_SCENE_FILE_ENDING,
		OBJ_FILE_ENDING,
		GLTF_FILE_ENDING,
		GLB_FILE_ENDING,
		FBX_FILE_ENDING,
		COLLADA_FILE_ENDING,
		BLEND_FILE_ENDING,
		RES_FILE_ENDING,
		TRES_FILE_ENDING,
		MESH_FILE_ENDING,
	]

	# Check File Ending, and if file exists and is of a supported type
	if valid_endings.any(func(e: String) -> bool: return p_file_path.ends_with(e)):
		if ResourceLoader.exists(p_file_path):
			return true
		printerr("AssetPlacerPlugin: %s not found. It might have been moved or deleted" % p_file_path)
	else:
		printerr("AssetPlacerPlugin: %s has an unsupported file ending. Are you sure it is a 3D file?" % p_file_path)
	return false


func _on_add_new_asset(p_asset_paths: Array[String]) -> void:
	var assets: Array[Asset3DData] = []
	for path in p_asset_paths:
		assets.append(Asset3DData.new(path, Asset3DData.PreviewPerspective.DEFAULT, -Vector3.ONE))
	_on_add_asset_data(assets)


func _on_add_asset_data(p_assets: Array[Asset3DData]) -> void:
	var valid_assets: Array[Asset3DData] = []
	for asset in p_assets:
		# if there is no library ("[Empty") create a new one
		if palette_state.current_library.is_empty() || !palette_state.library_data_dict.has(palette_state.current_library):
			_on_new_asset_library()

		assert(!palette_state.current_library.is_empty(), "_current_library not empty")
		if palette_state.current_library_data.has_asset(asset.path):
			continue

		if !_is_valid_file(asset.path):
			continue

		var res := ResourceLoader.load(asset.path)  # Expensive operation
		asset.is_mesh = res is Mesh
		if res is PackedScene or res is Mesh:
			valid_assets.push_back(asset)
		else:
			printerr("AssetPlacerPlugin: %s is not a scene or mesh." % [asset.path])

	if palette_state.current_library.is_empty():
		return

	if valid_assets.size():
		var updated_libdata := palette_state.current_library_data
		updated_libdata.asset_data.append_array(valid_assets)
		palette_state.mark_library_dirty(updated_libdata, true)

		palette_state.update_library_data(palette_state.current_library, updated_libdata)
		_update_save_disabled()
		generate_previews(palette_state.current_library_data, valid_assets, false)


func _on_remove_asset(p_paths: PackedStringArray) -> void:
	var updated_libdata := palette_state.current_library_data
	var updated := false
	for path in p_paths:
		if updated_libdata.has_asset(path):
			updated_libdata.remove_asset(path)
			palette_state.mark_library_dirty(updated_libdata, true)
			updated = true

	if updated:
		palette_state.update_library_data(palette_state.current_library, updated_libdata)


func cancel_queued_preview_generation() -> void:
	_preview_generator.cancel_queued_previews()


func generate_previews(library_data: AssetLibraryData, p_assets: Array[Asset3DData], p_force_reload: bool) -> void:
	var thumbnail_size: Vector2i = Vector2i.ONE * EditorInterface.get_editor_settings().get_setting("filesystem/file_dialog/thumbnail_size")

	for asset in p_assets:
		var success: bool = _preview_generator.generate_for_asset(
			asset, thumbnail_size, on_preview_loaded, p_force_reload, get_preview_perspective(asset), asset.custom_preview, asset.prev_custom_preview, weakref(library_data)
		)
		if not success:
			if ResourceLoader.exists(asset.path):
				EditorInterface.get_resource_previewer().queue_resource_preview(asset.path, self, "_on_resource_previewer_preview_loaded", weakref(library_data))
			else:
				palette_state.set_asset_broken(asset, true)


func _on_resource_previewer_preview_loaded(p_asset_path: String, p_preview: Texture2D, _p_thumbnail_preview: Texture2D, p_library: WeakRef) -> void:
	on_preview_loaded(p_library, p_asset_path, p_preview, Asset3DData.PreviewPerspective.DEFAULT, -Vector3.ONE)


func on_preview_loaded(p_library: WeakRef, p_asset_path: String, p_preview: Texture2D, p_generated_perspective: Asset3DData.PreviewPerspective, p_generated_custom_preview: Vector3) -> void:
	var asset: Asset3DData = palette_state.current_library_data.get_asset(p_asset_path)
	if asset:
		if (
			not p_library.get_ref()
			or palette_state.current_library_data.save_path != p_library.get_ref().save_path
			or not palette_state.current_library_data.has_asset(p_asset_path)
			or get_preview_perspective(asset) != p_generated_perspective
			or (asset.preview_perspective == Asset3DData.PreviewPerspective.CUSTOM and asset.custom_preview != p_generated_custom_preview)
		):
			# check if order is still valid. It is invalid if:
			# -- the library changed / was deleted in the meantime
			# -- the asset was removed from the library in the meantime
			# -- the assets perspective was changed again in the meantime
			return
		if p_preview:
			set_asset_preview(asset, p_preview, p_generated_perspective, p_generated_custom_preview)
		palette_state.set_asset_broken(asset, p_preview == null)


func set_asset_preview(p_asset: Asset3DData, p_preview: Texture2D, p_generated_perspective: Asset3DData.PreviewPerspective, p_generated_custom_preview: Vector3) -> void:
	p_asset.preview_texture = p_preview
	p_asset.generated_preview_perspective = p_generated_perspective
	p_asset.generated_custom_preview = p_generated_custom_preview
	palette_state.asset_updated.emit(p_asset, false)


func deselect_asset() -> void:
	palette_state.selected_asset = null


func is_asset_selected() -> bool:
	return palette_state.selected_asset != null


func try_select_previous_asset() -> void:
	palette_state.selected_asset = AssetPlacerState.instance.placement_state.last_selected_asset


func _get_available_library_name(p_desired_name: String) -> String:
	if p_desired_name == AssetPaletteView.EMPTY_TAB_TITLE:
		p_desired_name = "Empty"

	var lib_name := p_desired_name
	var i := 1
	while palette_state.library_data_dict.keys().any(func(x: String) -> bool: return x == lib_name):
		lib_name = "%s (%d)" % [p_desired_name, i]
		i += 1

	return lib_name


func _on_show_dynamic_preview(p_asset_path: String, p_button: AssetPlacerButton) -> void:
	var asset_idx := palette_state.current_library_data.asset_data.find_custom(func(a: Asset3DData) -> bool: return a.path == p_asset_path)
	if asset_idx == -1:
		printerr("AssetPlacerPlugin: Asset with path %s not found in current library" % p_asset_path)
		return
	var asset: Asset3DData = palette_state.current_library_data.asset_data[asset_idx]
	var asset_node: Node3D = AssetInstantiator.instantiate_asset(asset, palette_state.current_library_data)
	if not asset_node:
		return
	_dynamic_preview_controller.show_preview(p_button, asset_node, get_preview_perspective(asset), asset, true)


func _on_update_dynamic_preview(p_asset_path: String) -> void:
	if not palette_state.current_library:
		return
	var asset_idx := palette_state.current_library_data.asset_data.find_custom(func(a: Asset3DData) -> bool: return a.path == p_asset_path)
	if _dynamic_preview_controller.has_changed && asset_idx >= 0:
		_save_dynamic_preview(palette_state.current_library_data.asset_data[asset_idx])


func _on_default_library_previews(p_library: String) -> void:
	assert(palette_state.library_data_dict.has(p_library), "Data of library %s not found" % p_library)
	var lib: AssetLibraryData = palette_state.library_data_dict[p_library]
	for asset_3d_data in lib.asset_data:
		asset_3d_data.preview_perspective = Asset3DData.PreviewPerspective.DEFAULT
	_on_reload_library_previews(p_library)
	palette_state.mark_library_dirty(lib, true)


func _on_library_preview_perspective_changed(p_library: String, p_perspective: Asset3DData.PreviewPerspective) -> void:
	assert(palette_state.library_data_dict.has(p_library), "Data of library %s not found" % p_library)
	var lib: AssetLibraryData = palette_state.library_data_dict[p_library]
	lib.preview_perspective = p_perspective
	palette_state.mark_library_dirty(lib, true)

	generate_previews(palette_state.current_library_data, lib.asset_data, true)


func _on_asset_preview_perspective_changed(p_asset_path: String, p_perspective: Asset3DData.PreviewPerspective) -> void:
	assert(palette_state.current_library_data.has_asset(p_asset_path), "Asset %s is not part of current library" % p_asset_path)
	var asset: Array[Asset3DData] = palette_state.current_library_data.asset_data.filter(func(a: Asset3DData) -> bool: return a.path == p_asset_path)
	palette_state.mark_library_dirty(palette_state.current_library_data, true)
	for a in asset:  # should only be 1, usually
		a.preview_perspective = p_perspective  # change perspective
	generate_previews(palette_state.current_library_data, asset, true)


func _save_dynamic_preview(p_asset: Asset3DData) -> void:
	# store preview parameters in asset
	palette_state.mark_library_dirty(palette_state.current_library_data, true)
	p_asset.preview_perspective = Asset3DData.PreviewPerspective.CUSTOM
	p_asset.custom_preview = _dynamic_preview_controller.spherical_camera_coordinates

	# make a preview viewport reload this asset's preview with these parameters
	_reload_asset_preview(p_asset.path)
	p_asset.prev_custom_preview = _dynamic_preview_controller.spherical_camera_coordinates


func get_preview_perspective(p_asset: Asset3DData) -> Asset3DData.PreviewPerspective:
	var preview_perspective := p_asset.preview_perspective if p_asset.preview_perspective != Asset3DData.PreviewPerspective.DEFAULT else palette_state.current_library_data.preview_perspective

	return AssetPreviewGenerator.get_perspective(preview_perspective)


static func get_asset_name(p_path: String) -> String:
	var asset_name_with_ending := p_path.get_file()
	return asset_name_with_ending
