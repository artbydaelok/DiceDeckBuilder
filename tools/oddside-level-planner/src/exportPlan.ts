import type { LevelPlan, PlanEntity } from "./types";
import { PLAN_VERSION } from "./types";

/** Plan JSON for the Godot builder — strips editor-only entities. */
export function planForGameExport(plan: LevelPlan): LevelPlan {
  return {
    ...plan,
    version: PLAN_VERSION,
    entities: plan.entities.filter((e) => !e.editor_only && e.kind !== "custom"),
  };
}

export function exportEntitySummary(ent: PlanEntity): string[] {
  const lines: string[] = [`${ent.kind} (${ent.id}) @ tile (${ent.x}, ${ent.z})`];
  if (ent.size && (ent.size.width > 1 || ent.size.depth > 1)) {
    lines.push(`  size: ${ent.size.width}×${ent.size.depth} tiles`);
  }
  if (ent.path?.length) {
    lines.push(`  path: ${ent.path.map((p) => `(${p.x},${p.z})`).join(" → ")}`);
  }
  if (ent.grid_mover?.pattern?.length) {
    lines.push(`  grid_mover: ${ent.grid_mover.pattern.join(", ")}`);
  }
  if (ent.props?.object_id) lines.push(`  object_id: ${ent.props.object_id}`);
  if (ent.props?.deck) lines.push(`  deck: ${ent.props.deck}`);
  if (ent.editor_only) lines.push("  (editor only — not exported to Godot)");
  return lines;
}
