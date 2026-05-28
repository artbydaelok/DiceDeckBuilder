# placement_controller.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/viewport_3d_controller.gd"

const AssetPaletteController = preload("res://addons/assetplacer/viewport_3d_controllers/asset_palette_controller.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetInstantiator = preload("res://addons/assetplacer/asset_palette/asset_instantiator.gd")
const Node3DList = preload("res://addons/assetplacer/data_formats/node_3d_list.gd")
const Shortcuts = preload("res://addons/assetplacer/shortcuts.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")

const SquareSnapping = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/square.gd")
const Transformer = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/transformer/transformer.gd")

# Ray strategies
const RayStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/strategy.gd")
const PhysicsSurfaceStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/physics_surface.gd")
const Terrain3DStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/terrain_3d.gd")
const PlaneStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/plane.gd")

# Placement strategies
const PlacementStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_strategy/strategy.gd")
const PlaceAndRotateStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_strategy/place_and_rotate.gd")
const PaintStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_strategy/paint.gd")

const ActionType = InputManager.ActionType
const RayInfo = RayStrategy.RayInfo
const RayMode = AssetPlacerState.PlacementConfigState.RayMode
const PlacementMode = AssetPlacerState.PlacementConfigState.PlacementMode
const ControlState = AssetPlacerState.PlacementState.ControlState

const SHORTCUT_SHIFT_ROTATION := "Shortcut_Shift_Rotation_Step"
const IGNORE_SELECTION_CHANGE_BEFORE_FRAME_THRESHOLD := 3

var control_state: ControlState:
	set(value):
		if value == placement_state.control_state:
			return
		Tips.clear_tt("placement")
		if value == ControlState.SHOWING_HOLOGRAM:
			_preview_ray_info_valid = false
			_placement_viewport = null

		elif value == ControlState.PLACING_ASSET:
			assert(placement_state.control_state == ControlState.SHOWING_HOLOGRAM)  # illegal to enter from any other state

		placement_state.control_state = value

		var grid_active := value in [ControlState.SHOWING_HOLOGRAM, ControlState.PLACING_ASSET]
		snapping_state.grid_users.update_usage("placement_controller", grid_active)

		snapping_state.toggled_lock.lock(value in [ControlState.PLACING_ASSET])  # snapping can't be toggled while placing, it's locked on during placement
		var toggle_active := value in [ControlState.SHOWING_HOLOGRAM, ControlState.PLACING_ASSET]
		snapping_state.toggle_users.update_usage("placement_controller", toggle_active)
	get:
		return placement_state.control_state

var placement_state: AssetPlacerState.PlacementState:
	get():
		return AssetPlacerState.instance.placement_state

var placement_config_state: AssetPlacerState.PlacementConfigState:
	get():
		return AssetPlacerState.instance.placement_config_state

var palette_state: AssetPlacerState.PaletteState:
	get():
		return AssetPlacerState.instance.palette_state

var snapping_state: AssetPlacerState.SnappingState:
	get():
		return AssetPlacerState.instance.snapping_state

var _ray_strategies: Dictionary[RayMode, RayStrategy] = {}
var _is_mode_hologram_transformed: Dictionary[PlacementMode, bool] = {}
var _placement_strategies: Dictionary[PlacementMode, PlacementStrategy] = {}

var _current_placement_mode: PlacementMode

var _current_transformer: Transformer

var _preview_transform: Transform3D = Transform3D.IDENTITY
var _preview_ray_info_valid: bool = false
var _preview_ray_info: RayInfo

var _hologram_before_transform: Transform3D  # store transform before TransformingHologram (gizmos) for resetting it, in case the user cancels
var _placement_viewport: SubViewport  # the viewport that the user is currently working in

#var randomization := AssetPlacerState.instance.randomization_state
var _undo: EditorUndoRedoManager


func initialize(undo: EditorUndoRedoManager) -> void:
	_undo = undo

	_ray_strategies = {
		RayMode.PHYSICS_SURFACE: PhysicsSurfaceStrategy.new(),
		RayMode.TERRAIN_3D: Terrain3DStrategy.new(),
		RayMode.PLANE: PlaneStrategy.new(),
	}
	_placement_strategies = {
		PlacementMode.PLACE_ONLY: PlacementStrategy.new(),
		PlacementMode.PLACE_AND_ROTATE: PlaceAndRotateStrategy.new(),
		PlacementMode.PLACE_AND_PAINT: PaintStrategy.new(),
	}
	_is_mode_hologram_transformed = {
		PlacementMode.PLACE_ONLY: true,
		PlacementMode.PLACE_AND_ROTATE: true,
		PlacementMode.PLACE_AND_PAINT: true,
		# PlacementMode.
	}

	palette_state.selected_asset_changed.connect(
		func(a: Asset3DData) -> void:
			_clear_hologram()  # free old hologram
			if a == null:
				control_state = ControlState.IDLE
			else:
				# TODO[FoliagePainter]: could also be a strategy (foliage painting would want a different hologram for example)
				placement_state.hologram = AssetInstantiator.instantiate_asset(a, palette_state.current_library_data)
				if placement_state.hologram == null:  # instantiation failure -> deselect asset
					palette_state.selected_asset = null
					control_state = ControlState.IDLE
				else:
					control_state = ControlState.SHOWING_HOLOGRAM
	)
	palette_state.asset_updated.connect(
		func(asset: Asset3DData, transform_updated: bool) -> void:
			if asset != palette_state.selected_asset or placement_state.hologram == null or asset == null or not transform_updated:
				return
			if transform_updated:
				if placement_state.hologram.is_inside_tree():
					placement_state.hologram.global_transform.basis = asset.current_transform.basis
				else:
					placement_state.hologram.transform.basis = asset.current_transform.basis
	)

	placement_config_state.ray_mode_changed.connect(
		func(_mode: int) -> void:
			placement_state.last_valid_ray_info = null
			snapping_state.grid_ray_info = null
			placement_state.current_placement_plane = _ray_strategies[placement_config_state.ray_mode].get_placement_plane(null)  # for plane placement, this gets the default plane
	)

	AssetPlacerState.instance.scene_changed.connect(
		func() -> void:
			placement_state.last_valid_ray_info = null
			snapping_state.grid_ray_info = null
			placement_state.current_placement_plane = _ray_strategies[placement_config_state.ray_mode].get_placement_plane(null)  # for plane placement, this gets the default plane
	)

	Settings.register_setting(Settings.DEFAULT_CATEGORY, SHORTCUT_SHIFT_ROTATION, 45.0, TYPE_FLOAT, PROPERTY_HINT_RANGE, "-180,180,degrees")
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.SELECT_PREVIOUS_ASSET, [KEY_SPACE])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.ROTATE_X, [KEY_A])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.ROTATE_Y, [KEY_S])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.ROTATE_Z, [KEY_D])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.SHIFT_ROTATE_X, true, false, [KEY_A])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.SHIFT_ROTATE_Y, true, false, [KEY_S])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.SHIFT_ROTATE_Z, true, false, [KEY_D])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.FLIP_X, [KEY_F])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.FLIP_Y, [KEY_G])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.FLIP_Z, [KEY_H])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.RESET_TRANSFORM, true, false, [KEY_E])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.TRANSFORM_ASSET, [KEY_E, KEY_R])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.DOUBLE_SNAP_STEP, false, true, [KEY_UP])
	Shortcuts.instance.add_keys_3d_gui_shortcut(Shortcuts.HALVE_SNAP_STEP, false, true, [KEY_DOWN])

	palette_state.selected_asset_changed.connect(_on_selected_asset_changed)
	EditorInterface.get_selection().selection_changed.connect(_selection_changed)


