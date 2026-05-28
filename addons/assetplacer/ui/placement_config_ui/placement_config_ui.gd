# placement_config_ui.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const PlaneConfigView = preload("res://addons/assetplacer/ui/placement_config_ui/plane_config_view.gd")
const SurfaceConfigView = preload("res://addons/assetplacer/ui/placement_config_ui/surface_config_view.gd")
const Terrain3DConfigView = preload("res://addons/assetplacer/ui/placement_config_ui/terrain_3d_config_view.gd")
const PlacementConfigController = preload("res://addons/assetplacer/ui/placement_config_ui/placement_config_controller.gd")
const NodePathSelector = preload("res://addons/assetplacer/ui/components/node_path_selector/node_path_selector.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")
const RayMode = AssetPlacerState.PlacementConfigState.RayMode

signal mode_selected(mode: RayMode)
signal spawn_parent_selected(node: Node)

@export var spawn_parent_selection: NodePathSelector
@export var plane_config_view: PlaneConfigView
@export var surface_config_view: SurfaceConfigView
@export var terrain_3d_config_view: Terrain3DConfigView

@export var _ray_mode_option_button: OptionButton
@export var tab_container: TabContainer

var config_views: Dictionary[RayMode, Control] = {}


func initialize() -> void:
	config_views = {RayMode.PLANE: plane_config_view, RayMode.PHYSICS_SURFACE: null, RayMode.TERRAIN_3D: terrain_3d_config_view}

	_ray_mode_option_button.clear()
	var except := [RayMode.DUMMY]
	for i in PlacementConfigController.RAY_MODE_STRINGS:
		if not except.has(PlacementConfigController.RAY_MODE_STRINGS[i]):
			_ray_mode_option_button.add_item(i)

	_ray_mode_option_button.item_selected.connect(
		func(_idx: int) -> void:
			var mode_string := _ray_mode_option_button.get_item_text(_idx)
			var mode := PlacementConfigController.RAY_MODE_STRINGS[mode_string]
			mode_selected.emit(mode)
	)
	spawn_parent_selection.node_changed.connect(func() -> void: spawn_parent_selected.emit(spawn_parent_selection.node))

	plane_config_view.initialize()
	surface_config_view.initialize()
	terrain_3d_config_view.initialize()
	spawn_parent_selection.initialize_ui()


func register_nodes() -> void:
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_SPAWN_PARENT_SELECTOR, spawn_parent_selection)  # test automation access
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_RAY_MODE_OPTION_BUTTON, _ray_mode_option_button)  # test automation access
	plane_config_view.register_nodes()
	surface_config_view.register_nodes()
	terrain_3d_config_view.register_nodes()
	spawn_parent_selection.register_nodes(UIRegistry.PLACEMENTCONFIG_SPAWN_PARENT_SELECTOR)


func set_view_visible(mode: RayMode) -> void:
	var visible_view: Control = config_views[mode]
	tab_container.current_tab = tab_container.get_children().find(visible_view)
	_ray_mode_option_button.selected = get_placement_option_button_item_idx(mode)


func placement_option_button_has_item(mode: RayMode) -> bool:
	return get_placement_option_button_item_idx(mode) != -1


func get_placement_option_button_item_idx(mode: RayMode) -> int:
	for i in range(_ray_mode_option_button.item_count):
		if PlacementConfigController.get_ray_mode_string(mode) == _ray_mode_option_button.get_item_text(i):
			return i

	return -1
