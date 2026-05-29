extends Resource
class_name MapPOI

## A point of interest to display on the map with an icon and optional label.

enum POIType { GENERIC, SHOPKEEPER, BOSS, ITEM, EXIT, CAMPFIRE }

@export var label: String = ""
@export var poi_type: POIType = POIType.GENERIC
@export var icon: Texture2D
## XZ world position of this POI.
@export var world_position: Vector2 = Vector2.ZERO
## If true, always shown even without player discovery.
@export var always_visible: bool = true
