export const PLAN_VERSION = 2;
export const TILE_WORLD_UNITS = 2;

export type TileType = "floor" | "water" | "pit" | "deck_floor";

export type GridDirection = "FORWARD" | "BACK" | "LEFT" | "RIGHT";

export type EntityKind =
  | "enemy"
  | "boss"
  | "item_pickup"
  | "coin_pickup"
  | "deck_zone"
  | "checkpoint"
  | "moving_platform"
  | "water_block"
  | "lilypad"
  | "player_start"
  | "breakable"
  | "static_body"
  | "camera"
  | "camera_zone"
  | "dialogue_zone"
  | "custom"
  | "editor_region";

/** @deprecated plan v1 */
export type LegacyEntityKind = "debug_player_start";

export type PlacementMode = "point" | "rectangle" | "path";

export interface TileSize {
  width: number;
  depth: number;
}

export interface TileCoord {
  x: number;
  z: number;
}

export interface GridMoverConfig {
  pattern?: GridDirection[];
  ping_pong_pattern?: boolean;
  chase_player?: boolean;
  interval_time?: number;
  autostart?: boolean;
}

export interface PlanEntity {
  id: string;
  kind: EntityKind;
  /** Top-left tile for rectangles; center tile for 1×1 point entities. */
  x: number;
  z: number;
  scene?: string;
  size?: TileSize;
  /** Moving platform / future path followers — grid-aligned waypoints. */
  path?: TileCoord[];
  grid_mover?: GridMoverConfig;
  links?: {
    checkpoint_data?: string;
    editor_region?: string;
    /** camera_zone → planner camera entity id */
    camera_id?: string;
  };
  /** Excluded from game export (e.g. editor regions). */
  editor_only?: boolean;
  props?: Record<string, unknown>;
}

export interface GridTile {
  x: number;
  z: number;
  type: TileType;
}

export interface LevelPlan {
  version: typeof PLAN_VERSION;
  level_name: string;
  scene_path: string;
  grid: { width: number; depth: number };
  tiles?: GridTile[];
  entities: PlanEntity[];
  map_data?: {
    dimensions?: [number, number];
    map_top_left?: [number, number];
    pois?: { label: string; x: number; z: number }[];
  };
}

export interface CatalogEntry {
  id: string;
  label: string;
  scene: string;
  container: string;
  /** Planner-only sprite (game-icons.net). */
  icon?: string;
}

export interface BreakableEntry extends CatalogEntry {
  defaultHealth?: number;
}

export interface CheckpointEntry {
  id: string;
  label: string;
  path: string;
  checkpoint_name?: string;
}

export interface DeckEntry {
  id: string;
  label: string;
  path: string;
}

export interface DialogueEntry {
  id: string;
  label: string;
  path: string;
}

export interface EnumOption {
  value: number;
  label: string;
}

export interface PaletteItem {
  kind: EntityKind;
  label: string;
  icon?: string;
  container: string;
  placement: PlacementMode;
  scene?: string;
  pickSceneFrom?: "enemies" | "bosses" | "breakables";
  pickDeckFrom?: "decks";
  pickCheckpointFrom?: "checkpoints";
  defaultSize?: TileSize;
  defaultProps?: Record<string, unknown>;
  editorOnly?: boolean;
}

export interface GameCatalog {
  generatedAt: string;
  gameRoot: string;
  tileWorldUnits: number;
  palette: PaletteItem[];
  enemies: CatalogEntry[];
  bosses: CatalogEntry[];
  decks: DeckEntry[];
  breakables: BreakableEntry[];
  checkpoints: CheckpointEntry[];
  dialogues: DialogueEntry[];
  phantomFollowModes: EnumOption[];
  phantomLookAtModes: EnumOption[];
  tileTypes: TileType[];
  gridMoverPresets: { id: string; label: string; config: GridMoverConfig }[];
}

export function tileToWorld(x: number, z: number): { x: number; y: number; z: number } {
  return { x: x * TILE_WORLD_UNITS, y: 0, z: z * TILE_WORLD_UNITS };
}

export function entityFootprint(ent: PlanEntity): TileSize {
  return ent.size ?? { width: 1, depth: 1 };
}

export function rectTiles(x0: number, z0: number, x1: number, z1: number): { x: number; z: number; w: number; d: number } {
  const x = Math.min(x0, x1);
  const z = Math.min(z0, z1);
  return { x, z, w: Math.abs(x1 - x0) + 1, d: Math.abs(z1 - z0) + 1 };
}

export function newEntityId(): string {
  return `ent_${crypto.randomUUID().slice(0, 8)}`;
}

export function emptyPlan(): LevelPlan {
  return {
    version: PLAN_VERSION,
    level_name: "New Level",
    scene_path: "res://levels/new_level/new_level.tscn",
    grid: { width: 16, depth: 12 },
    tiles: [],
    entities: [],
    map_data: { dimensions: [32, 24] },
  };
}

export function placementForKind(catalog: GameCatalog, kind: EntityKind): PlacementMode {
  return catalog.palette.find((p) => p.kind === kind)?.placement ?? "point";
}
