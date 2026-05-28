# assetplacer_state.gd
# © Copyright CookieBadger 2026
@tool

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetLibraryData = preload("res://addons/assetplacer/asset_palette/asset_library_data.gd")
const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")
const UsersList = preload("res://addons/assetplacer/utils/users_list.gd")
const LockableProperty = preload("res://addons/assetplacer/utils/lockable_property.gd")

# main plugin signals
@warning_ignore_start("unused_signal")
signal ui_theme_changed(t: Theme)
signal scene_changed
@warning_ignore_restore("unused_signal")

static var instance: AssetPlacerState:
	get:
		if !_instance:
			initialize()

		return _instance

static var _instance: AssetPlacerState

var palette_state := PaletteState.new()

var snapping_state := SnappingState.new()

var placement_config_state := PlacementConfigState.new()

var placement_state := PlacementState.new()

var editor_state := EditorState.new()

var is_external_ui := false

var mouse_over_external_ui := false

var viewport_input_handled := false


static func initialize() -> void:
	_instance = AssetPlacerState.new()


class EditorState:
	signal toolbar_button_container_invalid

	var toolbar_button_container: Control:
		get:
			if not toolbar_button_container or not toolbar_button_container.is_inside_tree():
				toolbar_button_container_invalid.emit()
			return toolbar_button_container

	func switch_to_select_tool() -> void:
		switch_to_toolbar_button(0)

	func switch_to_translate_tool() -> void:
		switch_to_toolbar_button(1)

	func switch_to_rotate_tool() -> void:
		switch_to_toolbar_button(2)

	func switch_to_scale_tool() -> void:
		switch_to_toolbar_button(3)

	func switch_to_toolbar_button(idx: int) -> void:
		var children := []
		for c in toolbar_button_container.get_children():
			if c is Button:
				children.append(c)
		if idx >= 0 and idx < children.size():
			children[idx].emit_signal("pressed")
		else:
			push_error("Toolbar button index out of range: " + str(idx))


class PlacementState:
	signal last_valid_ray_info_changed(info: RayInfo)
	signal current_placement_plane_changed(info: RayInfo)
	signal hologram_changed(hologram: Node3D)

	enum ControlState {
		IDLE,  # no asset selected
		SHOWING_HOLOGRAM,  # asset selected
		TRANSFORMING_HOLOGRAM,  # transform tools active for selected asset
		PLACING_ASSET,  # click pressed to place asset, any given dragging controls (rotation, painting) are active
	}
	var control_state: ControlState = ControlState.IDLE
	var configuring_plane_active := false
	var last_placement_framestamp: int = 0
	var last_placed_asset: WeakRef = null

	var hologram: Node3D:
		set(value):
			if value != hologram:
				hologram = value
				hologram_changed.emit(value)

	# intersection info about the last point that was calculated for the user (where the hologram was last)
	var last_valid_ray_info: RayInfo:
		set(value):
			if value != last_valid_ray_info:
				last_valid_ray_info = value
				last_valid_ray_info_changed.emit(value)

	# info about the plane that the user is currently placing on (either the configured plane in plane mode, or the last surface that the user hovered over)
	var current_placement_plane: RayInfo:
		set(value):
			if value != current_placement_plane:
				current_placement_plane = value
				current_placement_plane_changed.emit(value)

	func notify_placement(asset: Node3D) -> void:
		last_placement_framestamp = Engine.get_process_frames()
		last_placed_asset = weakref(asset)


