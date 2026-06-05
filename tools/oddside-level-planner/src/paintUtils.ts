import type { GridTile, LevelPlan, TileCoord, TileType } from "./types";
import { rectTiles } from "./types";

export function tilesInRect(x0: number, z0: number, x1: number, z1: number): TileCoord[] {
  const { x, z, w, d } = rectTiles(x0, z0, x1, z1);
  const out: TileCoord[] = [];
  for (let tz = z; tz < z + d; tz++) {
    for (let tx = x; tx < x + w; tx++) {
      out.push({ x: tx, z: tz });
    }
  }
  return out;
}

export function tilesOnLine(x0: number, z0: number, x1: number, z1: number): TileCoord[] {
  const out: TileCoord[] = [];
  let x = x0;
  let z = z0;
  const dx = Math.abs(x1 - x0);
  const dz = Math.abs(z1 - z0);
  const sx = x0 < x1 ? 1 : -1;
  const sz = z0 < z1 ? 1 : -1;
  let err = dx - dz;

  while (true) {
    out.push({ x, z });
    if (x === x1 && z === z1) break;
    const e2 = 2 * err;
    if (e2 > -dz) {
      err -= dz;
      x += sx;
    }
    if (e2 < dx) {
      err += dx;
      z += sz;
    }
  }
  return out;
}

function tileTypeAt(plan: LevelPlan, x: number, z: number): TileType {
  return plan.tiles?.find((t) => t.x === x && t.z === z)?.type ?? "floor";
}

export function applyPaint(
  plan: LevelPlan,
  cells: TileCoord[],
  type: TileType,
): { tiles: GridTile[] } {
  const key = (c: TileCoord) => `${c.x},${c.z}`;
  const map = new Map<string, TileType>();
  for (const t of plan.tiles ?? []) {
    map.set(key(t), t.type);
  }
  for (const c of cells) {
    if (c.x < 0 || c.z < 0 || c.x >= plan.grid.width || c.z >= plan.grid.depth) continue;
    if (type === "floor") {
      map.delete(key(c));
    } else {
      map.set(key(c), type);
    }
  }
  const tiles: GridTile[] = [];
  for (const [k, tileType] of map) {
    const [xs, zs] = k.split(",");
    tiles.push({ x: Number(xs), z: Number(zs), type: tileType });
  }
  return { tiles };
}

/** Flood fill from (x,z), replacing cells matching `matchType`. */
export function floodFillTiles(
  plan: LevelPlan,
  x: number,
  z: number,
  paintType: TileType,
): TileCoord[] {
  if (x < 0 || z < 0 || x >= plan.grid.width || z >= plan.grid.depth) return [];
  const matchType = tileTypeAt(plan, x, z);
  if (matchType === paintType) return [];

  const filled: TileCoord[] = [];
  const seen = new Set<string>();
  const queue: TileCoord[] = [{ x, z }];
  const key = (c: TileCoord) => `${c.x},${c.z}`;

  while (queue.length) {
    const c = queue.shift()!;
    const k = key(c);
    if (seen.has(k)) continue;
    if (c.x < 0 || c.z < 0 || c.x >= plan.grid.width || c.z >= plan.grid.depth) continue;
    if (tileTypeAt(plan, c.x, c.z) !== matchType) continue;
    seen.add(k);
    filled.push(c);
    queue.push({ x: c.x + 1, z: c.z }, { x: c.x - 1, z: c.z }, { x: c.x, z: c.z + 1 }, { x: c.x, z: c.z - 1 });
  }
  return filled;
}
