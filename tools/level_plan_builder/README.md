# Level plan builder (Phase 2)

Godot script/plugin that will:

1. Duplicate `res://levels/game_scene.tscn` to `plan.scene_path`
2. Set `level_name` and `current_map_data` from the plan
3. Instance each `entities[]` entry under `BaseLevel/<container>` at `(x*2, y, z*2)`
4. Preserve existing `uid://` headers on template resources

Until that exists, use the web planner for layout and place tuned props in the editor as today.