class PaletteState:
	const OPENED_LIBRARIES_SAVE_KEY: String = "opened_libraries"
	const LAST_SELECTED_SAVE_KEY: String = "selected_library"

	signal selected_asset_changed(selected: Asset3DData)
	signal libraries_changed
	signal library_names_changed(prev_titles: Array[String])
	signal library_data_changed(library_title: String, library_data: AssetLibraryData)
	signal current_library_state_changed
	signal save_disabled_changed(disabled: bool)
	signal current_library_switched
	signal asset_updated(data: Asset3DData, affect_transform: bool)

	@warning_ignore("unused_signal")
	signal broken_asset_instantiated(asset: Asset3DData)  # can be emitted from outside

	var library_data_dict: Dictionary[String, AssetLibraryData]
	var library_titles_sorted: Array[String]
	var last_selected_asset_path: String
	var selection_framestamp: int

	var selected_asset: Asset3DData:
		set(value):
			if value != selected_asset:
				selected_asset = value
				selection_framestamp = Engine.get_process_frames()
				selected_asset_changed.emit(value)
			if value:
				last_selected_asset_path = value.path

	var current_library: String = ""

	var current_library_data: AssetLibraryData:
		get:
			if not library_data_dict.has(current_library):
				return AssetLibraryData.new()
			return library_data_dict[current_library]

	var save_disabled := false:
		set(value):
			if value != save_disabled:
				save_disabled = value
				save_disabled_changed.emit(value)

	func switch_library(p_library: String) -> void:
		if p_library != current_library:
			selected_asset = null
			current_library = p_library
			current_library_switched.emit()

	func add_library(p_title: String, p_data: AssetLibraryData) -> void:
		library_data_dict[p_title] = p_data
		library_titles_sorted.push_back(p_title)
		libraries_changed.emit()

	func remove_library(p_title: String) -> void:
		library_data_dict.erase(p_title)
		var idx := library_titles_sorted.find(p_title)
		assert(idx >= 0)
		library_titles_sorted.erase(p_title)
		libraries_changed.emit()
		if current_library == p_title:
			switch_library("" if library_titles_sorted.size() == 0 else library_titles_sorted[max(idx - 1, 0)])

	func update_library_data(p_title: String, p_library_data: AssetLibraryData) -> void:
		assert(library_data_dict.has(p_title) && library_titles_sorted.has(p_title))
		library_data_dict[p_title] = p_library_data
		library_data_changed.emit(p_title, p_library_data)
		if current_library == p_title:
			current_library_state_changed.emit()

	func mark_library_dirty(p_library: AssetLibraryData, p_dirty: bool) -> void:
		if library_data_dict.values().has(p_library):
			if p_dirty != p_library.dirty:
				p_library.dirty = p_dirty
				current_library_state_changed.emit()

	func set_asset_broken(p_asset: Asset3DData, p_is_broken: bool) -> void:
		if p_asset.is_broken != p_is_broken:
			p_asset.is_broken = p_is_broken
			asset_updated.emit(p_asset, false)

	func reset_asset_transform(p_library: AssetLibraryData, p_asset: Asset3DData) -> void:
		set_asset_transform(p_library, p_asset, p_asset.default_transform)

	func set_asset_transform(p_library: AssetLibraryData, p_asset: Asset3DData, p_transform: Transform3D) -> void:
		if p_asset.current_transform != p_transform:
			p_asset.current_transform = p_transform
			p_asset.current_transform_valid = true
			mark_library_dirty(p_library, true)
			asset_updated.emit(p_asset, true)

	func rename_library(p_old_title: String, p_new_title: String) -> void:
		if p_old_title == p_new_title:
			return
		var prev_titles := library_titles_sorted.duplicate()
		var data := library_data_dict[p_old_title]
		library_data_dict.erase(p_old_title)
		library_data_dict[p_new_title] = data
		var idx := library_titles_sorted.find(p_old_title)
		assert(idx >= 0)
		library_titles_sorted[idx] = p_new_title
		if current_library == p_old_title:
			current_library = p_new_title
		library_names_changed.emit(prev_titles)


