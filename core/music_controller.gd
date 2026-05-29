extends Node
## Custom MusicController autoload — replaces the Maaacks addon version.
## Same public API: play_stream(), fade_to_zero(), play_stream_player().
## Watches for AudioStreamPlayer nodes with bus == audio_bus and autoplay == true
## and reparents them here so music survives scene changes.

const MINIMUM_VOLUME_DB := -80.0

@export var audio_bus: StringName = &"Music"
@export var fade_out_duration: float = 1.5
@export var fade_in_duration: float = 1.0

var _player: AudioStreamPlayer  ## the managed, persistent player
var _saved_position: float = 0.0


# ── Public API ──────────────────────────────────────────────────────────────

func play_stream(audio_stream: AudioStream) -> AudioStreamPlayer:
	var sp := AudioStreamPlayer.new()
	sp.stream = audio_stream
	sp.bus = audio_bus
	add_child(sp)
	sp.play(_saved_position)
	_saved_position = 0.0
	play_stream_player(sp)
	return sp


func play_stream_player(stream_player: AudioStreamPlayer) -> void:
	if stream_player == _player:
		return
	_fade_out_and_free(_player)
	_player = stream_player
	if not _player.is_inside_tree():
		add_child(_player)
	_player.bus = audio_bus
	if not _player.playing:
		_player.play()
	_fade_in(_player)
	if not _player.tree_exiting.is_connected(_on_player_tree_exiting):
		_player.tree_exiting.connect(_on_player_tree_exiting)


func fade_to_zero() -> void:
	if not is_instance_valid(_player):
		return
	_saved_position = _player.get_playback_position()
	_fade_out_and_free(_player)
	_player = null


# ── Internals ───────────────────────────────────────────────────────────────

func _fade_in(sp: AudioStreamPlayer) -> void:
	if is_zero_approx(fade_in_duration):
		sp.volume_db = 0.0
		return
	sp.volume_db = MINIMUM_VOLUME_DB
	var tw := create_tween()
	tw.tween_property(sp, "volume_db", 0.0, fade_in_duration)


func _fade_out_and_free(sp: AudioStreamPlayer) -> void:
	if not is_instance_valid(sp):
		return
	if is_zero_approx(fade_out_duration):
		sp.queue_free()
		return
	var tw := create_tween()
	tw.tween_property(sp, "volume_db", MINIMUM_VOLUME_DB, fade_out_duration)
	tw.tween_callback(sp.queue_free)


func _on_player_tree_exiting() -> void:
	# If the player is being removed (scene change) and belongs to a scene node,
	# reparent it here to keep music alive.
	if not is_instance_valid(_player):
		return
	if _player.owner == null:
		return  # already ours
	var pos := _player.get_playback_position() + AudioServer.get_time_since_last_mix()
	var stream := _player.stream
	var new_sp := AudioStreamPlayer.new()
	new_sp.stream = stream
	new_sp.bus = audio_bus
	new_sp.volume_db = _player.volume_db
	add_child(new_sp)
	new_sp.play(pos)
	_player = new_sp
	if not _player.tree_exiting.is_connected(_on_player_tree_exiting):
		_player.tree_exiting.connect(_on_player_tree_exiting)


func _on_node_added(node: Node) -> void:
	if node == _player:
		return
	if not (node is AudioStreamPlayer):
		return
	var sp := node as AudioStreamPlayer
	if sp.bus != audio_bus or not sp.autoplay:
		return
	play_stream_player(sp)


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
