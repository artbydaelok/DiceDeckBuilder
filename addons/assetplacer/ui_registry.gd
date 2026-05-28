# ui_registry.gd
# © Copyright CookieBadger 2026
@tool

const PLUGIN_NODE := "plugin"
const MAIN_UI := "main_ui_control"

# placement config
const PLACEMENTCONFIG_SPAWN_PARENT_SELECTOR := "placementconfig_spawn_parent_selector"
const PLACEMENTCONFIG_RAY_MODE_OPTION_BUTTON := "placementconfig_ray_mode_option_button"

const PLACEMENTCONFIG_PLANE_OPTION_BUTTON := "placement_config_plane_option_button"
const PLACEMENTCONFIG_PLANE_POSITION_LINE_EDIT := "placement_config_plane_position_line_edit"
const PLACEMENTCONFIG_POSITION_FROM_SELECTED_BUTTON := "placement_config_position_from_selected_button"
const PLACEMENTCONFIG_RESET_POSITION_BUTTON := "placement_config_reset_position_button"

const PLACEMENTCONFIG_ALIGN_TO_NORMAL_CHECKBOX := "placement_config_align_checkbox"
const PLACEMENTCONFIG_ALIGNMENT_DIRECTION_OPTION_BUTTON := "placement_config_alignment_direction_option_button"

const PLACEMENTCONFIG_TERRAIN_3D_SELECTOR := "placement_config_terrain_3d_selector"

# snapping config

const SNAPPING_OFFSET_FROM_SELECTED_BUTTON := "snapping_offset_from_selected_button"
const SNAPPING_RESET_OFFSET_BUTTON := "snapping_reset_offset_button"
const SNAPPING_ENABLED_CHECKBOX := "snapping_enabled_checkbox"
const SNAPPING_SNAP_STEP_EDIT := "snapping_snap_step_edit"
const SNAPPING_SHIFT_SNAP_STEP_EDIT := "snapping_shift_snap_step_edit"
const SNAPPING_OFFSET_A_EDIT := "snapping_offset_a_edit"
const SNAPPING_OFFSET_B_EDIT := "snapping_offset_b_edit"

# asset palette
const PALETTE_ASSET_DROP_AREA := "palette_asset_drop_area"
const PALETTE_ASSET_BUTTON_CONTAINER := "palette_asset_button_container"
const PALETTE_SAVE_LIBRARY_FILEDIALOG := "palette_save_library_filedialog"
const PALETTE_LOAD_LIBRARY_FILEDIALOG := "palette_load_library_filedialog"
const PALETTE_ADD_LIBRARY_BUTTON := "palette_add_library_button"
const PALETTE_ASSET_BUTTON_RIGHT_CLICK_POPUP := "palette_asset_button_right_click_popup"
const PALETTE_BROKEN_ASSET_BUTTON_RIGHT_CLICK_POPUP := "palette_broken_asset_button_right_click_popup"
const PALETTE_LIBRARY_TAB_RIGHT_CLICK_POPUP := "palette_library_tab_right_click_popup"
const PALETTE_LIBRARY_TAB_BAR := "palette_library_tab_bar"
const PALETTE_SAVE_LIBRARY_BUTTON := "palette_save_library_button"
const PALETTE_LOAD_LIBRARY_BUTTON := "palette_load_library_button"
const PALETTE_MATCH_SELECTED_ASSET_BUTTON := "palette_match_selected_asset_button"
const PALETTE_ASSET_BUTTON_SIZE_SLIDER := "palette_asset_button_size_slider"
const PALETTE_SCROLL_CONTAINER := "palette_scroll_container"
const PALETTE_FILTER_LINE_EDIT := "palette_filter_line_edit"

const DYNPREV_CLOSE_BUTTON := "dynamic_preview_close_button"
const DYNPREV_UPDATE_BUTTON := "dynamic_preview_update_button"
const DYNPREV_VIEW := "dynamic_preview_view"

const NODE_PATH_SELECTOR_SET_SELECTED_BUTTON := "node_path_selector_set_selected_button"

static var ui_registry: Dictionary[String, NodePath] = {}  # path from base control


static func register(p_name: String, p_node: Node) -> void:
	ui_registry[p_name] = EditorInterface.get_base_control().get_path_to(p_node)


static func clear() -> void:
	ui_registry.clear()