func cleanup() -> void:
	_clear_hologram()


func process() -> void:
	snapping_state.grid_ray_info = _ray_strategies[placement_config_state.ray_mode].get_grid_placement()
	match control_state:
		ControlState.SHOWING_HOLOGRAM:
			_current_placement_mode = get_mode_for_placement()
			_process_hologram()
		ControlState.PLACING_ASSET:
			_process_placing_asset()


func forward_3d_viewport_input(_p_viewport: SubViewport, p_event: InputEvent, p_action: InputManager.ActionType) -> void:
	if Shortcuts.instance.is_shortcut(Shortcuts.SELECT_PREVIOUS_ASSET, p_event):
		try_select_previous_asset()
		accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.ROTATE_X, p_event):
		if try_rotate_selected_asset(Vector3.RIGHT, deg_to_rad(-90)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.ROTATE_Y, p_event):
		if try_rotate_selected_asset(Vector3.UP, deg_to_rad(-90)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.ROTATE_Z, p_event):
		if try_rotate_selected_asset(Vector3.BACK, deg_to_rad(-90)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.SHIFT_ROTATE_X, p_event):
		var r: float = Settings.get_setting(Settings.DEFAULT_CATEGORY, SHORTCUT_SHIFT_ROTATION)
		if try_rotate_selected_asset(Vector3.RIGHT, deg_to_rad(r)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.SHIFT_ROTATE_Y, p_event):
		var r: float = Settings.get_setting(Settings.DEFAULT_CATEGORY, SHORTCUT_SHIFT_ROTATION)
		if try_rotate_selected_asset(Vector3.UP, deg_to_rad(r)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.SHIFT_ROTATE_Z, p_event):
		var r: float = Settings.get_setting(Settings.DEFAULT_CATEGORY, SHORTCUT_SHIFT_ROTATION)
		if try_rotate_selected_asset(Vector3.BACK, deg_to_rad(r)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.FLIP_X, p_event):
		if try_scale_selected_asset(Vector3(-1.0, 1.0, 1.0)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.FLIP_Y, p_event):
		if try_scale_selected_asset(Vector3(1.0, -1.0, 1.0)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.FLIP_Z, p_event):
		if try_scale_selected_asset(Vector3(1.0, 1.0, -1.0)):
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.RESET_TRANSFORM, p_event):
		_reset_selected_asset_transform()
		accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.TRANSFORM_ASSET, p_event):
		if control_state == ControlState.SHOWING_HOLOGRAM and placement_state.hologram and placement_state.hologram.is_inside_tree():
			control_state = ControlState.TRANSFORMING_HOLOGRAM
			Tips.set_tt("placement/hologram/transform", Lang.ttr("transform_confirm") % [OS.get_keycode_string(InputManager.CONFIRM_KEYS[0])], Tips.TYPE.HINT_IMPORTANT)
			_hologram_before_transform = placement_state.hologram.global_transform if placement_state.hologram.is_inside_tree() else placement_state.hologram.transform
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(placement_state.hologram)
			if p_event.keycode == KEY_E:
				AssetPlacerState.instance.editor_state.switch_to_rotate_tool()
			elif p_event.keycode == KEY_R:
				AssetPlacerState.instance.editor_state.switch_to_scale_tool()
			else:
				AssetPlacerState.instance.editor_state.switch_to_rotate_tool()  # default to rotate tool if different key assigned
			accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.DOUBLE_SNAP_STEP, p_event):
		_multiply_snap_steps(2.0)
		accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.HALVE_SNAP_STEP, p_event):
		_multiply_snap_steps(0.5)
		accept_input()

	match p_action:
		ActionType.CANCEL:
			if control_state == ControlState.SHOWING_HOLOGRAM:
				_clear_hologram()
				palette_state.selected_asset = null
				control_state = ControlState.IDLE
				accept_input()
			elif control_state == ControlState.TRANSFORMING_HOLOGRAM:
				_cancel_transforming_hologram()
				AssetPlacerState.instance.editor_state.switch_to_select_tool()
				control_state = ControlState.SHOWING_HOLOGRAM
				accept_input()
		ActionType.CONFIRM:
			if control_state == ControlState.TRANSFORMING_HOLOGRAM:
				AssetPlacerState.instance.editor_state.switch_to_select_tool()
				control_state = ControlState.SHOWING_HOLOGRAM
				_apply_hologram_transform_to_selected_asset()
				accept_input()
		ActionType.PLACEMENT, ActionType.ALT_PLACEMENT:
			if control_state == ControlState.SHOWING_HOLOGRAM:
				if _try_place_asset():
					accept_input()


