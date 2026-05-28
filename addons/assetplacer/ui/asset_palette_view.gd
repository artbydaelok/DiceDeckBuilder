# asset_palette_view.gd
# © Copyright CookieBadger 2026
@tool
extends PanelContainer

## singletons and statics
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const PropertyUtils = preload("res://addons/assetplacer/utils/property_utils.gd")
const AssetPlacerUI = preload("res://addons/assetplacer/ui/assetplacer_ui.gd")
const AssetPaletteController = preload("res://addons/assetplacer/viewport_3d_controllers/asset_palette_controller.gd")

const AssetDropPanel = preload("res://addons/assetplacer/ui/asset_drop_panel.gd")
const SaveAssetLibraryDialog = preload("res://addons/assetplacer/ui/save_asset_library_dialog.gd")
const RightClickPopup = preload("res://addons/assetplacer/ui/components/right_click_popup.gd")
const AssetPlacerButton = preload("res://addons/assetplacer/ui/assetplacer_button.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const ThemeBuilder = preload("res://addons/assetplacer/ui/theme_builder.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

const EMPTY_TAB_TITLE: String = "[Empty]"
const PREVIEW_PERSPECTIVE_CONTEXT_MENU_LABEL: String = "Preview Perspective"

signal assets_added(asset_paths: PackedStringArray)
signal assets_removed(asset_paths: PackedStringArray)
signal asset_selected(asset_path: String)
signal asset_transform_reset(asset_path: String)
signal asset_library_saved(library_name: String, library_path: String, change_name: bool)
signal libraries_reordered(library_titles_reordered: Array[String])
signal asset_library_selected_to_load(library_path: String)
signal asset_tab_selected(tab_title: String)
signal new_tab_pressed
signal match_selected_pressed

# right click popup signals
@warning_ignore_start("unused_signal")
signal asset_library_removed(library: String)
signal reload_asset_preview(asset_path: String)
signal generate_zoo(library_name: String)
signal reload_library_previews(library: String)
signal default_library_previews(library: String)
@warning_ignore_restore("unused_signal")

signal library_preview_perspective_changed(library: String, perspective: Asset3DData.PreviewPerspective)
signal asset_preview_perspective_changed(asset_path: String, perspective: Asset3DData.PreviewPerspective)
signal dynamic_preview_shown(asset_path: String, button: AssetPlacerButton)

@export var asset_button_right_click_popup: RightClickPopup
@export var broken_asset_button_right_click_popup: RightClickPopup
@export var tab_right_click_popup: RightClickPopup
@export var library_tab_bar: TabBar
@export var add_library_button: Button
@export var save_button: Button
@export var load_button: Button
@export var load_asset_library_dialog: FileDialog
@export var save_asset_library_dialog: SaveAssetLibraryDialog
@export var match_selected_button: Button
@export var assetplacer_button: PackedScene
@export var asset_palette_scroll_container: ScrollContainer
@export var asset_palette_filter_line_edit: LineEdit
@export var drop_panel: AssetDropPanel
@export var asset_grid: Control
@export var asset_button_size_slider: Slider

var palette_state: AssetPlacerState.PaletteState:
	get:
		return AssetPlacerState.instance.palette_state

var _library_scroll_positions: Dictionary[String, int] = {}
var _broken_icon: Texture2D
var _suppress_tab_selected_signal: bool = false
var _asset_buttons: Dictionary[String, Button] = {}
var _default_asset_button_size: Vector2 = Vector2(100, 100)
var _default_asset_button_font_size: int = 18
var _selected_asset: Button

var _prev_selected_tab := -1
var _prev_selected_tab_title: String = ""


func initialize() -> void:
	Settings.register_setting(
		Settings.DEFAULT_CATEGORY, Settings.LIBRARY_SAVE_LOCATION, FileDialog.ACCESS_USERDATA, TYPE_INT, PROPERTY_HINT_ENUM, PropertyUtils.builtin_enum_to_property_hint_string("FileDialog", "Access")
	)

	var library_save_location: FileDialog.Access = Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.LIBRARY_SAVE_LOCATION)
	load_asset_library_dialog.access = library_save_location
	save_asset_library_dialog.access = library_save_location
	if library_save_location == FileDialog.ACCESS_USERDATA:
		_create_save_folder_if_not_exists(library_save_location)
		load_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER
		save_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER

	_connect_signals()
	_setup_icons_and_popups()
	EditorInterface.get_base_control().theme_changed.connect(_setup_icons_and_popups)

	_reset_tab_bar()
	match_selected_button.disabled = true


