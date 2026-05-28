# assetplacer_button.gd
# © Copyright CookieBadger 2026
@tool
extends Button

const AssetDropPanel = preload("res://addons/assetplacer/ui/asset_drop_panel.gd")

const TOGGLE_DYNAMIC_PREVIEW_KEY := KEY_V

signal right_clicked(asset_path: String, click_position: Vector2)
signal button_was_pressed(button: Button)
signal reset_transform_pressed(button: Button, asset_path: String)
signal show_dynamic_preview

## workaround to also have this here, to be not have to drop the items into the gaps
signal assets_dropped(asset_paths: PackedStringArray)

enum ButtonType { NORMAL, MESH }

@export var _thumbnail_texture_rect: TextureRect
@export var icon_texture_rect: TextureRect
@export var reset_transform_button: Button

var type: ButtonType = ButtonType.NORMAL
var asset_path: String
var asset_name: String
var is_broken: bool = false


func _can_drop_data(_p_at_position: Vector2, p_data: Variant) -> bool:
	return AssetDropPanel.can_drop_data(p_data)


func _drop_data(_p_at_position: Vector2, p_data: Variant) -> void:
	assets_dropped.emit(p_data["files"])


func _ready() -> void:
	pressed.connect(on_pressed)
	gui_input.connect(on_gui_input)
	reset_transform_button.pressed.connect(on_reset_transform)


func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		return

	if event is InputEventKey:
		if event.keycode == TOGGLE_DYNAMIC_PREVIEW_KEY && event.pressed && is_hovered() && not event.is_echo():
			show_dynamic_preview.emit()
			get_tree().root.set_input_as_handled()


func set_data(p_asset_path: String, p_asset_name: String) -> void:
	self.asset_path = p_asset_path
	self.asset_name = p_asset_name


func set_button_type(p_type: ButtonType) -> void:
	self.type = p_type


func update_button_icon() -> void:
	match type:
		ButtonType.NORMAL:
			icon_texture_rect.texture = null
		ButtonType.MESH:
			icon_texture_rect.texture = EditorInterface.get_base_control().get_theme_icon("Mesh", "EditorIcons")


func set_thumbnail(p_texture: Texture) -> void:
	_thumbnail_texture_rect.texture = p_texture


func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit(asset_path, get_screen_position() + event.position)


func on_pressed() -> void:
	button_was_pressed.emit(self)


func on_reset_transform() -> void:
	reset_transform_pressed.emit(self, asset_path)


func set_reset_transform_button_visible(p_visible: bool) -> void:
	reset_transform_button.visible = p_visible


func set_child_button_theme(p_button_theme: Theme) -> void:
	reset_transform_button.theme = p_button_theme
