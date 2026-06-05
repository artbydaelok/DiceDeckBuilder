/**
 * Scans the Oddside Godot project and writes public/catalog.json for the planner UI.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { iconPathForPawn } from "./enemy-icon-map.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const GAME_ROOT = path.resolve(__dirname, "../../..");
const OUT = path.join(__dirname, "../public/catalog.json");

function toResPath(absPath) {
  const rel = path.relative(GAME_ROOT, absPath).replaceAll("\\", "/");
  return `res://${rel}`;
}

function findTscnInDir(dir) {
  if (!fs.existsSync(dir)) return null;
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".tscn")).sort();
  return files[0] ? path.join(dir, files[0]) : null;
}

function listPawnEnemies() {
  const root = path.join(GAME_ROOT, "enemy/enemy_pawns");
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root, { withFileTypes: true }).flatMap((ent) => {
    if (!ent.isDirectory()) return [];
    const tscn = findTscnInDir(path.join(root, ent.name));
    if (!tscn) return [];
    return [
      {
        id: ent.name,
        label: ent.name.replaceAll("_", " "),
        scene: toResPath(tscn),
        container: "Enemies",
        icon: iconPathForPawn(ent.name),
      },
    ];
  });
}

function listBosses() {
  const root = path.join(GAME_ROOT, "enemy/boss");
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root, { withFileTypes: true }).flatMap((ent) => {
    if (!ent.isDirectory()) return [];
    const tscn = findTscnInDir(path.join(root, ent.name));
    if (!tscn) return [];
    return [
      {
        id: ent.name,
        label: `Boss: ${ent.name}`,
        scene: toResPath(tscn),
        container: "Enemies",
        icon: iconPathForPawn(ent.name),
      },
    ];
  });
}

function listDecks() {
  const root = path.join(GAME_ROOT, "card/decks");
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root).filter((f) => f.endsWith(".tres")).map((f) => ({
    id: f.replace(".tres", ""),
    label: f,
    path: toResPath(path.join(root, f)),
  }));
}

function listBreakables() {
  return [
    {
      id: "log",
      label: "Breakable log",
      scene: "res://level_mechanics/breakable_log.tscn",
      container: "Gameplay",
      defaultHealth: 1,
    },
    {
      id: "component",
      label: "Breakable (component scene)",
      scene: "res://level_mechanics/breakable_component.tscn",
      container: "Gameplay",
      defaultHealth: 1,
    },
  ];
}

function listCheckpoints() {
  const root = path.join(GAME_ROOT, "core/checkpoint_system/checkpoints");
  if (!fs.existsSync(root)) return [];
  return fs
    .readdirSync(root)
    .filter((f) => f.endsWith(".tres"))
    .map((f) => {
      const full = path.join(root, f);
      const id = f.replace(".tres", "");
      let checkpoint_name = id;
      try {
        const text = fs.readFileSync(full, "utf8");
        const m = text.match(/checkpoint_name\s*=\s*"([^"]+)"/);
        if (m) checkpoint_name = m[1];
      } catch {
        /* ignore */
      }
      return {
        id,
        label: checkpoint_name,
        path: toResPath(full),
        checkpoint_name,
      };
    });
}

function listDialogues() {
  const root = path.join(GAME_ROOT, "dialogue");
  if (!fs.existsSync(root)) return [];
  return fs
    .readdirSync(root)
    .filter((f) => f.endsWith(".dialogue"))
    .map((f) => ({
      id: f.replace(".dialogue", ""),
      label: f,
      path: toResPath(path.join(root, f)),
    }));
}

