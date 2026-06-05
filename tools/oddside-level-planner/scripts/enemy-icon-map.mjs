/**
 * Per-enemy planner icons from game-icons.net (CC BY 3.0).
 * Add rows as [pawn id, author, icon-name]. New pawns without a row get a fallback from the pool.
 */
export const ENEMY_ICON_MAP = [
  ["eyeball", "lorc", "eyeball"],
  ["flying_imp", "lorc", "imp"],
  ["frog", "lorc", "frog"],
  ["shooting_goon", "delapouite", "revolver"],
];

export const BOSS_ICON_MAP = [
  ["bear", "delapouite", "bear-head"],
  ["fire_demon", "lorc", "fire-breath"],
  ["forest_demon", "lorc", "daemon-skull"],
  ["jim_and_jam", "lorc", "anvil"],
  ["salt_and_pepper", "lorc", "bubbling-flask"],
];

/** Used when a new pawn folder appears and is not listed above. */
const FALLBACK_ICON_POOL = [
  ["lorc", "monster-grasp"],
  ["lorc", "slime"],
  ["lorc", "bat"],
  ["lorc", "spider-face"],
  ["delapouite", "mummy-head"],
  ["lorc", "ghost"],
  ["lorc", "rat"],
  ["delapouite", "snake"],
];

const byId = new Map(
  [...ENEMY_ICON_MAP, ...BOSS_ICON_MAP].map(([id, author, name]) => [id, [author, name]]),
);

export function iconPathForPawn(id) {
  return `/icons/enemies/${id}.svg`;
}

export function iconSourceForPawn(id) {
  if (byId.has(id)) return byId.get(id);
  let hash = 0;
  for (let i = 0; i < id.length; i++) hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
  return FALLBACK_ICON_POOL[hash % FALLBACK_ICON_POOL.length];
}

export function allPawnIconIds() {
  return [...byId.keys()];
}
