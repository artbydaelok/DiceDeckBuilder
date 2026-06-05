import type { LevelPlan, PlanEntity } from "./types";
import { entityFootprint } from "./types";

export function cellInEntity(ent: PlanEntity, x: number, z: number): boolean {
  const { width: w, depth: d } = entityFootprint(ent);
  return x >= ent.x && x < ent.x + w && z >= ent.z && z < ent.z + d;
}

/** All entities covering a cell; last = drawn on top (most recently placed). */
export function entitiesAt(plan: LevelPlan, x: number, z: number): PlanEntity[] {
  return plan.entities.filter((ent) => cellInEntity(ent, x, z));
}

export function topEntityAt(plan: LevelPlan, x: number, z: number): PlanEntity | undefined {
  const list = entitiesAt(plan, x, z);
  return list.length ? list[list.length - 1] : undefined;
}

export function rectsOverlap(
  ax: number,
  az: number,
  aw: number,
  ad: number,
  bx: number,
  bz: number,
  bw: number,
  bd: number,
): boolean {
  return ax < bx + bw && ax + aw > bx && az < bz + bd && az + ad > bz;
}

export function entityIntersectsRect(
  ent: PlanEntity,
  x: number,
  z: number,
  w: number,
  d: number,
): boolean {
  const { width: ew, depth: ed } = entityFootprint(ent);
  return rectsOverlap(ent.x, ent.z, ew, ed, x, z, w, d);
}

export function idsIntersectingRect(plan: LevelPlan, x: number, z: number, w: number, d: number): string[] {
  return plan.entities.filter((e) => entityIntersectsRect(e, x, z, w, d)).map((e) => e.id);
}
