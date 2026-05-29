extends Node
## Custom SceneLoader autoload — replaces the Maaacks addon version.
## Same public API: load_scene(), reload_current_scene(), scene_loaded signal.

signal scene_loaded

var _scene_path: String = ""
var _background_loading: bool = false

func load_scene(scene_path: String, in_background: bool = false) -> void:
	GameEvents._on_scene_transition_start()
	if scene_path == null or scene_path.is_empty():
		push_error("SceneLoader: no path given to load")
		return
	_scene_path = scene_path
	_background_loading = in_background

	if ResourceLoader.has_cached(_scene_path):
		call_deferred("_finish_load")
		return

	ResourceLoader.load_threaded_request(_scene_path)
	set_process(true)


func reload_current_scene() -> void:
	get_tree().reload_current_scene()


func _finish_load() -> void:
	emit_signal("scene_loaded")
	if not _background_loading:
		var packed = ResourceLoader.load_threaded_get(_scene_path)
		if packed == null:
			packed = ResourceLoader.load(_scene_path)
		var err = get_tree().change_scene_to_packed(packed)
		if err != OK:
			push_error("SceneLoader: failed to change scene (%d)" % err)
			get_tree().quit()


func _ready() -> void:
	set_process(false)


func _process(_delta) -> void:
	var status = ResourceLoader.load_threaded_get_status(_scene_path)
	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			push_error("SceneLoader: failed to load '%s'" % _scene_path)
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_finish_load()
