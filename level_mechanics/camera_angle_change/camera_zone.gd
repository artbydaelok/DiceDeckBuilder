extends Area3D
class_name CameraZone

@export var phantom_camera: PhantomCamera3D
@export var is_default: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	if is_default:
		CameraZoneManager.set_default_zone(self)
	CameraZoneManager.enter_zone(self)

func _on_area_exited(area: Area3D) -> void:
	CameraZoneManager.exit_zone(self)

## Call this from a dialogue system or cutscene to manually release and disable the camera zone.
func release() -> void:
	CameraZoneManager.exit_zone(self)
	monitoring = false
