# surface_config_view.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const SurfaceAlignConfigUI = preload("res://addons/assetplacer/ui/components/surface_align_config_ui/surface_align_config_ui.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")

signal config_changed(align_to_surface: bool, align_axis: int)

@export var alignment_ui: SurfaceAlignConfigUI


func initialize() -> void:
	alignment_ui.initialize()
	alignment_ui.alignment_changed.connect(func(_x: bool, _y: int) -> void: _on_config_changed())
	AssetPlacerState.instance.placement_config_state.surface_align_enabled_changed.connect(func(b: bool) -> void: alignment_ui.enabled = b)
	# ToDo[SurfaceNormalOffset] AssetPlacerState.instance.placement_config_state.surface_normal_offset_changed.connect(func(o: float) -> void: alignment_ui.offset = o)
	AssetPlacerState.instance.placement_config_state.surface_align_axis_changed.connect(func(a: int) -> void: alignment_ui.axis = a)


func register_nodes() -> void:
	alignment_ui.register_nodes()


func _on_config_changed() -> void:
	config_changed.emit(alignment_ui.enabled, alignment_ui.axis)
