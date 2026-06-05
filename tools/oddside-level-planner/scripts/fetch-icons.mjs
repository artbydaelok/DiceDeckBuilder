/**
 * Downloads CC BY 3.0 icons from https://github.com/game-icons/icons
 * Run: npm run icons
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { iconSourceForPawn } from "./enemy-icon-map.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const GAME_ROOT = path.resolve(__dirname, "../../..");
const OUT = path.join(__dirname, "../public/icons");
const ENEMY_OUT = path.join(OUT, "enemies");
const BASE = "https://raw.githubusercontent.com/game-icons/icons/master";

async function downloadSvg(outFile, author, name) {
  const url = `${BASE}/${author}/${name}.svg`;
  const res = await fetch(url);
  if (!res.ok) {
    console.warn(`Skip ${path.basename(outFile)}: ${res.status} ${url}`);
    return false;
  }
  fs.writeFileSync(outFile, await res.text());
  console.log(`OK ${path.relative(OUT, outFile)}`);
  return true;
}

function listPawnIds(subdir) {
  const root = path.join(GAME_ROOT, "enemy", subdir);
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name);
}

/** [filename, author, icon-name] */
const ICONS = [
  ["player_start.svg", "delapouite", "perspective-dice-six-faces-random"],
  ["enemy.svg", "lorc", "frog"],
  ["boss.svg", "lorc", "daemon-skull"],
  ["deck_zone.svg", "delapouite", "card-joker"],
  ["breakable.svg", "delapouite", "half-log"],
  ["static_body.svg", "delapouite", "brick-wall"],
  ["moving_platform.svg", "delapouite", "floating-platforms"],
  ["checkpoint.svg", "lorc", "campfire"],
  ["water.svg", "sbed", "water-drop"],
  ["floor.svg", "delapouite", "domino-tiles"],
  ["pit.svg", "delapouite", "well"],
  ["deck_hint.svg", "delapouite", "card-exchange"],
  ["camera.svg", "delapouite", "cctv-camera"],
  ["camera_zone.svg", "lorc", "bordered-shield"],
  ["dialogue_zone.svg", "delapouite", "chat-bubble"],
  ["custom.svg", "lorc", "gear-hammer"],
  ["coin.svg", "delapouite", "coins"],
  ["item_pickup.svg", "delapouite", "backpack"],
  ["editor_region.svg", "lorc", "mesh-ball"],
];

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(ENEMY_OUT, { recursive: true });

for (const [file, author, name] of ICONS) {
  await downloadSvg(path.join(OUT, file), author, name);
}

const pawnIds = [...new Set([...listPawnIds("enemy_pawns"), ...listPawnIds("boss")])];
for (const id of pawnIds) {
  const [author, name] = iconSourceForPawn(id);
  await downloadSvg(path.join(ENEMY_OUT, `${id}.svg`), author, name);
}

console.log(`Icons in ${OUT}`);
