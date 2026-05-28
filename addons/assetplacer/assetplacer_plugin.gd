# assetplacer_plugin.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/utils/contextless_plugin.gd"

##################
## imports

# singletons
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")
const Shortcuts = preload("res://addons/assetplacer/shortcuts.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const InputManager = preload("res://addons/assetplacer/input_manager.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

# Controllers
const Viewport3DController = preload("res://addons/assetplacer/viewport_3d_controllers/viewport_3d_controller.gd")
const MainUIController = preload("res://addons/assetplacer/main_ui_controller.gd")
const SnappingConfigController = preload("res://addons/assetplacer/ui/snapping_config_ui/snapping_config_controller.gd")
const PlacementConfigController = preload("res://addons/assetplacer/ui/placement_config_ui/placement_config_controller.gd")
const AssetPaletteController = preload("res://addons/assetplacer/viewport_3d_controllers/asset_palette_controller.gd")
const PlacementController = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_controller.gd")
const SnappingController = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_controller.gd")
const PlaneController = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/plane_controller.gd")
const TooltipPanel = preload("res://addons/assetplacer/tooltip_panel.gd")

################
## static & constants

const ASSET_PLACER_TITLE := "AssetPlacer"
const PLUGIN_FOLDER_PATH: String = "res://addons/assetplacer"
const PLUGIN_FILE_PATH: String = PLUGIN_FOLDER_PATH + "/plugin.cfg"
const UI_ROUND_TO_DECIMALS = 3

static var plugin_version := "0.0"
static var godot_version := "4.6"
static var cleanup_needed := false

############
## controllers
var shortcuts: Shortcuts
var main_ui_controller: MainUIController
var asset_palette_controller: AssetPaletteController
var placement_config_controller: PlacementConfigController
var placement_controller: PlacementController
var snapping_config_controller: SnappingConfigController
var snapping_controller: SnappingController
var plane_controller: PlaneController
var viewport_controllers: Array[Viewport3DController] = []

########################
## inherited methods


static func is_godot4_version_greater(p_minor: int) -> bool:
	var version := Engine.get_version_info()
	return version.major >= 4 && version.minor >= p_minor


static func replace_tags(p_str: String) -> String:
	var newstr := p_str
	newstr = newstr.replace("##version##", plugin_version)
	newstr = newstr.replace("##godotversion##", godot_version)
	return newstr


static func round_to_ui_decimals(p_f: float) -> float:
	var mag := pow(10, UI_ROUND_TO_DECIMALS)
	return round(p_f * mag) / mag


# override
func _initialize() -> void:
	if !FileAccess.file_exists(PLUGIN_FILE_PATH):
		printerr(
			(
				("AssetPlacerPlugin: Plugin location appears to be incorrect. Plugin expected at: %s. " % PLUGIN_FILE_PATH)
				+ "\nPlease follow these steps to fix: "
				+ "\n1. Deactivate the plugin "
				+ "\n2. Make sure the assetplacer folder is directly contained in the addons folder"
				+ "\n3. Enable the plugin again"
			)
		)
		_init_failed = true
		return

	if is_godot4_version_greater(2):
		plugin_version = get_plugin_version()
	else:
		plugin_version = read_plugin_version()

	cleanup_needed = true  # need to clean up

	UIRegistry.register(UIRegistry.PLUGIN_NODE, self)

	# initialize state
	AssetPlacerState.initialize()
	init_editor_toolbar_button_container()
	AssetPlacerState.instance.editor_state.toolbar_button_container_invalid.connect(init_editor_toolbar_button_container)
	AssetPlacerPersistence.initialize()
	InputManager.initialize()
	Settings.init_settings()

	main_ui_controller = MainUIController.new(self)
	placement_config_controller = PlacementConfigController.new()
	snapping_config_controller = SnappingConfigController.new()
	asset_palette_controller = AssetPaletteController.new()
	placement_controller = PlacementController.new()
	snapping_controller = SnappingController.new()
	plane_controller = PlaneController.new(1)  # receive input first

	add_child(placement_config_controller)
	add_child(snapping_config_controller)
	add_child(asset_palette_controller)
	add_child(placement_controller)
	add_child(snapping_controller)
	add_child(plane_controller)

	placement_config_controller.initialize(main_ui_controller.main_ui.placement_config_ui)
	snapping_config_controller.initialize(main_ui_controller.main_ui.snapping_config_view)
	asset_palette_controller.initialize(main_ui_controller.main_ui.asset_palette_view, main_ui_controller.main_ui.dynamic_preview_view)
	placement_controller.initialize(get_undo_redo())
	snapping_controller.initialize()
	plane_controller.initialize()
	scene_changed.connect(_on_scene_changed)

	for c in get_children():
		if c is Viewport3DController:
			viewport_controllers.append(c)
	viewport_controllers.sort_custom(func(a: Viewport3DController, b: Viewport3DController) -> bool: return a.input_priority > b.input_priority)


func init_editor_toolbar_button_container() -> void:
	# Reverse engineering to find the Toolbar over the 3D viewport
	var dummy := Control.new()
	add_control_to_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, dummy)
	AssetPlacerState.instance.editor_state.toolbar_button_container = dummy.get_parent().get_parent().get_parent().get_child(0)
	remove_control_from_container(CustomControlContainer.CONTAINER_SPATIAL_EDITOR_MENU, dummy)
	dummy.queue_free()