func get_mode_for_placement() -> PlacementMode:
	return PlacementMode.PLACE_AND_PAINT if snapping_state.is_active else PlacementMode.PLACE_AND_ROTATE  # TODO[PlacementModeButton]: make this a ui setting


func _cancel_transforming_hologram() -> void:
	if placement_state.hologram:
		if placement_state.hologram.is_inside_tree():
			placement_state.hologram.global_transform = _hologram_before_transform
		else:
			placement_state.hologram.transform = _hologram_before_transform


func _on_selected_asset_changed(_asset: Asset3DData) -> void:
	if _asset:
		EditorInterface.get_selection().clear()


func _selection_changed() -> void:
	var selection := EditorInterface.get_selection().get_selected_nodes()
	if selection.size() == 0:  # ok
		return
	var hologram_selected := false
	var hologram_children_selected := false
	if placement_state.hologram:
		hologram_selected = selection.any(func(n: Node) -> bool: return n == placement_state.hologram)
		hologram_children_selected = selection.any(func(n: Node) -> bool: return placement_state.hologram.is_ancestor_of(n))

	if hologram_children_selected:  # illegal
		EditorInterface.get_selection().call_deferred("clear")
		return

	if hologram_selected and not control_state == ControlState.TRANSFORMING_HOLOGRAM:  # illegal
		EditorInterface.get_selection().call_deferred("clear")

	if control_state != ControlState.IDLE and (selection.size() > 1 or not hologram_selected):
		# cancel what you are doing
		if control_state == ControlState.TRANSFORMING_HOLOGRAM:
			_cancel_transforming_hologram()
		elif control_state == ControlState.SHOWING_HOLOGRAM:
			var frames_since_asset_selection := Engine.get_process_frames() - palette_state.selection_framestamp
			# selecting / instantiating certain nodes (OccluderInstance3D) can cause root selection
			# i.e. skip deselection shortly after selecting an asset

			if selection.size() >= 1:
				if frames_since_asset_selection < IGNORE_SELECTION_CHANGE_BEFORE_FRAME_THRESHOLD:
					EditorInterface.get_selection().call_deferred("clear")
					return
		elif control_state == ControlState.PLACING_ASSET:
			var allowed_selection := []
			if placement_state.hologram:
				allowed_selection.append(placement_state.hologram)
			if placement_state.last_placed_asset and placement_state.last_placed_asset.get_ref():
				allowed_selection.append(placement_state.last_placed_asset.get_ref())
			if selection.size() >= 1:
				var other_node_selected := allowed_selection.size() == 0 or selection.any(func(n: Node) -> bool: return not n in allowed_selection)
				var frames_since_asset_placement := Engine.get_process_frames() - placement_state.last_placement_framestamp
				if other_node_selected and frames_since_asset_placement < IGNORE_SELECTION_CHANGE_BEFORE_FRAME_THRESHOLD:
					EditorInterface.get_selection().call_deferred("clear")
					return
				_finish_placing_asset()
		if placement_state.hologram and selection.has(placement_state.hologram):
			EditorInterface.get_selection().remove_node(placement_state.hologram)
		_clear_hologram()
		palette_state.selected_asset = null
		control_state = ControlState.IDLE


