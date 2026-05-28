# theme_builder.gd
# © Copyright CookieBadger 2026
@tool

# variations

const BackgroundPanelContainer: String = "BackgroundPanelContainer"
const TightBackgroundPanelContainer: String = "TightBackgroundPanelContainer"
const CorneredBackgroundPanelContainer: String = "CorneredBackgroundPanelContainer"
const DarkBackgroundPanelContainer: String = "DarkBackgroundPanelContainer"
const RaisedButton: String = "RaisedButton"
const HeaderLarge: String = "HeaderLarge"
const HeaderMedium: String = "HeaderMedium"
const HeaderSmall: String = "HeaderSmall"
const AssetButton: String = "AssetButton"
const AssetButtonSelected: String = "AssetButtonSelected"
const GreyedRaisedButton: String = "GreyedRaisedButton"

const VARIATIONS: Array[String] = [
	BackgroundPanelContainer,
	TightBackgroundPanelContainer,
	CorneredBackgroundPanelContainer,
	DarkBackgroundPanelContainer,
	RaisedButton,
	HeaderLarge,
	HeaderMedium,
	HeaderSmall,
	AssetButton,
	AssetButtonSelected,
	GreyedRaisedButton,
]


# Make a theme that has all variations that are needed, using calues and colors of the current Editor theme
static func create_theme_from_editor(merge: bool = false) -> Theme:
	var theme := Theme.new()
	var e_theme := Theme.new()
	if Engine.get_version_info().minor > 2:
		e_theme = EditorInterface.call("get_editor_theme")  # only works in 4.2+
	else:
		e_theme = EditorInterface.get_base_control().theme

	# copy default values
	if merge:
		theme.merge_with(e_theme)
		theme.remove_type("EditorIcons")  # about 15MB of images

	@warning_ignore_start("unused_variable")
	var base_color := e_theme.get_color("base_color", "Editor")
	var dark_color_1 := e_theme.get_color("dark_color_1", "Editor")
	var dark_color_2 := e_theme.get_color("dark_color_2", "Editor")
	var dark_color_3 := e_theme.get_color("dark_color_3", "Editor")
	var accent_color := e_theme.get_color("accent_color", "Editor")
	var font_color := e_theme.get_color("font_color", "Editor")

	var content_sb := e_theme.get_stylebox("Content", "EditorStyles")
	var background_sb := e_theme.get_stylebox("Background", "EditorStyles")
	var panel_container_panel_sb := e_theme.get_stylebox("panel", "Panel")
	var button_disabled_sb := e_theme.get_stylebox("disabled", "Button")
	var button_hover_sb := e_theme.get_stylebox("hover", "Button")
	var button_normal_sb := e_theme.get_stylebox("normal", "Button")
	var button_pressed_sb := e_theme.get_stylebox("pressed", "Button")
	var window_panel_sb := e_theme.get_stylebox("panel", "Window")
	var button_focus_sb := e_theme.get_stylebox("focus", "Button")
	@warning_ignore_restore("unused_variable")

	var background_panel_container_sb: StyleBoxFlat = panel_container_panel_sb.duplicate(true)
	background_panel_container_sb.bg_color = base_color
	background_panel_container_sb.draw_center = true
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "panel", BackgroundPanelContainer, background_panel_container_sb)
	theme.set_type_variation(BackgroundPanelContainer, "PanelContainer")

	var cornered_background_panel_container_sb: StyleBoxFlat = background_panel_container_sb.duplicate(true)
	cornered_background_panel_container_sb.set_corner_radius_all(0)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "panel", CorneredBackgroundPanelContainer, cornered_background_panel_container_sb)
	theme.set_type_variation(CorneredBackgroundPanelContainer, "PanelContainer")

	var tight_background_panel_container_sb: StyleBoxFlat = background_panel_container_sb.duplicate(true)
	tight_background_panel_container_sb.set_corner_radius_all(0)
	tight_background_panel_container_sb.set_content_margin_all(0)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "panel", TightBackgroundPanelContainer, tight_background_panel_container_sb)
	theme.set_type_variation(TightBackgroundPanelContainer, "PanelContainer")

	var dark_background_panel_container_sb: StyleBoxFlat = background_panel_container_sb.duplicate(true)
	dark_background_panel_container_sb.bg_color = dark_color_1
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "panel", DarkBackgroundPanelContainer, dark_background_panel_container_sb)
	theme.set_type_variation(DarkBackgroundPanelContainer, "PanelContainer")
	#var raised_button_disabled_sb : StyleBoxFlat = button_disabled_sb.duplicate(true)
	#var raised_button_hover_sb : StyleBoxFlat = button_hover_sb.duplicate(true)
	var raised_button_normal_sb: StyleBoxFlat = button_normal_sb.duplicate(true)
	raised_button_normal_sb.bg_color = base_color
	#var raised_button_pressed_sb : StyleBoxFlat = button_pressed_sb.duplicate(true)
	#theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "disabled", RaisedButton, raised_button_disabled_sb)
	#theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "hover", RaisedButton, raised_button_hover_sb)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "normal", RaisedButton, raised_button_normal_sb)
	#theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "pressed", RaisedButton, raised_button_pressed_sb)
	theme.set_type_variation(RaisedButton, "Button")

	# Greyed RaisedButton
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "normal", GreyedRaisedButton, raised_button_normal_sb)
	theme.set_theme_item(Theme.DATA_TYPE_COLOR, "font_color", GreyedRaisedButton, (font_color + base_color) / 2.0)
	theme.set_type_variation(GreyedRaisedButton, "Button")

	# Asset Button (normal, hover)
	var asset_button_sb: StyleBoxFlat = button_normal_sb.duplicate(true)
	asset_button_sb.bg_color = base_color
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "normal", AssetButton, asset_button_sb)
	var asset_button_focus_sb: StyleBoxFlat = button_focus_sb.duplicate(true)
	asset_button_focus_sb.set_border_width_all(1)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "focus", AssetButton, asset_button_focus_sb)
	theme.set_type_variation(AssetButton, "Button")

	# Selected Asset Button (normal, hover)
	var asset_button_selected_sb: StyleBoxFlat = asset_button_sb.duplicate(true)
	asset_button_selected_sb.set_border_width_all(2)
	asset_button_selected_sb.border_color = font_color
	var asset_button_selected_focus_sb: StyleBoxFlat = asset_button_selected_sb.duplicate(true)
	asset_button_selected_focus_sb.border_color = accent_color
	var asset_button_selected_hover_sb: StyleBoxFlat = button_hover_sb.duplicate(true)
	asset_button_selected_hover_sb.set_border_width_all(2)
	asset_button_selected_hover_sb.border_color = font_color
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "normal", AssetButtonSelected, asset_button_selected_sb)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "focus", AssetButtonSelected, asset_button_selected_focus_sb)
	theme.set_theme_item(Theme.DATA_TYPE_STYLEBOX, "hover", AssetButtonSelected, asset_button_selected_hover_sb)
	theme.set_type_variation(AssetButtonSelected, "Button")

	return theme