class PlacementConfigState:
	const SPAWN_PARENT_SAVE_KEY := "spawn_parent_path"
	const RAY_MODE_SAVE_KEY := "ray_mode"
	const PLACEMENT_PLANE_SAVE_KEY := "placement_plane"
	const PLANE_POSITIONS_SAVE_KEY := "plane_positions"
	const SURFACE_ALIGN_ENABLED_SAVE_KEY := "surface_align_enabled"
	const SURFACE_ALIGNMENT_AXIS_SAVE_KEY := "surface_align_axis"
	const TERRAIN_3D_NODE_SAVE_KEY := "terrain3d_path"

	signal spawn_parent_node_changed(node: Node)
	signal ray_mode_changed(mode: RayMode)
	signal terrain_3d_node_changed(terrain3d: Node)
	signal surface_align_axis_changed(axis: int)
	signal surface_align_enabled_changed(enabled: bool)
	signal surface_normal_offset_changed(offset: float)
	signal plane_changed(plane: PlacementPlane)
	signal plane_positions_changed(pos: Array[float])

	enum RayMode { PLANE, PHYSICS_SURFACE, TERRAIN_3D, DUMMY }
	enum PlacementMode { PLACE_ONLY, PLACE_AND_ROTATE, PLACE_AND_PAINT }  # , PlaceAndDrawLine, PlaceAndDrawRect }
	enum PlacementPlane { YZ, XZ, XY }

	var spawn_parent_node: Node:
		set(value):
			if value != spawn_parent_node:
				spawn_parent_node = value
				spawn_parent_node_changed.emit(value)

	var ray_mode: RayMode:
		set(value):
			if value != ray_mode:
				ray_mode = value
				ray_mode_changed.emit(value)

	var plane: PlacementPlane:
		set(value):
			if value != plane:
				plane = value
				plane_changed.emit(value)

	var plane_positions: Array[float] = [0.0, 0.0, 0.0]:
		set(value):
			if value != plane_positions:
				plane_positions = value
				plane_positions_changed.emit(value)

	var plane_position: float:
		get:
			return plane_positions[int(plane)]
		set(value):
			if value != plane_positions[int(plane)]:
				plane_positions[int(plane)] = value
				plane_positions_changed.emit(plane_positions)

	var surface_align_enabled: bool:
		set(value):
			if value != surface_align_enabled:
				surface_align_enabled = value
				surface_align_enabled_changed.emit(value)

	var surface_align_axis: int:
		set(value):
			if value != surface_align_axis:
				surface_align_axis = value
				surface_align_axis_changed.emit(value)

	var surface_normal_offset: float:
		set(value):
			if value != surface_normal_offset:
				surface_normal_offset = value
				surface_normal_offset_changed.emit(value)

	var terrain_3d_node: Node:
		set(value):
			if value != terrain_3d_node:
				terrain_3d_node = value
				terrain_3d_node_changed.emit(value)


class SnappingState:
	const ENABLED_SAVE_KEY := "snap_enabled"
	const SNAP_STEP_SAVE_KEY := "snap_step"
	const SNAP_STEP_SHIFT_SAVE_KEY := "snap_step_shift"
	const GRID_OFFSET_SAVE_KEY := "snap_offset"

	signal enabled_changed(active: bool)
	signal active_changed(active: bool)
	signal step_changed(step: float)
	signal shift_step_changed(shift_step: float)
	signal offset_changed(offset: Vector2)
	signal current_step_changed(current_step: float)
	signal grid_ray_info_changed(info: RayInfo)

	# toggle logic is a bit complicated
	# if toggle_active is true, the snapping grid will show and hide depending on the toggle state (no asset selected = ctrl has no effect)
	# if toggled_lock is locked, the toggled state will remain whatever it was set to, only updating again once it's unlocked. (placing asset: toggle state will be respected, but can't be changed)

	var grid_users := UsersList.new()
	var toggle_users := UsersList.new()
	var toggled_lock := LockableProperty.new(false)

	var grid_input_active: bool:
		get:
			return grid_users.has_users()

	var toggle_active: bool:
		get:
			return toggle_users.has_users()

	var enabled: bool:
		set(value):
			if value != enabled:
				enabled = value
				active_changed.emit(is_active)
				enabled_changed.emit(value)

	var toggled: bool:
		set(value):
			var prev: bool = toggled_lock.get_state()
			toggled_lock.set_state(value)
			if toggle_active and prev != value:
				active_changed.emit(is_active)
		get():
			return toggled_lock.get_state()

	var is_active: bool:
		get:
			if toggle_active:
				return enabled != toggled_lock.get_state()  # XOR, snapping is active iff one is true
			return enabled

	var step: float:
		set(value):
			if value != step:
				step = value
				step_changed.emit(value)

	var shift_step: float:
		set(value):
			if value != shift_step:
				shift_step = value
				shift_step_changed.emit(value)

	var current_step: float:
		set(value):
			if value != current_step:
				current_step = value
				current_step_changed.emit(value)

	var offset: Vector2:
		set(value):
			if value != offset:
				offset = value
				offset_changed.emit(value)

	var grid_ray_info: RayInfo:  # difference to current_placement_plane: also stores position (potentially relative to camera)
		set(value):
			var changed := true
			if value and grid_ray_info:
				changed = value.pos != grid_ray_info.pos or value.normal != grid_ray_info.normal or value.validity != grid_ray_info.validity
			if value != grid_ray_info and changed:
				grid_ray_info = value
				grid_ray_info_changed.emit(value)
