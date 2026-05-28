# asset_zoo_generator.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const AssetLibraryData = preload("res://addons/assetplacer/asset_palette/asset_library_data.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")
const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const AssetInstantiator = preload("res://addons/assetplacer/asset_palette/asset_instantiator.gd")

const TEMP_ZOO_FOLDER_PATH := "%s/zoo" % AssetPlacerPlugin.PLUGIN_FOLDER_PATH
const TEMP_ZOO_PATH := "%s/temp_asset_zoo.tscn" % TEMP_ZOO_FOLDER_PATH

signal finished

var _temp_vp: SubViewport
var _scene: PackedScene
var _root_node: Node3D
var _library: AssetLibraryData
var _used := false


func generate(p_library_name: String, p_library: AssetLibraryData) -> void:
	if _used:
		push_warning("AssetZooGenerator should not be reused")
		return

	_used = true
	_library = p_library

	# Open new scene
	_scene = null
	AssetPlacerPersistence.check_folder_exists(TEMP_ZOO_FOLDER_PATH)

	print_rich("AssetPlacerPlugin: [b]Generating AssetZoo for '%s' ...[/b]" % [p_library_name])

	print_rich(
		(
			"AssetPlacerPlugin: [b]The zoo will be saved at a temporary location. If you want it to be persisted, make sure to save the scene at a different location in your project. %s[/b]"
			% ["A previously generated zoo was was overwritten." if ResourceLoader.exists(TEMP_ZOO_PATH) else ""]
		)
	)

	_scene = PackedScene.new()
	_root_node = Node3D.new()
	_root_node.name = "%s_zoo" % p_library_name

	# temporarily add the root node, so we can evaluate AABBs
	_temp_vp = SubViewport.new()
	add_child(_temp_vp)

	# instantiate all assets
	for asset in p_library.asset_data:
		var node: Node3D = AssetInstantiator.instantiate_asset(asset, p_library)
		if node != null:
			_root_node.add_child(node)
			node.owner = _root_node

	_root_node.ready.connect(_finish_generation)
	_temp_vp.add_child.call_deferred(_root_node)


func _finish_generation() -> void:
	SpatialUtils.organize_spatial_children(_root_node)

	# remove temp viewport
	_temp_vp.remove_child(_root_node)
	_temp_vp.queue_free()

	# pack, store and open scene
	_scene.pack(_root_node)
	ResourceSaver.save(_scene, TEMP_ZOO_PATH)

	if EditorInterface.get_open_scenes().has(TEMP_ZOO_PATH):
		EditorInterface.reload_scene_from_path(TEMP_ZOO_PATH)

	EditorInterface.open_scene_from_path(TEMP_ZOO_PATH)
	# needed to force editor tab switching in some cases
	EditorInterface.open_scene_from_path.call_deferred(TEMP_ZOO_PATH)

	finished.emit()