func _process_hologram() -> void:
	if placement_state.hologram == null:
		return

	var vp: SubViewport
	if Editor3DViewportUtils.is_mouse_over_valid_focused_3d_viewport():
		vp = Editor3DViewportUtils.get_3d_viewport_under_mouse()

	var ray_info := RayInfo.invalid()
	var placing_nodes: Array[Node3D] = [placement_state.hologram]

	_preview_ray_info_valid = false
	var hologram_parent: Node = placement_state.hologram.get_parent()
	if not vp:
		Tips.clear_tt("placement/hologram")
	else:
		if placement_config_state.spawn_parent_node == null:
			Tips.set_tt("placement/hologram", Lang.ttr("no_spawn_parent"), Tips.TYPE.ERROR)
		else:
			if not InputManager.instance.rmb_pressed and _ray_strategies.has(placement_config_state.ray_mode):
				if EditorInterface.get_selection().get_selected_nodes().size() >= 1:
					EditorInterface.get_selection().call_deferred("clear")

				ray_info = _ray_strategies[placement_config_state.ray_mode].get_placement(vp.get_camera_3d(), InputManager.instance.viewport_mouse_position, placing_nodes)
				_preview_ray_info_valid = ray_info.is_valid()
				if _preview_ray_info_valid:
					Tips.set_tt("placement/hologram[coords,shorctus]", "")
					var place_and_select_modifier := "Shift" if Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.USE_SHIFT_SETTING) else "Alt"
					var place_and_select_tt := Lang.ttr("place_and_select") % place_and_select_modifier
					var transform_tt := Lang.ttr("hologram_transform") % Shortcuts.get_shortcut_string(Shortcuts.TRANSFORM_ASSET)
					var reset_transform_tt := Lang.ttr("hologram_reset_transform") % Shortcuts.get_shortcut_string(Shortcuts.RESET_TRANSFORM)
					var tts := [Lang.ttr("click_to_place"), place_and_select_tt, transform_tt]
					if palette_state.selected_asset.current_transform != palette_state.selected_asset.default_transform:
						tts.append(reset_transform_tt)
					Tips.set_tt("placement/hologram/shortcuts", "\n".join(tts), Tips.TYPE.HINT)
					placement_state.last_valid_ray_info = ray_info
					placement_state.current_placement_plane = _ray_strategies[placement_config_state.ray_mode].get_placement_plane(ray_info)
					_preview_ray_info = ray_info
					_placement_viewport = vp
					if hologram_parent == null:
						_add_hologram_to_tree()

					_current_transformer = Transformer.new(palette_state.selected_asset, snapping_state.is_active, placement_config_state.surface_align_enabled, false)
					_preview_transform = _current_transformer.get_transform(ray_info)

					Tips.set_tt("placement/hologram/coords", str(_preview_transform.origin), Tips.TYPE.VALUE, 2)
					if _is_mode_hologram_transformed[_current_placement_mode]:
						placement_state.hologram.global_transform = _preview_transform
					else:
						placement_state.hologram.global_position = ray_info.pos
				else:
					if ray_info.validity == RayInfo.VALIDITY.NO_INTERSECTION:
						Tips.clear_tt("placement/hologram/coords")
					elif ray_info.validity_message:
						var is_error: bool = ray_info.validity in [RayInfo.VALIDITY.INVALID, RayInfo.VALIDITY.TERRAIN_ERROR]
						Tips.set_tt("placement/hologram", Lang.ttr(ray_info.validity_message), Tips.TYPE.ERROR if is_error else Tips.TYPE.HINT)

	if not _preview_ray_info_valid:
		var local_transform := placement_state.hologram.transform
		var parent: Node = placement_state.hologram.get_parent()
		if parent:
			parent.remove_child(placement_state.hologram)
		placement_state.hologram.transform = local_transform