func register_nodes() -> void:  # test automation
	UIRegistry.register(UIRegistry.PALETTE_ASSET_DROP_AREA, drop_panel)
	UIRegistry.register(UIRegistry.PALETTE_ASSET_BUTTON_CONTAINER, asset_grid)
	UIRegistry.register(UIRegistry.PALETTE_ADD_LIBRARY_BUTTON, add_library_button)
	UIRegistry.register(UIRegistry.PALETTE_SAVE_LIBRARY_FILEDIALOG, save_asset_library_dialog)
	UIRegistry.register(UIRegistry.PALETTE_LOAD_LIBRARY_FILEDIALOG, load_asset_library_dialog)
	UIRegistry.register(UIRegistry.PALETTE_ASSET_BUTTON_RIGHT_CLICK_POPUP, asset_button_right_click_popup)
	UIRegistry.register(UIRegistry.PALETTE_BROKEN_ASSET_BUTTON_RIGHT_CLICK_POPUP, broken_asset_button_right_click_popup)
	UIRegistry.register(UIRegistry.PALETTE_LIBRARY_TAB_RIGHT_CLICK_POPUP, tab_right_click_popup)
	UIRegistry.register(UIRegistry.PALETTE_LIBRARY_TAB_BAR, library_tab_bar)
	UIRegistry.register(UIRegistry.PALETTE_SAVE_LIBRARY_BUTTON, save_button)
	UIRegistry.register(UIRegistry.PALETTE_LOAD_LIBRARY_BUTTON, load_button)
	UIRegistry.register(UIRegistry.PALETTE_MATCH_SELECTED_ASSET_BUTTON, match_selected_button)
	UIRegistry.register(UIRegistry.PALETTE_ASSET_BUTTON_SIZE_SLIDER, asset_button_size_slider)
	UIRegistry.register(UIRegistry.PALETTE_SCROLL_CONTAINER, asset_palette_scroll_container)
	UIRegistry.register(UIRegistry.PALETTE_FILTER_LINE_EDIT, asset_palette_filter_line_edit)


