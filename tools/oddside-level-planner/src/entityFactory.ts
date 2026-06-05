import type {
  GameCatalog,
  GridMoverConfig,
  PlanEntity,
  TileCoord,
  TileSize,
  EntityKind,
} from "./types";
import { newEntityId } from "./types";

export interface PlaceContext {
  enemyId: string;
  bossId: string;
  deckId: string;
  breakableId: string;
  checkpointId: string;
  pathPoints?: TileCoord[];
}

export function createEntity(
  catalog: GameCatalog,
  kind: EntityKind,
  x: number,
  z: number,
  size: TileSize | undefined,
  ctx: PlaceContext,
): PlanEntity {
  const palette = catalog.palette.find((p) => p.kind === kind);
  let scene = palette?.scene;
  const props: Record<string, unknown> = { ...(palette?.defaultProps ?? {}) };
  const ent: PlanEntity = {
    id: newEntityId(),
    kind,
    x,
    z,
    scene,
    size: size ?? palette?.defaultSize ?? { width: 1, depth: 1 },
    props,
    editor_only: palette?.editorOnly ?? false,
  };

  if (palette?.pickSceneFrom === "enemies") {
    const e = catalog.enemies.find((en) => en.id === ctx.enemyId) ?? catalog.enemies[0];
    ent.scene = e?.scene;
    ent.props = { max_health: 2, move_speed: 2, ...props };
    ent.grid_mover = { pattern: [], chase_player: false, interval_time: 0.75, autostart: true };
  }
  if (palette?.pickSceneFrom === "bosses") {
    const b = catalog.bosses.find((bo) => bo.id === ctx.bossId) ?? catalog.bosses[0];
    ent.scene = b?.scene;
    ent.props = { max_health: 100, ...props };
  }
  if (palette?.pickDeckFrom === "decks") {
    const d = catalog.decks.find((de) => de.id === ctx.deckId) ?? catalog.decks[0];
    ent.props = { deck: d?.path ?? "", ...props };
    ent.size = size ?? { width: 1, depth: 1 };
  }
  if (palette?.pickSceneFrom === "breakables") {
    const b = catalog.breakables.find((br) => br.id === ctx.breakableId) ?? catalog.breakables[0];
    ent.scene = b?.scene;
    ent.props = {
      object_id: suggestObjectId(ctx.breakableId),
      health: b?.defaultHealth ?? 1,
      ...props,
    };
  }
  if (palette?.pickCheckpointFrom === "checkpoints") {
    const cp = catalog.checkpoints.find((c) => c.id === ctx.checkpointId) ?? catalog.checkpoints[0];
    if (cp) {
      ent.props = {
        checkpoint_name: cp.checkpoint_name ?? cp.label,
        checkpoint_data: cp.path,
        ...props,
      };
      ent.links = { checkpoint_data: cp.path };
    }
  }

  switch (kind) {
    case "player_start":
      ent.props = { disabled: false };
      ent.size = { width: 1, depth: 1 };
      break;
    case "static_body":
      ent.props = { block_player: true, note: "" };
      ent.size = size ?? { width: 1, depth: 1 };
      break;
    case "camera":
      ent.scene = "res://core/cameras/basic_phantom_camera.tscn";
      ent.props = {
        rotation_y_deg: 0,
        follow_mode: 2,
        look_at_mode: 0,
        priority: 10,
        follow_offset: [0, 8, 6],
        ...props,
      };
      ent.size = { width: 1, depth: 1 };
      break;
    case "camera_zone":
      ent.scene = "res://level_mechanics/camera_angle_change/camera_zone.tscn";
      ent.props = { is_default: false, ...props };
      ent.links = { camera_id: "" };
      ent.size = size ?? { width: 1, depth: 1 };
      break;
    case "dialogue_zone":
      ent.scene = "res://core/components/cutscene/dialogue_trigger_area.tscn";
      ent.props = {
        dialogue_resource: "",
        title_to_play: "start",
        one_shot: false,
        disables_player_movement: true,
        ...props,
      };
      ent.size = size ?? { width: 1, depth: 1 };
      break;
    case "custom":
      ent.props = { label: "Custom", notes: "", ...props };
      ent.size = size ?? { width: 1, depth: 1 };
      break;
    case "moving_platform": {
      const path = ctx.pathPoints?.length
        ? ctx.pathPoints
        : [
            { x, z },
            { x, z: z + Math.max(2, (ent.size?.depth ?? 1) - 1) },
          ];
      ent.path = path;
      ent.props = {
        travel_duration: 2,
        stop_duration: 1.5,
        ease_type: "Sine",
        autostart: true,
        ...props,
      };
      break;
    }
    case "editor_region":
      ent.editor_only = true;
      ent.size = size ?? { width: 1, depth: 1 };
      ent.props = { label: "Section", color: "#6c5ce7", notes: "", ...props };
      break;
    default:
      break;
  }

  return ent;
}

function suggestObjectId(breakableId: string): string {
  const base = breakableId.replace(/[^a-z0-9_]/gi, "_").toLowerCase();
  return `${base}_${Math.random().toString(36).slice(2, 6)}`;
}

export function applyGridMoverPreset(
  ent: PlanEntity,
  preset: GridMoverConfig | undefined,
): PlanEntity {
  if (!preset || ent.kind !== "enemy") return ent;
  return { ...ent, grid_mover: { ...preset } };
}
