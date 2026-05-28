# preview_camera_3d.gd
# © Copyright CookieBadger 2026
@tool
extends Camera3D

const UPDATES_BEFORE_READY: int = 1

signal preview_ready

var _updates: int = 0


func _process(_delta: float) -> void:
	if _updates == UPDATES_BEFORE_READY:
		preview_ready.emit()
	_updates += 1


func start_preview(p_transform: Transform3D) -> void:
	current = true
	transform = p_transform
	_updates = 0
