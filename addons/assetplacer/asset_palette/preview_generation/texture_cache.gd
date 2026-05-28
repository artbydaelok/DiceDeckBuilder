# texture_cache.gd
# © Copyright CookieBadger 2026
@tool

const MAX_CACHE_SIZE: int = 2000
const CACHE_REMOVE_STEP: int = 50

var _cache: Dictionary[String, Texture2D] = {}  # preserves order


func check_cache(p_key: String) -> Texture2D:
	if _cache.has(p_key):
		var texture := _cache[p_key]
		# append at end of cache
		_cache.erase(p_key)
		_cache[p_key] = texture
		return texture
	return null


func remove_from_cache(p_key: String) -> void:
	_cache.erase(p_key)


func add_to_cache(p_key: String, p_texture: Texture2D) -> void:
	_cache[p_key] = p_texture
	if _cache.size() > MAX_CACHE_SIZE:
		var oldest_keys: Array[String] = _cache.keys().slice(0, CACHE_REMOVE_STEP)
		for old_key in oldest_keys:
			_cache.erase(old_key)