func _connect_signals() -> void:
	palette_state.save_disabled_changed.connect(_library_save_disabled_changed)
	palette_state.selected_asset_changed.connect(_on_asset_selected)
	palette_state.current_library_switched.connect(_on_library_switched)
	palette_state.libraries_changed.connect(update_library_tab_bar)
	palette_state.library_names_changed.connect(_on_library_names_changed)
	palette_state.library_data_changed.connect(_on_library_data_changed)
	palette_state.asset_updated.connect(func(a: Asset3DData, _b: bool) -> void: _update_asset_button(a))

	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	# Asset Library TabBar
	library_tab_bar.tab_selected.connect(_on_tab_selected)
	library_tab_bar.active_tab_rearranged.connect(_on_tabs_rearranged)
	library_tab_bar.gui_input.connect(_on_tab_bar_gui_input)
	add_library_button.pressed.connect(new_tab_pressed.emit)

	load_button.pressed.connect(_on_load_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_asset_library_dialog.file_selected.connect(_on_asset_library_load_file_select)
	save_asset_library_dialog.file_selected.connect(_on_asset_library_save_file_select)
	asset_palette_filter_line_edit.text_submitted.connect(func(_t: String) -> void: asset_palette_filter_line_edit.release_focus())
	asset_palette_filter_line_edit.text_changed.connect(_update_asset_filter)
	match_selected_button.pressed.connect(match_selected_pressed.emit)

	drop_panel.assets_dropped.connect(_on_assets_dropped)
	drop_panel.gui_input.connect(_on_panel_gui)
	asset_button_size_slider.value_changed.connect(_on_asset_button_size_slider_changed)


func _setup_icons_and_popups() -> void:
	var bc := EditorInterface.get_base_control()
	_broken_icon = bc.get_theme_icon("FileBrokenBigThumb", "EditorIcons")

	for asset_path: String in _asset_buttons.keys():
		_asset_buttons[asset_path].update_button_icon()
		if _asset_buttons[asset_path].is_broken:
			update_asset_preview(asset_path, _broken_icon)

	var add_icon := bc.get_theme_icon("Add", "EditorIcons")
	add_library_button.text = ""
	add_library_button.icon = add_icon

	var search_icon := bc.get_theme_icon("Search", "EditorIcons")
	asset_palette_filter_line_edit.right_icon = search_icon

	var remove_icon := bc.get_theme_icon("Remove", "EditorIcons")
	var scene_icon := bc.get_theme_icon("PackedScene", "EditorIcons")
	var filesystem_icon := bc.get_theme_icon("Filesystem", "EditorIcons")
	var save_icon := bc.get_theme_icon("Save", "EditorIcons")
	var reload_icon := bc.get_theme_icon("Reload", "EditorIcons")
	var center_view_icon := bc.get_theme_icon("CenterView", "EditorIcons")
	var selectable_previews := Asset3DData.PreviewPerspective.keys()
	selectable_previews.erase(selectable_previews[Asset3DData.PreviewPerspective.CUSTOM])

	asset_button_right_click_popup.clear()
	asset_button_right_click_popup.add_entry("Remove", remove_icon, _remove_asset)
	asset_button_right_click_popup.add_condition_entry("Open Scene", scene_icon, _open_asset_scene, _is_not_asset_res_file)
	asset_button_right_click_popup.add_entry("Show in FileSystem", null, _show_asset_in_file_system)
	asset_button_right_click_popup.add_signal_entry("Reload Preview", reload_icon, _emit_path_signal, "reload_asset_preview")
	asset_button_right_click_popup.add_entry("Open Dynamic Preview", null, _on_show_dynamic_preview, KEY_V)
	asset_button_right_click_popup.add_enum_entry(PREVIEW_PERSPECTIVE_CONTEXT_MENU_LABEL, _set_preview_perspective, selectable_previews)

	broken_asset_button_right_click_popup.clear()
	broken_asset_button_right_click_popup.add_signal_entry("Try Reload", reload_icon, _emit_path_signal, "reload_asset_preview")
	broken_asset_button_right_click_popup.add_entry("Remove", remove_icon, _remove_asset)

	tab_right_click_popup.clear()
	tab_right_click_popup.add_signal_entry("Close Tab", remove_icon, _emit_path_signal, "asset_library_removed")
	tab_right_click_popup.add_entry("Show in File Manager", filesystem_icon, _on_show_asset_library_in_file_manager)
	tab_right_click_popup.add_entry("Save as", save_icon, show_save_as_dialog)
	tab_right_click_popup.add_signal_entry("Reload all Previews", reload_icon, _emit_path_signal, "reload_library_previews")
	tab_right_click_popup.add_enum_entry(PREVIEW_PERSPECTIVE_CONTEXT_MENU_LABEL, _set_library_preview_perspective, selectable_previews)
	tab_right_click_popup.add_signal_entry("Reset all Preview Perspectives", reload_icon, _emit_path_signal, "default_library_previews")
	tab_right_click_popup.add_signal_entry("Generate Asset Zoo", center_view_icon, _emit_path_signal, "generate_zoo")


static func _can_match_selection() -> bool:
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	return selected_nodes.size() == 1 && selected_nodes[0].owner == EditorInterface.get_edited_scene_root()


func _on_tabs_rearranged(p_active_tab_new_idx: int) -> void:
	_prev_selected_tab = p_active_tab_new_idx
	var reordered_library_titles: Array[String] = []

	for i in range(library_tab_bar.get_tab_count()):
		if library_tab_bar.get_tab_title(i) != EMPTY_TAB_TITLE:
			reordered_library_titles.push_back(library_tab_bar.get_tab_title(i))

	libraries_reordered.emit(reordered_library_titles)


func _on_library_switched() -> void:
	_select_tab_from_title(palette_state.current_library)
	update_all_assets()
	scroll_to_previous_library_pos()


func _on_tab_selected(p_index: int) -> void:
	if p_index == _prev_selected_tab:
		return

	if _suppress_tab_selected_signal:
		return  # prevent infinite recursions

	if p_index < palette_state.library_titles_sorted.size():
		var lib_title := palette_state.library_titles_sorted[p_index]
		asset_tab_selected.emit(lib_title)


func _select_tab_from_title(p_tab_title: String) -> void:
	if not p_tab_title:
		assert(library_tab_bar.get_tab_title(0) == EMPTY_TAB_TITLE)
		assert(not palette_state.current_library)
		assert(palette_state.library_titles_sorted.size() == 0)
		_set_library_tab(0)  # Empty
		return
	var tab := get_tab_idx(p_tab_title)
	if tab != -1:
		_set_library_tab(tab)
	else:
		_set_library_tab(-1)


func _set_library_tab(p_idx: int) -> void:
	# involuntarily triggers tab_selected signal
	_suppress_tab_selected_signal = true
	library_tab_bar.current_tab = p_idx
	_suppress_tab_selected_signal = false

	_tab_selection_side_effects()


func _add_library_tab(p_library_title: String) -> void:
	# involuntarily triggers tab_selected signal if it's the first tab
	_suppress_tab_selected_signal = true
	library_tab_bar.add_tab(p_library_title)
	_suppress_tab_selected_signal = false


func _tab_selection_side_effects() -> void:
	if _prev_selected_tab_title:
		_library_scroll_positions[_prev_selected_tab_title] = asset_palette_scroll_container.scroll_vertical

	_prev_selected_tab = library_tab_bar.current_tab
	_prev_selected_tab_title = library_tab_bar.get_tab_title(_prev_selected_tab)
	asset_palette_filter_line_edit.clear()
	if asset_palette_filter_line_edit.is_inside_tree():
		asset_palette_filter_line_edit.release_focus()


func _on_library_data_changed(p_library_title: String, _p_data: Variant) -> void:
	if p_library_title == palette_state.current_library:
		update_changed_assets()


func _on_selection_changed() -> void:
	match_selected_button.disabled = not _can_match_selection()


func _on_asset_library_save_file_select(p_path: String) -> void:
	asset_library_saved.emit(save_asset_library_dialog.asset_library_name, p_path, save_asset_library_dialog.change_name)
	save_asset_library_dialog.current_file = ""
	save_asset_library_dialog.deselect_all()


func _on_asset_library_load_file_select(p_path: String) -> void:
	asset_library_selected_to_load.emit(p_path)


func _update_asset_filter(p_text: String) -> void:
	for button: Button in _asset_buttons.values():
		button.visible = p_text.is_empty() or button.asset_name.to_lower().find(p_text.to_lower()) != -1


func _on_tab_bar_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		var mouse_button := p_event as InputEventMouseButton
		var tab := library_tab_bar.get_tab_idx_at_point(mouse_button.position)
		if tab == -1:
			return
		var title := library_tab_bar.get_tab_title(tab)
		if title.is_empty() or title == EMPTY_TAB_TITLE:
			return
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_on_asset_tab_right_clicked(title, library_tab_bar.get_screen_position() + mouse_button.position)
		elif mouse_button.button_index == MOUSE_BUTTON_MIDDLE and title != EMPTY_TAB_TITLE and mouse_button.is_pressed():
			asset_library_removed.emit(title)


func _on_load_button_pressed() -> void:
	var window_position := get_viewport().get_window().position
	var viewport_rect_center := get_viewport_rect().size / 2 as Vector2i
	load_asset_library_dialog.position = window_position + viewport_rect_center - load_asset_library_dialog.size / 2
	AssetPlacerUI.clamp_window_to_screen(load_asset_library_dialog, self)

	var access := int(Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.LIBRARY_SAVE_LOCATION))
	if access != load_asset_library_dialog.access:  # Access changed
		load_asset_library_dialog.access = access as FileDialog.Access
		if access == FileDialog.ACCESS_USERDATA:
			_create_save_folder_if_not_exists(access)
			load_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER
		else:
			load_asset_library_dialog.current_dir = ""

	load_asset_library_dialog.popup_centered()


