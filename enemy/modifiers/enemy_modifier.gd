extends Resource
class_name EnemyModifier
## A modifier that can be dropped onto an Enemy's `modifiers` array to change it —
## e.g. a Poisonous Frog. Bundles a visual sheen, a behavior, and stat tweaks.
##
## Visual: `overlay_material` is rendered ON TOP of the enemy's normal meshes
## (via MeshInstance3D.material_overlay), so it tints/sheens without repainting.
## Behavior: `behavior_scene` is a Node added under the enemy that hooks its
## lifecycle (e.g. spawn a toxic cloud when it dies).

@export var mod_name: String = "Modifier"
## Usually a ShaderMaterial. Applied as material_overlay to every enemy mesh.
@export var overlay_material: Material
## A Node scene added under the enemy. It reads its parent enemy and wires behavior.
@export var behavior_scene: PackedScene
## Stat tweaks applied at spawn.
@export var health_mult: float = 1.0
@export var speed_mult: float = 1.0
