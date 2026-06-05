import type { CatalogEntry, EntityKind, GameCatalog, TileType } from "./types";

/** Planner-only sprites from game-icons.net (CC BY 3.0) — not exported to Godot. */
export const ENTITY_ICONS: Partial<Record<EntityKind, string>> = {
  player_start: "/icons/player_start.svg",
  enemy: "/icons/enemy.svg",
  boss: "/icons/boss.svg",
  deck_zone: "/icons/deck_zone.svg",
  breakable: "/icons/breakable.svg",
  static_body: "/icons/static_body.svg",
  moving_platform: "/icons/moving_platform.svg",
  checkpoint: "/icons/checkpoint.svg",
  water_block: "/icons/water.svg",
  item_pickup: "/icons/item_pickup.svg",
  coin_pickup: "/icons/coin.svg",
  camera: "/icons/camera.svg",
  camera_zone: "/icons/camera_zone.svg",
  dialogue_zone: "/icons/dialogue_zone.svg",
  custom: "/icons/custom.svg",
  editor_region: "/icons/editor_region.svg",
};

export const TERRAIN_ICONS: Partial<Record<TileType, string>> = {
  floor: "/icons/floor.svg",
  water: "/icons/water.svg",
  pit: "/icons/pit.svg",
  deck_floor: "/icons/deck_hint.svg",
};

/** Enemy/boss id from a Godot scene path, e.g. `enemy_pawns/frog/...` → `frog`. */
export function pawnIdFromScene(scene?: string): string | null {
  if (!scene) return null;
  const m = scene.match(/enemy_pawns\/([^/]+)/) ?? scene.match(/(?:^|\/)boss\/([^/]+)/);
  return m?.[1] ?? null;
}

export function iconForCatalogEntry(entry: CatalogEntry): string {
  return entry.icon ?? `/icons/enemies/${entry.id}.svg`;
}

export function iconForEntity(
  kind: EntityKind,
  scene?: string,
  catalog?: GameCatalog,
): string {
  const pawnId = pawnIdFromScene(scene);
  if (pawnId && catalog) {
    const entry =
      catalog.enemies.find((e) => e.id === pawnId) ??
      catalog.bosses.find((b) => b.id === pawnId);
    if (entry) return iconForCatalogEntry(entry);
  }
  if (pawnId) return `/icons/enemies/${pawnId}.svg`;
  return ENTITY_ICONS[kind] ?? "/icons/custom.svg";
}