func _on_save_button_pressed() -> void:
	if palette_state.current_library.is_empty() or !palette_state.current_library_data.save_path:
		show_save_dialog(palette_state.current_library, true)
	else:
		asset_library_saved.emit(palette_state.current_library, palette_state.current_library_data.save_path, save_asset_library_dialog.change_name)


func _create_save_folder_if_not_exists(p_access: FileDialog.Access) -> void:
	var library_dir_path := AssetPaletteController.get_asset_library_dir_path(p_access)
	if not DirAccess.dir_exists_absolute(library_dir_path):
		DirAccess.make_dir_recursive_absolute(library_dir_path)
		load_asset_library_dialog.access = FileDialog.ACCESS_USERDATA
		load_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER
		save_asset_library_dialog.access = FileDialog.ACCESS_USERDATA
		save_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER


func _emit_path_signal(p_signal_name: String, p_path: String) -> void:
	emit_signal(p_signal_name, p_path)


func _reset_tab_bar() -> void:
	library_tab_bar.clear_tabs()
	library_tab_bar.add_tab(EMPTY_TAB_TITLE)
	_set_library_tab(0)


func _on_show_asset_library_in_file_manager(p_library_name: String) -> void:
	var save_path: String = palette_state.library_data_dict[p_library_name].save_path
	if save_path:
		OS.shell_open(ProjectSettings.globalize_path(palette_state.library_data_dict[p_library_name].save_path.get_base_dir()))
	else:
		printerr("AssetPlacerPlugin: Can't open library in file manager. Library is not saved.")


