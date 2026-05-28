# lang.gd
# © Copyright CookieBadger 2026
@tool

const TIPS_EN: Dictionary[String, String] = {
	"click_to_place": "Click to Place",
	"place_and_select": "%s+Click to Place and Edit",
	"hologram_transform": "%s to Transform",
	"hologram_reset_transform": "%s to Reset Transform",
	"transform_confirm": "%s to confirm transformation",
	"no_spawn_parent": "No Spawn Parent set!",
	"no_surface": "Hover over a physics surface to place",
	"no_terrain": "Hover over Terrain3D to place",
	"rotate_place": "Move mouse left/right to rotate",
	"paint_begin": "Drag to place assets",
	"paint_continue": "Placing %d assets",
	"pos_occ": "Position occupied.",
	"child_exc": "Too many children - some duplication checks skipped.",
	"move_plane": "Click to Confirm",
	"no_terrain_node": "Assign Terrain3D Node!",
	"terrain_data_err": "Error retrieving Terrain3D data",
	"terrain_height_err": "Error retrieving Terrain3D height range",
	"terrain_intersection_err": "Error retrieving Intersection with Terrain3D",
	"terrain_hover_tip": "Hover over Terrain3D to place",
	"terrain_isec_err": "Error retrieving Intersection with Terrain3D",
	"terrain_normal_err": "Error retrieving Terrain3D Normal",
	"terrain_no_intersection": "(No Intersection with Terrain3D found)",
}


static func ttr(key: String, args: Array = []) -> String:
	var locale := TIPS_EN

	var fallback_locale := TIPS_EN

	if not locale.has(key):
		if fallback_locale.has(key):
			return fallback_locale[key]
		return key

	var tip := locale[key]
	if args.size() > 0:
		return tip % args
	return tip
