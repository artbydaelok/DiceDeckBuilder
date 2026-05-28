# terrain_3d_config_view.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const NodePathSelector = preload("res://addons/assetplacer/ui/components/node_path_selector/node_path_selector.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

signal config_changed(terrain_3d_node: Node)

@export var terrain3d_selector: NodePathSelector


func initialize() -> void:
	terrain3d_selector.initialize_ui()
	terrain3d_selector.node_changed.connect(func() -> void: _on_config_changed())
	AssetPlacerState.instance.placement_config_state.terrain_3d_node_changed.connect(func(n: Node) -> void: terrain3d_selector.set_node_path(n))


func register_nodes() -> void:
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_TERRAIN_3D_SELECTOR, terrain3d_selector)  # test automation access


func _on_config_changed() -> void:
	config_changed.emit(terrain3d_selector.node)
