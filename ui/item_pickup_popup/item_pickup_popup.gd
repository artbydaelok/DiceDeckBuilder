extends CanvasLayer
class_name ItemPickupPopup

## Juicy item-pickup notification popup.
##
## Scene setup (do this once in the editor):
##   1. Create a CanvasLayer node, attach this script.
##   2. Set layer to something high (e.g. 10) so it draws on top of everything.
##   3. Assign card_system in the inspector.
##
## The script builds all UI nodes at runtime — no child nodes needed.

@export var card_system: CardSystem

## How long the card is shown before sliding out.
@export var display_duration: float = 2.8

## Pixels from the bottom of the screen when fully shown.
@export var bottom_margin: float = 40.0

const POPUP_W := 300.0
const POPUP_H := 130.0

# ----- internal nodes (built in _ready) -----
var _anchor_root: Control   # full-rect; gives us a reliable coordinate space
var _panel: PanelContainer
var _artwork: TextureRect
var _name_label: Label
var _desc_label: Label
var _new_label: Label

# ----- state -----
var _queue: Array[Card] = []
var _showing: bool = false


func _ready() -> void:
	_build_ui()
	_panel.visible = false

	if card_system:
		card_system.item_obtained.connect(_on_item_obtained)
	else:
		push_warning("ItemPickupPopup: card_system not assigned in inspector.")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func preview_card(card: Card) -> void:
	## Manually enqueue a card for display (useful for testing).
	_on_item_obtained(card)


# ---------------------------------------------------------------------------
# Signal handler
# ---------------------------------------------------------------------------

func _on_item_obtained(card: Card) -> void:
	_queue.append(card)
	if not _showing:
		_show_next()


# ---------------------------------------------------------------------------
# Display logic
# ---------------------------------------------------------------------------

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return

	_showing = true
	var card: Card = _queue.pop_front()

	_artwork.texture = card.card_artwork
	_name_label.text  = card.card_name
	_desc_label.text  = card.card_description

	# Offsets when below the screen (slide-in start / slide-out end).
	var off_top    :=  POPUP_H + 60.0
	var off_bottom :=  POPUP_H + 60.0 + POPUP_H

	# Offsets when on-screen (resting position).
	var on_top    := -(POPUP_H + bottom_margin)
	var on_bottom := -bottom_margin

	# Snap off-screen, make visible, then tween in.
	_panel.offset_top    = off_top
	_panel.offset_bottom = off_bottom
	_panel.visible  = true
	_panel.modulate = Color(1.5, 1.5, 1.5, 0.0)

	# --- Slide in (TRANS_BACK = overshoot bounce) ---
	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(_panel, "offset_top",    on_top,    0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_in.tween_property(_panel, "offset_bottom", on_bottom, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_in.tween_property(_panel, "modulate",      Color.WHITE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await get_tree().create_timer(display_duration).timeout

	# --- Slide out ---
	var tween_out := create_tween().set_parallel(true)
	tween_out.tween_property(_panel, "offset_top",    off_top,    0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween_out.tween_property(_panel, "offset_bottom", off_bottom, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween_out.tween_property(_panel, "modulate:a",    0.0,        0.20).set_ease(Tween.EASE_IN)

	await tween_out.finished
	_panel.visible = false

	if not _queue.is_empty():
		await get_tree().create_timer(0.1).timeout

	_show_next()


# ---------------------------------------------------------------------------
# Programmatic UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-rect anchor root — always fills the viewport regardless of resolution.
	_anchor_root = Control.new()
	_anchor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_anchor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_anchor_root)

	# Panel — anchored to the bottom-center of the anchor root.
	# Horizontal: centered (anchor 0.5), offset left/right by half popup width.
	# Vertical: bottom edge (anchor 1.0), offset upward.
	_panel = PanelContainer.new()
	_panel.anchor_left   = 0.5
	_panel.anchor_right  = 0.5
	_panel.anchor_top    = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left   = -POPUP_W * 0.5
	_panel.offset_right  =  POPUP_W * 0.5
	_panel.offset_top    = -(POPUP_H + bottom_margin)
	_panel.offset_bottom = -bottom_margin
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_anchor_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# ---- "NEW ITEM" banner ----
	_new_label = Label.new()
	_new_label.text = "✦ NEW ITEM ✦"
	_new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_label.add_theme_font_size_override("font_size", 12)
	_new_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(_new_label)

	# ---- Horizontal row: artwork | text ----
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	# Artwork — fixed 64×64, no expansion.
	_artwork = TextureRect.new()
	_artwork.custom_minimum_size = Vector2(64, 64)
	_artwork.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_artwork.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	_artwork.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(_artwork)

	# Text column — fills remaining width.
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 4)
	hbox.add_child(text_col)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 12)
	_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(_desc_label)

	# StyleBox
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