func _build_transformer(asset_3d: Asset3DData, surface_align_enabled: bool) -> Transformer:
	return Transformer.new(asset_3d, surface_align_enabled, false)


func _try_place_asset() -> bool:
	if not _preview_ray_info_valid or not Editor3DViewportUtils.is_mouse_over_valid_focused_3d_viewport() or not placement_config_state.spawn_parent_node:
		return false

	var prototype := _create_prototype()
	if prototype == null:
		return false

	control_state = ControlState.PLACING_ASSET
	_remove_hologram_from_tree()
	var success := _placement_strategies[_current_placement_mode].begin_drag(
		_placement_viewport,
		palette_state.selected_asset,
		prototype,
		placement_config_state.spawn_parent_node,
		_ray_strategies[placement_config_state.ray_mode],
		_preview_ray_info,
		_current_transformer,
		_preview_transform,
		"placement/place"
	)
	if not success:
		prototype.queue_free()
		control_state = ControlState.SHOWING_HOLOGRAM
		return false
	return true


func _process_placing_asset() -> void:
	if _placement_viewport == null:
		return
	if InputManager.instance.lmb_pressed:
		# drag
		_placement_strategies[_current_placement_mode].drag(_placement_viewport, InputManager.instance.viewport_mouse_position, "placement/place")
	else:
		_finish_placing_asset()


func _finish_placing_asset() -> void:
	var placed_assets: Node3DList = _placement_strategies[_current_placement_mode].end_drag()
	var asset_name := AssetPaletteController.get_asset_name(palette_state.selected_asset.path)
	var count := placed_assets.size()
	for asset in placed_assets.get_nodes():
		asset.get_parent().remove_child(asset)  # will be done in undo_redo system
	if count > 0:
		var action_name := "Place %s %s assets" % [count, asset_name] if count > 1 else "Place %s asset" % asset_name
		_undo.create_action(action_name, UndoRedo.MERGE_DISABLE, placement_config_state.spawn_parent_node)
		_undo.add_do_method(self, "_place_assets_action", placed_assets, placement_config_state.spawn_parent_node, asset_name)
		_undo.add_undo_method(self, "_undo_place_assets", placed_assets, placement_config_state.spawn_parent_node)
		_undo.add_do_reference(placed_assets)
		_undo.commit_action()

		var alt_placement := InputManager.instance.is_alt_placement_pressed()
		if alt_placement:
			EditorInterface.call_deferred("edit_node", placed_assets.get_nodes()[0])
			var editor_selection := EditorInterface.get_selection()
			editor_selection.clear()
			for asset in placed_assets.get_nodes():
				editor_selection.add_node(asset)
			palette_state.selected_asset = null
			control_state = ControlState.IDLE
		else:
			control_state = ControlState.SHOWING_HOLOGRAM
	else:
		control_state = ControlState.SHOWING_HOLOGRAM


