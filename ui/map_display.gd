extends Control

## Full-screen map overlay. Opened by map_ability.gd.
## Pan: click-drag or arrow keys.
## Zoom: scroll wheel or +/- keys.

const ZOOM_MIN    := 0.4
const ZOOM_MAX    := 3.0
const ZOOM_STEP   := 0.15
const PAN_SPEED   := 400.0

const CHECKPOINT_DOT_SIZE := 10.0
const POI_ICON_SIZE       := 20.0
const CHECKPOINT_COLOR    := Color(0.9, 0.75, 0.2, 1.0)
const PLAYER_COLOR        := Color(0.2, 0.9, 0.4, 1.0)

@onready var _canvas:         Control         = %MapCanvas
@onready var _map_img:        TextureRect     = %MapImage
@onready var _player_marker:  Control         = %PlayerMarker
@onready var _open_sfx:       AudioStreamPlayer = $MapOpenSFX
@onready var _tooltip:        Label           = %Tooltip

var _map_data:    LevelMapData
var _player:      Player
var _save_system: SaveSystem

var _zoom:         float   = 1.0
var _dragging:     bool    = false
var _drag_start:   Vector2 = Vector2.ZERO
var _canvas_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	_player      = get_tree().get_first_node_in_group("player")
	_save_system = get_tree().get_root().find_child("SaveSystem", true, false)
	_map_data    = GameEvents.current_level.current_map_data

	GameEvents.menu_entered.emit()

	if _map_data == null or _map_data.map_texture == null:
		push_warning("MapDisplay: no map data set on current level.")
		return

	_map_img.texture = _map_data.map_texture
	_map_img.size    = Vector2(_map_data.map_texture.get_width(),
	                           _map_data.map_texture.get_height())
	_canvas.size     = _map_img.size

	_place_checkpoint_markers()
	_place_poi_markers()
	_update_player_marker()
	_center_on_player()

	if _open_sfx:
		_open_sfx.play()


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  dir.x += 1.0
	if Input.is_action_pressed("ui_right"): dir.x -= 1.0
	if Input.is_action_pressed("ui_up"):    dir.y += 1.0
	if Input.is_action_pressed("ui_down"):  dir.y -= 1.0
	if dir != Vector2.ZERO:
		_canvas.position += dir * PAN_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_close()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(ZOOM_STEP, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(-ZOOM_STEP, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging     = true
				_drag_start   = event.position
				_canvas_start = _canvas.position
			else:
				_dragging = false

	if event is InputEventMouseMotion and _dragging:
		_canvas.position = _canvas_start + (event.position - _drag_start)

	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_EQUAL, KEY_KP_ADD]:
			_apply_zoom(ZOOM_STEP, size * 0.5)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_apply_zoom(-ZOOM_STEP, size * 0.5)


func _apply_zoom(delta_zoom: float, pivot_screen: Vector2) -> void:
	var old_zoom := _zoom
	_zoom = clamp(_zoom + delta_zoom, ZOOM_MIN, ZOOM_MAX)
	var factor := _zoom / old_zoom
	_canvas.position = pivot_screen + (_canvas.position - pivot_screen) * factor
	_canvas.scale    = Vector2(_zoom, _zoom)


func _center_on_player() -> void:
	if _map_data == null or _player == null: return
	var pixel := _map_data.world_to_pixel(
		Vector2(_player.global_position.x, _player.global_position.z))
	_canvas.position = size * 0.5 - pixel * _zoom


func _update_player_marker() -> void:
	if _map_data == null or _player == null: return
	var pixel := _map_data.world_to_pixel(
		Vector2(_player.global_position.x, _player.global_position.z))
	_player_marker.position = pixel


func _place_checkpoint_markers() -> void:
	if _save_system == null: return
	var unlocked: Dictionary = _save_system.player_data.unlocked_checkpoints
	var level_key: String    = GameEvents.current_level.level_name
	if not unlocked.has(level_key): return
	for cp_path in unlocked[level_key]:
		var data: CheckpointData = load(cp_path)
		if data == null: continue
		var pixel := _map_data.world_to_pixel(
			Vector2(data.spawn_point.x, data.spawn_point.z))
		_spawn_dot(pixel, CHECKPOINT_COLOR, data.checkpoint_name)


func _spawn_dot(pixel: Vector2, color: Color, tip: String) -> void:
	var dot := ColorRect.new()
	dot.color    = color
	dot.size     = Vector2(CHECKPOINT_DOT_SIZE, CHECKPOINT_DOT_SIZE)
	dot.position = pixel - dot.size * 0.5
	dot.mouse_filter = Control.MOUSE_FILTER_STOP
	if not tip.is_empty():
		dot.mouse_entered.connect(func(): _tooltip.text = tip)
		dot.mouse_exited.connect(func():  _tooltip.text = "")
	_canvas.add_child(dot)


func _place_poi_markers() -> void:
	if _map_data == null: return
	for poi in _map_data.points_of_interest:
		var pixel := _map_data.world_to_pixel(poi.world_position)
		_spawn_poi(poi, pixel)


func _spawn_poi(poi: MapPOI, pixel: Vector2) -> void:
	var c := Control.new()
	c.position     = pixel - Vector2(POI_ICON_SIZE, POI_ICON_SIZE) * 0.5
	c.size         = Vector2(POI_ICON_SIZE, POI_ICON_SIZE)
	c.mouse_filter = Control.MOUSE_FILTER_STOP

	if poi.icon != null:
		var img := TextureRect.new()
		img.texture      = poi.icon
		img.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.size         = Vector2(POI_ICON_SIZE, POI_ICON_SIZE)
		c.add_child(img)
	else:
		var dot := ColorRect.new()
		dot.color = Color.WHITE
		dot.size  = Vector2(POI_ICON_SIZE, POI_ICON_SIZE)
		c.add_child(dot)

	if not poi.label.is_empty():
		c.mouse_entered.connect(func(): _tooltip.text = poi.label)
		c.mouse_exited.connect(func():  _tooltip.text = "")

	_canvas.add_child(c)


func _close() -> void:
	GameEvents.menu_exited.emit()
	queue_free()
