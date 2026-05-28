# viewport_3d_controller.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const InputManager = preload("res://addons/assetplacer/input_manager.gd")
const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Tips = preload("res://addons/assetplacer/tooltip_panel.gd")
const Lang = preload("res://addons/assetplacer/lang.gd")

var input_priority: int


func _init(p_input_priority: int = 0) -> void:
	self.input_priority = p_input_priority


func forward_3d_viewport_input(_p_viewport: SubViewport, _p_event: InputEvent, _p_action: InputManager.ActionType) -> void:
	pass


func accept_input() -> void:
	AssetPlacerState.instance.viewport_input_handled = true
