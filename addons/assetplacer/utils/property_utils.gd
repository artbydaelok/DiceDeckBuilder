# property_utils.gd
# © Copyright CookieBadger 2026
@tool
extends Object


static func builtin_enum_to_property_hint_string(_class: StringName, enum_name: StringName) -> String:
	var enum_constants := ClassDB.class_get_enum_constants(_class, enum_name)
	var hint_string := ""
	var i := 0
	for en in enum_constants:
		var val := ClassDB.class_get_integer_constant(_class, en)
		hint_string += "%s%s:%d" % ["" if i == 0 else ",", en.to_lower().capitalize(), val]
		i += 1
	return hint_string