func show_save_as_dialog(p_library_name: String) -> void:
	show_save_dialog(p_library_name, true)


func show_save_dialog(p_library_name: String, p_change_name: bool) -> void:
	var window_position := get_viewport().get_window().position
	var viewport_rect_center := get_viewport_rect().size / 2 as Vector2i
	save_asset_library_dialog.position = window_position + viewport_rect_center - save_asset_library_dialog.size / 2
	AssetPlacerUI.clamp_window_to_screen(save_asset_library_dialog, self)
	save_asset_library_dialog.asset_library_name = p_library_name

	var access: FileDialog.Access = Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.LIBRARY_SAVE_LOCATION)
	if access != save_asset_library_dialog.access:  # access changed
		save_asset_library_dialog.access = access
		if access == FileDialog.ACCESS_USERDATA:
			_create_save_folder_if_not_exists(access)
			save_asset_library_dialog.current_dir = AssetPaletteController.ASSET_LIBRARY_SAVE_FOLDER
		else:
			save_asset_library_dialog.current_dir = ""

	save_asset_library_dialog.change_name = p_change_name
	save_asset_library_dialog.popup_centered()


func _library_save_disabled_changed(p_disabled: bool) -> void:
	save_button.disabled = p_disabled


func _on_panel_gui(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		var button := p_event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			_deselect_asset()


func _on_assets_dropped(p_obj: PackedStringArray) -> void:
	assets_added.emit(p_obj)


func update_all_assets() -> void:
	_asset_buttons.clear()
	for child in asset_grid.get_children():
		asset_grid.remove_child(child)
		child.queue_free()

	if palette_state.current_library:
		_add_assets(palette_state.current_library_data.asset_data)


func update_changed_assets() -> void:
	var buttons_to_remove: Array = _asset_buttons.keys()
	for a in palette_state.current_library_data.asset_data:
		if _asset_buttons.has(a.path):
			buttons_to_remove.erase(a.path)
		else:
			_add_asset(a)
	_remove_assets(buttons_to_remove)


func _add_assets(p_asset_data: Array[Asset3DData]) -> void:
	for data in p_asset_data:
		_add_asset(data as Asset3DData)


func scroll_to_previous_library_pos() -> void:
	if _library_scroll_positions.has(palette_state.current_library):
		_set_palette_scroll_pos(_library_scroll_positions[palette_state.current_library])


func _remove_assets(p_asset_paths: PackedStringArray) -> void:
	for asset_path: String in _asset_buttons.keys():
		if p_asset_paths.has(asset_path):
			if _asset_buttons[asset_path] == _selected_asset:
				_deselect_asset()
			asset_grid.remove_child(_asset_buttons[asset_path])
			_asset_buttons[asset_path].queue_free()
			_asset_buttons.erase(asset_path)


func _on_asset_button_size_slider_changed(val: float) -> void:
	for button: Button in _asset_buttons.values():
		button.custom_minimum_size = _default_asset_button_size * val
		button.get_node("%Label").add_theme_font_size_override("font_size", int(round(_default_asset_button_font_size * val)))


func update_asset_preview(p_path: String, p_preview: Texture) -> void:
	if p_preview == null or not _asset_buttons.has(p_path):
		return
	_asset_buttons[p_path].set_thumbnail(p_preview)


func get_tab_idx(title: String) -> int:
	for i in range(library_tab_bar.get_tab_count()):
		if library_tab_bar.get_tab_title(i) == title:
			return i
	return -1


func _on_library_names_changed(p_prev_titles: Array[String]) -> void:
	var scroll_pos_dict: Dictionary[String, int] = {}
	for i in range(p_prev_titles.size()):
		var title := p_prev_titles[i]
		var new_title: String = palette_state.library_titles_sorted[i]
		if _library_scroll_positions.has(title):
			scroll_pos_dict[new_title] = _library_scroll_positions[title]
		if _prev_selected_tab_title == title:
			_prev_selected_tab_title = new_title
	_library_scroll_positions = scroll_pos_dict
	update_library_tab_bar()


func update_library_tab_bar() -> void:
	var removed_libraries: Array[String] = []
	for i in range(library_tab_bar.tab_count):
		removed_libraries.push_back(library_tab_bar.get_tab_title(i))
	library_tab_bar.clear_tabs()

	var libs: Array = palette_state.library_titles_sorted
	var cur_idx := 0

	for i in range(libs.size()):
		_add_library_tab(libs[i])

		# if library existed before, it is not removed, thus erase from the 'removed' list
		var rm_idx := removed_libraries.find(libs[i])
		if rm_idx >= 0:
			removed_libraries.remove_at(rm_idx)

		if libs[i] == palette_state.current_library:
			cur_idx = i

	if libs.size() == 0:
		_reset_tab_bar()

	_set_library_tab(cur_idx)

	for l in removed_libraries:
		_on_asset_library_removed(l)


func _on_asset_library_removed(p_title: String) -> void:
	if _library_scroll_positions.has(p_title):
		_library_scroll_positions.erase(p_title)


func _add_asset(p_data: Asset3DData) -> void:
	var asset_path := p_data.path
	var button := assetplacer_button.instantiate() as AssetPlacerButton
	var label := button.get_node("%Label") as Label
	var slider_val := asset_button_size_slider.value

	_default_asset_button_size = button.custom_minimum_size

	button.custom_minimum_size = _default_asset_button_size * slider_val
	var asset_name := AssetPaletteController.get_asset_name(asset_path)
	const MAX_DISPLAY_NAME_LENGTH = 14
	label.text = asset_name if asset_name.length() <= MAX_DISPLAY_NAME_LENGTH else asset_name.substr(0, MAX_DISPLAY_NAME_LENGTH - 2) + ".."
	label.add_theme_font_size_override("font_size", int(round(_default_asset_button_font_size * slider_val)))
	button.tooltip_text = asset_name
	asset_grid.add_child(button)
	_asset_buttons[asset_path] = button

	button.set_data(asset_path, asset_name)
	button.assets_dropped.connect(_on_assets_dropped)
	button.button_was_pressed.connect(_on_asset_button_pressed)
	button.right_clicked.connect(func(path: String, pos: Vector2) -> void: _on_asset_button_right_clicked(path, pos))
	button.reset_transform_pressed.connect(_asset_reset_transform_pressed)
	button.show_dynamic_preview.connect(func() -> void: _on_show_dynamic_preview(asset_path))
	button.set_reset_transform_button_visible(p_data.current_transform != p_data.default_transform)
	_update_asset_button(p_data)


func _update_asset_button(p_asset: Asset3DData) -> void:
	if _asset_buttons.has(p_asset.path):
		var button_type := AssetPlacerButton.ButtonType.MESH if p_asset.is_mesh else AssetPlacerButton.ButtonType.NORMAL
		_asset_buttons[p_asset.path].set_button_type(button_type)
		_asset_buttons[p_asset.path].update_button_icon()

		var button := _asset_buttons[p_asset.path]
		if p_asset.is_broken:
			update_asset_preview(p_asset.path, _broken_icon)
			button.tooltip_text = "Asset file not found. Was at: %s\nRight click for options." % [p_asset.path]
		else:
			update_asset_preview(p_asset.path, p_asset.preview_texture)
			if button.is_broken:  # was broken, but not broken anymore
				button.tooltip_text = button.asset_name
		button.is_broken = p_asset.is_broken
		set_reset_transform_button_visible(p_asset.path, p_asset.current_transform != p_asset.default_transform)


func _on_asset_button_right_clicked(p_asset_path: String, p_pos: Vector2) -> void:
	assert(palette_state.current_library_data.has_asset(p_asset_path), "AssetPath %s does not exist in current library" % [p_asset_path])
	display_asset_right_click_popup(p_asset_path, p_pos, palette_state.current_library_data.get_asset(p_asset_path).preview_perspective)


func _on_asset_tab_right_clicked(p_library: String, p_pos: Vector2) -> void:
	assert(palette_state.library_data_dict.has(p_library), "Data of library %s not found" % [p_library])
	display_tab_right_click_popup(p_library, p_pos, palette_state.library_data_dict[p_library].preview_perspective)


func display_asset_right_click_popup(p_asset_path: String, p_position: Vector2, p_perspective_idx: int) -> void:
	if _asset_buttons[p_asset_path].is_broken:
		_right_clicked(p_asset_path, p_position, broken_asset_button_right_click_popup)
	else:
		_right_clicked(p_asset_path, p_position, asset_button_right_click_popup)
		asset_button_right_click_popup.set_enum_entry_checked(PREVIEW_PERSPECTIVE_CONTEXT_MENU_LABEL, p_perspective_idx)


func display_tab_right_click_popup(p_library: String, p_position: Vector2, p_perspective_idx: int) -> void:
	_right_clicked(p_library, p_position, tab_right_click_popup)
	tab_right_click_popup.set_enum_entry_checked(PREVIEW_PERSPECTIVE_CONTEXT_MENU_LABEL, p_perspective_idx)


func _right_clicked(p_item_path: String, p_position: Vector2, p_popup: RightClickPopup) -> void:
	p_popup.position = p_position
	p_popup.reset_size()
	p_popup.popup()
	p_popup.item_path = p_item_path
	p_popup.update_conditions()


func _on_asset_selected(p_asset: Asset3DData) -> void:
	_mark_button(_selected_asset, false)  # deselect previous
	_selected_asset = _asset_buttons[p_asset.path] if p_asset else null
	if p_asset:
		_mark_button(_selected_asset, true)


func _deselect_asset() -> void:
	_emit_selection(null, false)


func _on_asset_button_pressed(p_button: AssetPlacerButton) -> void:
	_emit_selection(p_button, _selected_asset != p_button)


func _emit_selection(p_button: AssetPlacerButton, p_selected: bool) -> void:
	if p_selected:
		assert(p_button != null)
		asset_selected.emit(p_button.asset_path)
	else:
		asset_selected.emit("")


func _asset_reset_transform_pressed(_p_button: AssetPlacerButton, p_asset_path: String) -> void:
	asset_transform_reset.emit(p_asset_path)


func scroll_to_asset_button(p_asset_path: String) -> void:
	_set_palette_scroll_pos_to_button(_asset_buttons[p_asset_path])


func _set_palette_scroll_pos(p_pos: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame  # one frame is not enough, sometimes
	asset_palette_scroll_container.scroll_vertical = p_pos


func _set_palette_scroll_pos_to_button(p_button: Button) -> void:
	# Await position of potentially added button to be updated
	await get_tree().process_frame

	var max_scroll := int(max(asset_grid.size.y - asset_palette_scroll_container.size.y, 0))
	var button_pos := int(p_button.position.y)
	var scroll_pos: int = clamp(button_pos, 0, max_scroll)
	asset_palette_scroll_container.scroll_vertical = scroll_pos


func _mark_button(p_button: AssetPlacerButton, p_selected: bool) -> void:
	if p_button != null:
		p_button.theme_type_variation = ThemeBuilder.AssetButtonSelected if p_selected else ThemeBuilder.AssetButton


func _remove_asset(p_asset_path: String) -> void:
	if p_asset_path:
		assets_removed.emit([p_asset_path])


func _open_asset_scene(p_asset_path: String) -> void:
	if p_asset_path:
		EditorInterface.open_scene_from_path(p_asset_path)


func _is_not_asset_res_file(p_asset_path: String) -> bool:
	if p_asset_path:
		var valid_endings := [AssetPaletteController.RES_FILE_ENDING, AssetPaletteController.TRES_FILE_ENDING]
		return not valid_endings.any(func(x: String) -> bool: return p_asset_path.ends_with(x))
	return false


func _show_asset_in_file_system(p_asset_path: String) -> void:
	if p_asset_path:
		EditorInterface.get_file_system_dock().navigate_to_path(p_asset_path)


func _get_scroll_pos(p_tab_name: String) -> int:
	return _library_scroll_positions[p_tab_name] if _library_scroll_positions.has(p_tab_name) else 0


func set_reset_transform_button_visible(p_asset_path: String, p_visible: bool) -> void:
	_asset_buttons[p_asset_path].set_reset_transform_button_visible(p_visible)


func _set_preview_perspective(p_asset_path: String, p_perspective: Asset3DData.PreviewPerspective) -> void:
	asset_preview_perspective_changed.emit(p_asset_path, p_perspective)


func _set_library_preview_perspective(p_library_name: String, p_perspective: Asset3DData.PreviewPerspective) -> void:
	library_preview_perspective_changed.emit(p_library_name, p_perspective)


func _on_show_dynamic_preview(p_asset_path: String) -> void:
	dynamic_preview_shown.emit(p_asset_path, _asset_buttons[p_asset_path])
