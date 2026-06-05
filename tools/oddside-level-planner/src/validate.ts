import Ajv from "ajv";
import addFormats from "ajv-formats";
import schemaJson from "../schema/level-plan.schema.json";
import type { LevelPlan, PlanEntity } from "./types";
import { entityFootprint, TILE_WORLD_UNITS } from "./types";

const { $schema: _s, $id: _i, ...levelPlanSchema } = schemaJson as Record<string, unknown>;

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
const validateSchema = ajv.compile(levelPlanSchema);

export interface ValidationIssue {
  path: string;
  message: string;
}

function inGrid(plan: LevelPlan, x: number, z: number, w = 1, d = 1): boolean {
  return x >= 0 && z >= 0 && x + w <= plan.grid.width && z + d <= plan.grid.depth;
}

function entityBounds(ent: PlanEntity): { x: number; z: number; w: number; d: number } {
  const { width: w, depth: d } = entityFootprint(ent);
  return { x: ent.x, z: ent.z, w, d };
}

export function validatePlan(plan: LevelPlan): ValidationIssue[] {
  const issues: ValidationIssue[] = [];

  if (!validateSchema(plan)) {
    for (const err of validateSchema.errors ?? []) {
      issues.push({
        path: err.instancePath || "/",
        message: err.message ?? "Invalid",
      });
    }
  }

  const objectIds = new Map<string, string>();

  for (const tile of plan.tiles ?? []) {
    if (!inGrid(plan, tile.x, tile.z)) {
      issues.push({
        path: `/tiles/${tile.x},${tile.z}`,
        message: `Tile outside grid ${plan.grid.width}×${plan.grid.depth}`,
      });
    }
  }

  const playerStarts = plan.entities.filter((e) => e.kind === "player_start");
  if (playerStarts.length > 1) {
    issues.push({ path: "/entities", message: "Only one player start per level" });
  }

  const cameraIds = new Set(
    plan.entities.filter((e) => e.kind === "camera").map((e) => e.id),
  );
  for (const ent of plan.entities.filter((e) => e.kind === "camera_zone")) {
    const camId = ent.links?.camera_id;
    if (!camId) {
      issues.push({
        path: `/entities/${ent.id}`,
        message: "Camera zone must link to a camera entity id",
      });
    } else if (!cameraIds.has(camId)) {
      issues.push({
        path: `/entities/${ent.id}`,
        message: `Camera zone links to missing camera "${camId}"`,
      });
    }
  }

  const bosses = plan.entities.filter((e) => e.kind === "boss" && !e.editor_only);
  if (bosses.length > 1) {
    issues.push({ path: "/entities", message: `More than one boss (${bosses.length})` });
  }

  for (const ent of plan.entities) {
    const { x, z, w, d } = entityBounds(ent);
    if (!inGrid(plan, x, z, w, d)) {
      issues.push({
        path: `/entities/${ent.id}`,
        message: `Footprint ${w}×${d} at (${x},${z}) exceeds grid`,
      });
    }

    if (ent.kind === "breakable") {
      const oid = String(ent.props?.object_id ?? "");
      if (!oid) {
        issues.push({ path: `/entities/${ent.id}`, message: "Breakable requires object_id" });
      } else if (objectIds.has(oid)) {
        issues.push({
          path: `/entities/${ent.id}`,
          message: `Duplicate object_id "${oid}" (also on ${objectIds.get(oid)})`,
        });
      } else {
        objectIds.set(oid, ent.id);
      }
    }

    if (ent.kind === "deck_zone") {
      if (!ent.props?.deck) {
        issues.push({ path: `/entities/${ent.id}`, message: "Deck zone requires deck resource path" });
      }
      if (!ent.size || ent.size.width < 1 || ent.size.depth < 1) {
        issues.push({ path: `/entities/${ent.id}`, message: "Deck zone needs size (tiles)" });
      }
    }

    if (ent.kind === "moving_platform") {
      if (!ent.path || ent.path.length < 2) {
        issues.push({
          path: `/entities/${ent.id}`,
          message: "Moving platform needs path with at least 2 waypoints",
        });
      }
      for (const p of ent.path ?? []) {
        if (p.x % 1 !== 0 || p.z % 1 !== 0) {
          issues.push({ path: `/entities/${ent.id}`, message: "Path waypoints must be integer tiles" });
        }
      }
    }

    if (ent.kind === "checkpoint" && !ent.props?.checkpoint_data && !ent.props?.checkpoint_name) {
      issues.push({
        path: `/entities/${ent.id}`,
        message: "Checkpoint needs checkpoint_data path or checkpoint_name",
      });
    }

    if (ent.kind === "editor_region" && !String(ent.props?.label ?? "").trim()) {
      issues.push({ path: `/entities/${ent.id}`, message: "Editor region needs a label" });
    }
  }

  if (plan.map_data?.dimensions) {
    const [mw, md] = plan.map_data.dimensions;
    const ew = plan.grid.width * TILE_WORLD_UNITS;
    const ed = plan.grid.depth * TILE_WORLD_UNITS;
    if (mw !== ew || md !== ed) {
      issues.push({
        path: "/map_data/dimensions",
        message: `Expected [${ew}, ${ed}] from grid × ${TILE_WORLD_UNITS}`,
      });
    }
  }

  return issues;
}
