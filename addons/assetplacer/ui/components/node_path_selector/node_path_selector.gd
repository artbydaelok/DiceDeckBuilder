# node_path_selector.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")
const NodePathSelectorGlue = preload("res://addons/assetplacer/ui/components/node_path_selector/node_path_selector_glue.gd")
const AssetPlacer3DPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")

const NULL_PATH = "@#@null"

signal node_changed

@export var class_type: String
@export var default_assign_root: bool
@export var text: String:
	set(value):
		text = value
		if not is_node_ready():
			await ready
			_node_path_selector_glue.text = value

var node: Node:
	get:
		return _node.get_ref()

var _node_path_selector_glue: NodePathSelectorGlue
var _node: WeakRef = weakref(null)
var _node_path: NodePath
var _node_path_save_key: String
var _root_was_null := false


func _ready() -> void:
	_node_path_selector_glue = get_node("Glue")


func initialize_ui() -> void:
	_node_path_selector_glue = get_node("Glue")
	_node_path_selector_glue.initialize()
	_node_path_selector_glue.select_node_button.node_dropped.connect(set_node_path)
	_node_path_selector_glue.select_node_button.pressed.connect(select_node)
	_node_path_selector_glue.set_selected_button.pressed.connect(set_selected)


func register_nodes(p_name: String) -> void:
	UIRegistry.register(p_name.path_join(UIRegistry.NODE_PATH_SELECTOR_SET_SELECTED_BUTTON), _node_path_selector_glue.set_selected_button)


func initialize(p_save_key: String) -> void:
	_node_path_save_key = p_save_key
	AssetPlacerState.instance.scene_changed.connect(_on_scene_changed)
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_scene_changed()
	_on_selection_changed()


func _process(_p_delta: float) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not Engine.is_editor_hint() or (root and root.is_ancestor_of(self)):
		return

	if node:
		if node.is_inside_tree():
			var path: NodePath = node.get_tree().edited_scene_root.get_path_to(node)
			if _node_path != path:
				_update_node_by_path(path)

			# rename detection, update
			if String(path) == "." and node.name != _node_path_selector_glue.select_node_button.text:
				_update_node_by_path(path)

		elif str(_node_path) != NULL_PATH:  # node invalid
			_update_node_by_path(NULL_PATH)

	if _root_was_null and root != null:
		_update_node_by_path(_node_path)

	_root_was_null = root == null


func set_selected() -> void:
	var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() == 1 and selected_nodes[0] != node:
		set_node_path(selected_nodes[0])
		if _node_path_selector_glue:
			_node_path_selector_glue.set_selected_button_disabled(true)


func select_node() -> void:
	if !node or !node.is_inside_tree():
		return
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)


func set_node_path(p_node: Node) -> void:
	var node_icon: Texture2D = null
	var prev := node
	var root := EditorInterface.get_edited_scene_root()
	if p_node and is_valid_type(p_node):
		assert(root && root.is_inside_tree())
		assert(p_node.is_inside_tree())
		_node = weakref(p_node)
		_node_path = root.get_path_to(p_node)

		var class_names := p_node.get_class().split(".")
		var node_name := class_names[class_names.size() - 1]
		node_icon = EditorInterface.get_base_control().get_theme_icon(node_name, "EditorIcons")
		if node_icon == EditorInterface.get_base_control().get_theme_icon("notavalidiconname", "EditorIcons"):  # File Broken icon
			node_icon = EditorInterface.get_base_control().get_theme_icon("Node", "EditorIcons")

		_node_path_selector_glue.set_node(p_node, node_icon)

	else:
		_node_path = NULL_PATH
		_node = weakref(null)
		_node_path_selector_glue.set_node(null, null)

	if _node_path_save_key:
		if (root and root.scene_file_path) or str(_node_path) != NULL_PATH:  # don't store <NULL> for unsaved scenes
			AssetPlacerPersistence.instance.store_scene_data(_node_path_save_key, _node_path)

	if prev != node:
		node_changed.emit()


func is_valid_type(p_node: Node) -> bool:
	if !class_type or class_type.is_empty():
		return true
	return p_node.get_class() == class_type


# The scene has changed i.e., user has closed the scene, or opened a new one
## It's special that this control saves and stores the path, and switches on scene change independently of the controller
## Technically, this does not follow our architecture, but it makes the bloated controllers a little lighter.
func _on_scene_changed() -> void:
	# load the new node
	var path: String = ""
	if EditorInterface.get_edited_scene_root() != null and _node_path_save_key:
		path = AssetPlacerPersistence.instance.load_scene_data(_node_path_save_key, NodePath("."), TYPE_NODE_PATH)

	_update_node_by_path(path, true)


func _on_selection_changed() -> void:
	if _node_path_selector_glue:
		var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
		_node_path_selector_glue.set_selected_button_disabled(selected_nodes.size() != 1 || selected_nodes[0] == node)


func _update_node_by_path(p_path: String, p_scene_changed: bool = false) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if !root or !root.is_inside_tree():
		# no root in the scene -> no nodes
		set_node_path(null)
		_node_path = ""  # this is to prevent the path==NullPath, thus when a root will be added, it will be set as the node.
		return

	if p_path == NULL_PATH:
		# path == NullPath: the old node could not be found anymore
		set_node_path(null)
		return

	# Check if spawnNode is still in the scene
	if not p_scene_changed and node and node.is_inside_tree():
		set_node_path(node)  # Updates the path
		return

	# Update spawn parent
	# Check if the path is valid
	var spawn_node := root.get_node_or_null(p_path)
	if spawn_node:
		set_node_path(spawn_node)
		return

	# Root exists, a path was loaded, but it doesn't lead to a valid node and the current Node is invalid
	# e.g. when the spawn parent was the root and it was deleted (and the scene change is not triggered first)
	# e.g. when you have an empty scene and you add a root for the first time.
	if default_assign_root and not p_scene_changed:
		set_node_path(root)