func _notification(p_what: int) -> void:
	if _init_failed:
		return
	match p_what:
		NOTIFICATION_CRASH, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_EDITOR_PRE_SAVE:
			AssetPlacerPersistence.save_plugin_data()


# override
func _cleanup() -> void:
	AssetPlacerPersistence.save_plugin_data()
	asset_palette_controller.cleanup()
	placement_config_controller.cleanup()
	snapping_config_controller.cleanup()
	snapping_controller.cleanup()
	placement_controller.cleanup()
	plane_controller.cleanup()
	AssetPlacerPersistence.cleanup()
	main_ui_controller.cleanup()
	cleanup_needed = false


func _on_scene_changed(_p_scene_root: Node) -> void:
	AssetPlacerState.instance.scene_changed.emit()
	AssetPlacerPersistence.save_plugin_data()


# override
func _forward_input(p_event: InputEvent) -> void:
	InputManager.instance.forward_input(p_event)


# override
func _forward_3d_viewport_input(p_viewport: SubViewport, p_event: InputEvent) -> void:
	var vp_rect := Rect2(p_viewport.get_screen_transform().origin, p_viewport.get_visible_rect().size * p_viewport.get_screen_transform().get_scale())
	TooltipPanel.instance.update_position(vp_rect, InputManager.instance.screen_mouse_position)

	AssetPlacerState.instance.viewport_input_handled = false
	var action: InputManager.ActionType = InputManager.instance.forward_3d_viewport_input(p_viewport, p_event)
	if Editor3DViewportUtils.is_editor_viewport_previewing_camera(p_viewport):
		return

	if not (InputManager.instance.rmb_pressed and action == InputManager.ActionType.MOVEMENT):
		for c in viewport_controllers:
			# Regular viewport input handling doesnt work in my testautomation, because the test automation wants to call this function directly, but then the viewport doesnt mark input as unhandled.
			if AssetPlacerState.instance.viewport_input_handled:
				p_viewport.set_input_as_handled()
				break
			c.forward_3d_viewport_input(p_viewport, p_event, action)


# override
func _forward_3d_viewport_unhandled_input(_p_viewport: SubViewport, _p_event: InputEvent) -> void:
	return


# override
func _process_update(_p_delta: float) -> void:
	placement_controller.process()
	plane_controller.process()


# override
func _create_draw_panel() -> EditorDrawPanel:
	return TooltipPanel.new()


#######################
## public methods


func read_plugin_version() -> String:
	var file := FileAccess.open(PLUGIN_FILE_PATH, FileAccess.READ)
	while !file.eof_reached():
		var line := file.get_line()
		if line.begins_with("version"):
			var idx := line.find('\"')
			return line.substr(idx + 1, line.rfind('\"') - idx - 1)
	return ""

#####################
## private methods
