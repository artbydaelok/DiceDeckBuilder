@tool
var _users: Array = []


func update_usage(user: String, active: bool) -> void:
	if not active:
		_users.erase(user)
	elif not _users.has(user):
		_users.append(user)


func has_users() -> bool:
	return _users.size() > 0