const palette = [
  {
    kind: "player_start",
    label: "Player start",
    icon: "/icons/player_start.svg",
    container: "BaseLevel",
    placement: "point",
    scene: "res://level_mechanics/debug_player_start.tscn",
    defaultProps: { disabled: false },
  },
  {
    kind: "enemy",
    label: "Enemy (pawn)",
    icon: "/icons/enemy.svg",
    container: "Enemies",
    placement: "point",
    pickSceneFrom: "enemies",
    defaultProps: { max_health: 2, move_speed: 2 },
  },
  {
    kind: "boss",
    label: "Boss",
    icon: "/icons/boss.svg",
    container: "Enemies",
    placement: "point",
    pickSceneFrom: "bosses",
    defaultProps: { max_health: 100 },
  },
  {
    kind: "deck_zone",
    label: "Deck zone",
    icon: "/icons/deck_zone.svg",
    container: "Gameplay",
    placement: "rectangle",
    scene: "res://level_mechanics/deck_zone.tscn",
    pickDeckFrom: "decks",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: {},
  },
  {
    kind: "breakable",
    label: "Breakable",
    icon: "/icons/breakable.svg",
    container: "Gameplay",
    placement: "rectangle",
    pickSceneFrom: "breakables",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { health: 1 },
  },
  {
    kind: "static_body",
    label: "Static body (blocker)",
    icon: "/icons/static_body.svg",
    container: "Environment",
    placement: "rectangle",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { block_player: true },
  },
  {
    kind: "moving_platform",
    label: "Moving platform",
    icon: "/icons/moving_platform.svg",
    container: "Gameplay",
    placement: "path",
    scene: "res://core/vehicles/moving_platform.tscn",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { travel_duration: 2, stop_duration: 1.5, ease_type: "Sine", autostart: true },
  },
  {
    kind: "checkpoint",
    label: "Checkpoint",
    icon: "/icons/checkpoint.svg",
    container: "Gameplay",
    placement: "point",
    scene: "res://core/checkpoint_system/checkpoint.tscn",
    pickCheckpointFrom: "checkpoints",
    defaultProps: {},
  },
  {
    kind: "camera",
    label: "Phantom camera",
    icon: "/icons/camera.svg",
    container: "BaseLevel/Cameras",
    placement: "point",
    scene: "res://core/cameras/basic_phantom_camera.tscn",
    defaultProps: { rotation_y_deg: 0, follow_mode: 2, look_at_mode: 0, priority: 10 },
  },
  {
    kind: "camera_zone",
    label: "Camera zone",
    icon: "/icons/camera_zone.svg",
    container: "BaseLevel/Cameras",
    placement: "rectangle",
    scene: "res://level_mechanics/camera_angle_change/camera_zone.tscn",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { is_default: false },
  },
  {
    kind: "dialogue_zone",
    label: "Dialogue zone",
    icon: "/icons/dialogue_zone.svg",
    container: "Gameplay",
    placement: "rectangle",
    scene: "res://core/components/cutscene/dialogue_trigger_area.tscn",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { title_to_play: "start", one_shot: false },
  },
  {
    kind: "custom",
    label: "Custom element",
    icon: "/icons/custom.svg",
    container: "Gameplay",
    placement: "point",
    defaultProps: { label: "Custom", notes: "" },
  },
  {
    kind: "editor_region",
    label: "Editor region (not exported)",
    icon: "/icons/editor_region.svg",
    container: "—",
    placement: "rectangle",
    editorOnly: true,
    defaultSize: { width: 1, depth: 1 },
    defaultProps: { label: "Section", color: "#6c5ce7", notes: "" },
  },
  {
    kind: "item_pickup",
    label: "Item pickup",
    icon: "/icons/item_pickup.svg",
    container: "Gameplay",
    placement: "point",
    scene: "res://level_mechanics/item_pickup.tscn",
    defaultProps: { item_data: "" },
  },
  {
    kind: "coin_pickup",
    label: "Coin pickup",
    icon: "/icons/coin.svg",
    container: "Gameplay",
    placement: "point",
    scene: "res://level_mechanics/coin_pickup.tscn",
    defaultProps: {},
  },
  {
    kind: "water_block",
    label: "Water block",
    icon: "/icons/water.svg",
    container: "Environment",
    placement: "rectangle",
    scene: "res://level_mechanics/water_block.tscn",
    defaultSize: { width: 1, depth: 1 },
    defaultProps: {},
  },
];

const gridMoverPresets = [
  { id: "none", label: "No pattern (manual / default scene)", config: { pattern: [], autostart: false } },
  {
    id: "patrol_back_3",
    label: "Patrol 3 back",
    config: { pattern: ["BACK", "BACK", "BACK"], interval_time: 0.75, autostart: true },
  },
  {
    id: "square",
    label: "Square loop",
    config: {
      pattern: ["BACK", "RIGHT", "FORWARD", "LEFT"],
      interval_time: 0.75,
      autostart: true,
    },
  },
  {
    id: "ping_pong",
    label: "Ping-pong line",
    config: {
      pattern: ["BACK", "BACK", "BACK"],
      ping_pong_pattern: true,
      interval_time: 0.75,
      autostart: true,
    },
  },
  {
    id: "chase",
    label: "Chase player",
    config: { pattern: [], chase_player: true, interval_time: 0.75, autostart: true },
  },
];

const catalog = {
  generatedAt: new Date().toISOString(),
  gameRoot: GAME_ROOT,
  tileWorldUnits: 2,
  palette,
  enemies: listPawnEnemies(),
  bosses: listBosses(),
  decks: listDecks(),
  breakables: listBreakables(),
  checkpoints: listCheckpoints(),
  dialogues: listDialogues(),
  phantomFollowModes: [
    { value: 0, label: "NONE" },
    { value: 1, label: "GLUED" },
    { value: 2, label: "SIMPLE" },
    { value: 3, label: "GROUP" },
    { value: 4, label: "PATH" },
    { value: 5, label: "FRAMED" },
    { value: 6, label: "THIRD_PERSON" },
  ],
  phantomLookAtModes: [
    { value: 0, label: "NONE" },
    { value: 1, label: "MIMIC" },
    { value: 2, label: "SIMPLE" },
    { value: 3, label: "GROUP" },
  ],
  gridMoverPresets,
  tileTypes: ["floor", "water", "pit", "deck_floor"],
};

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(catalog, null, 2));
console.log(`Wrote ${OUT}`);
console.log(
  `  ${catalog.enemies.length} enemies, ${catalog.breakables.length} breakables, ${catalog.checkpoints.length} checkpoints`,
);