func _create_prototype() -> Node3D:
	var instance := AssetInstantiator.instantiate_asset(palette_state.selected_asset, palette_state.current_library_data)
	if instance == null:
		return null
	instance.transform = palette_state.selected_asset.current_transform
	instance.name = AssetPaletteController.get_asset_name(palette_state.selected_asset.path)
	return instance


func _remove_hologram_from_tree() -> void:
	if placement_state.hologram:
		var parent := placement_state.hologram.get_parent()
		if parent:
			parent.remove_child(placement_state.hologram)


#########################
## Shortcut methods


func _multiply_snap_steps(factor: float) -> void:
	snapping_state.shift_step *= factor
	snapping_state.step *= factor


func try_rotate_selected_asset(axis: Vector3, angle: float) -> bool:
	if (control_state != ControlState.SHOWING_HOLOGRAM and control_state != ControlState.TRANSFORMING_HOLOGRAM) or InputManager.instance.rmb_pressed or palette_state.selected_asset == null:
		return false
	var t := palette_state.selected_asset.current_transform
	_update_selected_asset_transform(Transform3D(t.basis.rotated(axis, angle), t.origin))
	return true


func try_scale_selected_asset(factor: Vector3) -> bool:
	if (control_state != ControlState.SHOWING_HOLOGRAM and control_state != ControlState.TRANSFORMING_HOLOGRAM) or InputManager.instance.rmb_pressed or palette_state.selected_asset == null:
		return false
	var t := palette_state.selected_asset.current_transform
	_update_selected_asset_transform(Transform3D(t.basis.scaled(factor), t.origin))
	return true


func try_select_previous_asset() -> bool:
	if palette_state.current_library_data == null or palette_state.last_selected_asset_path == "":
		return false
	if palette_state.current_library_data.has_asset(palette_state.last_selected_asset_path):
		palette_state.selected_asset = palette_state.current_library_data.get_asset(palette_state.last_selected_asset_path)
		return true
	return false


func _reset_selected_asset_transform() -> void:
	if palette_state.selected_asset == null or palette_state.current_library_data == null:
		return
	palette_state.reset_asset_transform(palette_state.current_library_data, palette_state.selected_asset)


########################
## Hologram logic and helpers
func _add_hologram_to_tree() -> void:
	var transform_before_enter_tree := placement_state.hologram.transform
	placement_config_state.spawn_parent_node.add_child(placement_state.hologram)
	placement_state.hologram.global_transform = transform_before_enter_tree

	# if hologram has been transformed before, apply that transform
	if palette_state.selected_asset.current_transform_valid:
		var holo_transform := placement_state.hologram.global_transform
		holo_transform.basis = palette_state.selected_asset.current_transform.basis
		placement_state.hologram.global_transform = holo_transform
	else:
		# initialize current transform. probably not needed, though.
		_apply_hologram_transform_to_selected_asset()


func _update_selected_asset_transform(transform: Transform3D) -> void:
	if palette_state.selected_asset == null or palette_state.current_library_data == null:
		return
	palette_state.set_asset_transform(palette_state.current_library_data, palette_state.selected_asset, transform)


func _apply_hologram_transform_to_selected_asset() -> void:
	if palette_state.selected_asset == null or placement_state.hologram == null or palette_state.current_library_data == null:
		return
	var transform := palette_state.selected_asset.current_transform
	transform.basis = placement_state.hologram.global_transform.basis
	palette_state.set_asset_transform(palette_state.current_library_data, palette_state.selected_asset, transform)


func _clear_hologram() -> void:
	if placement_state.hologram:
		placement_state.hologram.queue_free()
	placement_state.hologram = null


###############################
## Undo/Redo Actions
func _place_assets_action(p_assets: Node3DList, p_parent: Node, p_name: String) -> void:
	for asset: Node3D in p_assets.node_transforms.keys():
		p_parent.add_child(asset)
		asset.name = p_name
		asset.transform = p_assets.node_transforms[asset]
		asset.owner = p_parent.get_tree().edited_scene_root


func _undo_place_assets(p_assets: Node3DList, p_parent: Node) -> void:
	for asset: Node3D in p_assets.node_transforms.keys():
		p_parent.remove_child(asset)
