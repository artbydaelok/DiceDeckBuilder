import type { GameCatalog, GridDirection, LevelPlan, PlanEntity } from "../types";
import { tileToWorld, TILE_WORLD_UNITS } from "../types";
import { RotationDial } from "./RotationDial";

interface Props {
  plan: LevelPlan;
  catalog: GameCatalog;
  entity: PlanEntity | null;
  onUpdatePlan: (plan: LevelPlan) => void;
  onUpdateEntity: (entity: PlanEntity) => void;
  onDeleteEntity: () => void;
  exportLines: string[];
}

function num(v: string, fallback: number): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function SizeFields({
  entity,
  onUpdateEntity,
}: {
  entity: PlanEntity;
  onUpdateEntity: (e: PlanEntity) => void;
}) {
  const size = entity.size ?? { width: 1, depth: 1 };
  return (
    <>
      <label>
        Width (tiles)
        <input
          type="number"
          min={1}
          value={size.width}
          onChange={(e) =>
            onUpdateEntity({
              ...entity,
              size: { ...size, width: Math.max(1, num(e.target.value, 1)) },
            })
          }
        />
      </label>
      <label>
        Depth (tiles)
        <input
          type="number"
          min={1}
          value={size.depth}
          onChange={(e) =>
            onUpdateEntity({
              ...entity,
              size: { ...size, depth: Math.max(1, num(e.target.value, 1)) },
            })
          }
        />
      </label>
    </>
  );
}

function EntityFields({
  entity,
  plan,
  catalog,
  onUpdateEntity,
}: {
  entity: PlanEntity;
  plan: LevelPlan;
  catalog: GameCatalog;
  onUpdateEntity: (e: PlanEntity) => void;
}) {
  const props = entity.props ?? {};
  const setProp = (key: string, value: unknown) =>
    onUpdateEntity({ ...entity, props: { ...props, [key]: value } });

  switch (entity.kind) {
    case "player_start":
      return (
        <label className="checkbox-row">
          <input
            type="checkbox"
            checked={!props.disabled}
            onChange={(e) => setProp("disabled", !e.target.checked)}
          />
          Active (not disabled)
        </label>
      );

    case "camera":
      return (
        <>
          <RotationDial
            label="Y rotation"
            value={Number(props.rotation_y_deg ?? 0)}
            step={5}
            onChange={(deg) => setProp("rotation_y_deg", deg)}
          />
          <label>
            Follow mode
            <select
              value={Number(props.follow_mode ?? 2)}
              onChange={(e) => setProp("follow_mode", Number(e.target.value))}
            >
              {catalog.phantomFollowModes.map((m) => (
                <option key={m.value} value={m.value}>
                  {m.label}
                </option>
              ))}
            </select>
          </label>
          <label>
            Look-at mode
            <select
              value={Number(props.look_at_mode ?? 0)}
              onChange={(e) => setProp("look_at_mode", Number(e.target.value))}
            >
              {catalog.phantomLookAtModes.map((m) => (
                <option key={m.value} value={m.value}>
                  {m.label}
                </option>
              ))}
            </select>
          </label>
          <label>
            Priority
            <input
              type="number"
              value={Number(props.priority ?? 10)}
              onChange={(e) => setProp("priority", Number(e.target.value))}
            />
          </label>
          <p className="meta">Cone on grid shows approximate view direction. Link from camera zones.</p>
        </>
      );

    case "camera_zone":
      return (
        <>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
          <label>
            Linked camera (entity id)
            <select
              value={entity.links?.camera_id ?? ""}
              onChange={(e) =>
                onUpdateEntity({
                  ...entity,
                  links: { ...entity.links, camera_id: e.target.value },
                })
              }
            >
              <option value="">— select camera —</option>
              {plan.entities
                .filter((e) => e.kind === "camera")
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.id} @ ({c.x},{c.z})
                  </option>
                ))}
            </select>
          </label>
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={!!props.is_default}
              onChange={(e) => setProp("is_default", e.target.checked)}
            />
            Default zone for this area
          </label>
        </>
      );

    case "dialogue_zone":
      return (
        <>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
          <label>
            Dialogue resource (.dialogue)
            <select
              value={String(props.dialogue_resource ?? "")}
              onChange={(e) => setProp("dialogue_resource", e.target.value)}
            >
              <option value="">— manual path —</option>
              {catalog.dialogues.map((d) => (
                <option key={d.id} value={d.path}>
                  {d.label}
                </option>
              ))}
            </select>
          </label>
          <label>
            Dialogue title / ID
            <input
              value={String(props.title_to_play ?? "start")}
              onChange={(e) => setProp("title_to_play", e.target.value)}
            />
          </label>
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={props.one_shot !== false}
              onChange={(e) => setProp("one_shot", e.target.checked)}
            />
            One shot (remove after)
          </label>
        </>
      );

    case "custom":
      return (
        <>
          <label>
            Label
            <input
              value={String(props.label ?? "")}
              onChange={(e) => setProp("label", e.target.value)}
            />
          </label>
          <label>
            Notes
            <textarea
              rows={3}
              value={String(props.notes ?? "")}
              onChange={(e) => setProp("notes", e.target.value)}
            />
          </label>
          <p className="meta warn">Placeholder only — not exported to Godot until you define a builder rule.</p>
        </>
      );

    case "enemy":
      return (
        <>
          <label>
            Max health
            <input
              type="number"
              min={1}
              value={Number(props.max_health ?? 2)}
              onChange={(e) => setProp("max_health", num(e.target.value, 2))}
            />
          </label>
          <label>
            Move speed
            <input
              type="number"
              min={0}
              step={0.5}
              value={Number(props.move_speed ?? 2)}
              onChange={(e) => setProp("move_speed", num(e.target.value, 2))}
            />
          </label>
          <h3>Grid mover</h3>
          <label>
            Preset
            <select
              value=""
              onChange={(e) => {
                const preset = catalog.gridMoverPresets.find((p) => p.id === e.target.value);
                if (preset) onUpdateEntity({ ...entity, grid_mover: { ...preset.config } });
              }}
            >
              <option value="">Apply preset…</option>
              {catalog.gridMoverPresets.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.label}
                </option>
              ))}
            </select>
          </label>
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={!!entity.grid_mover?.chase_player}
              onChange={(e) =>
                onUpdateEntity({
                  ...entity,
                  grid_mover: { ...entity.grid_mover, chase_player: e.target.checked },
                })
              }
            />
            Chase player
          </label>
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={!!entity.grid_mover?.ping_pong_pattern}
              onChange={(e) =>
                onUpdateEntity({
                  ...entity,
                  grid_mover: { ...entity.grid_mover, ping_pong_pattern: e.target.checked },
                })
              }
            />
            Ping-pong pattern
          </label>
          <label>
            Pattern (comma-separated: FORWARD, BACK, LEFT, RIGHT)
            <input
              value={(entity.grid_mover?.pattern ?? []).join(", ")}
              onChange={(e) => {
                const parts = e.target.value
                  .split(",")
                  .map((s) => s.trim().toUpperCase())
                  .filter((s): s is GridDirection =>
                    ["FORWARD", "BACK", "LEFT", "RIGHT"].includes(s),
                  );
                onUpdateEntity({
                  ...entity,
                  grid_mover: { ...entity.grid_mover, pattern: parts },
                });
              }}
            />
          </label>
          <label>
            Interval (sec)
            <input
              type="number"
              step={0.05}
              min={0}
              value={entity.grid_mover?.interval_time ?? 0.75}
              onChange={(e) =>
                onUpdateEntity({
                  ...entity,
                  grid_mover: {
                    ...entity.grid_mover,
                    interval_time: num(e.target.value, 0.75),
                  },
                })
              }
            />
          </label>
        </>
      );

    case "boss":
      return (
        <label>
          Max health
          <input
            type="number"
            min={1}
            value={Number(props.max_health ?? 100)}
            onChange={(e) => setProp("max_health", num(e.target.value, 100))}
          />
        </label>
      );

    case "deck_zone":
      return (
        <>
          <label>
            Deck resource
            <select
              value={String(props.deck ?? "")}
              onChange={(e) => setProp("deck", e.target.value)}
            >
              <option value="">— select —</option>
              {catalog.decks.map((d) => (
                <option key={d.id} value={d.path}>
                  {d.label}
                </option>
              ))}
            </select>
          </label>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
        </>
      );

    case "breakable":
      return (
        <>
          <label>
            Variant (scene)
            <select
              value={entity.scene ?? ""}
              onChange={(e) => onUpdateEntity({ ...entity, scene: e.target.value })}
            >
              {catalog.breakables.map((b) => (
                <option key={b.id} value={b.scene}>
                  {b.label}
                </option>
              ))}
            </select>
          </label>
          <label>
            object_id (unique per level)
            <input
              value={String(props.object_id ?? "")}
              onChange={(e) => setProp("object_id", e.target.value)}
            />
          </label>
          <label>
            Health (axe hits)
            <input
              type="number"
              min={1}
              value={Number(props.health ?? 1)}
              onChange={(e) => setProp("health", num(e.target.value, 1))}
            />
          </label>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
        </>
      );

    case "static_body":
      return (
        <>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={props.block_player !== false}
              onChange={(e) => setProp("block_player", e.target.checked)}
            />
            Blocks player
          </label>
          <label>
            Note (export doc)
            <input
              value={String(props.note ?? "")}
              onChange={(e) => setProp("note", e.target.value)}
            />
          </label>
        </>
      );

    case "moving_platform":
      return (
        <>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
          <p className="meta">
            Path ({entity.path?.length ?? 0} waypoints): green = start, red = end. Re-place with
            path tool or edit tiles below.
          </p>
          <label>
            Path waypoints (x,z per line)
            <textarea
              rows={4}
              value={(entity.path ?? []).map((p) => `${p.x},${p.z}`).join("\n")}
              onChange={(e) => {
                const path = e.target.value
                  .split("\n")
                  .map((line) => line.trim())
                  .filter(Boolean)
                  .map((line) => {
                    const [xs, zs] = line.split(",").map((s) => Number(s.trim()));
                    return { x: xs, z: zs };
                  })
                  .filter((p) => Number.isFinite(p.x) && Number.isFinite(p.z));
                onUpdateEntity({ ...entity, path, x: path[0]?.x ?? entity.x, z: path[0]?.z ?? entity.z });
              }}
            />
          </label>
          <label>
            Travel duration (s)
            <input
              type="number"
              step={0.1}
              value={Number(props.travel_duration ?? 2)}
              onChange={(e) => setProp("travel_duration", num(e.target.value, 2))}
            />
          </label>
          <label>
            Stop duration (s)
            <input
              type="number"
              step={0.1}
              value={Number(props.stop_duration ?? 1.5)}
              onChange={(e) => setProp("stop_duration", num(e.target.value, 1.5))}
            />
          </label>
          <label>
            Ease
            <select
              value={String(props.ease_type ?? "Sine")}
              onChange={(e) => setProp("ease_type", e.target.value)}
            >
              {["Linear", "Sine", "Bounce", "Spring"].map((o) => (
                <option key={o} value={o}>
                  {o}
                </option>
              ))}
            </select>
          </label>
          <label className="checkbox-row">
            <input
              type="checkbox"
              checked={props.autostart !== false}
              onChange={(e) => setProp("autostart", e.target.checked)}
            />
            Autostart
          </label>
        </>
      );

    case "checkpoint":
      return (
        <>
          <label>
            Checkpoint data (.tres)
            <select
              value={String(props.checkpoint_data ?? "")}
              onChange={(e) => {
                const cp = catalog.checkpoints.find((c) => c.path === e.target.value);
                onUpdateEntity({
                  ...entity,
                  props: {
                    ...props,
                    checkpoint_data: e.target.value,
                    checkpoint_name: cp?.checkpoint_name ?? cp?.label ?? props.checkpoint_name,
                  },
                  links: { checkpoint_data: e.target.value },
                });
              }}
            >
              <option value="">— new / manual —</option>
              {catalog.checkpoints.map((c) => (
                <option key={c.id} value={c.path}>
                  {c.label}
                </option>
              ))}
            </select>
          </label>
          <label>
            Display name
            <input
              value={String(props.checkpoint_name ?? "")}
              onChange={(e) => setProp("checkpoint_name", e.target.value)}
            />
          </label>
          <p className="meta">
            Spawn point and level path are auto-filled at runtime when the player touches the
            campfire. Assign camera_zone in Godot after export.
          </p>
        </>
      );

    case "editor_region":
      return (
        <>
          <SizeFields entity={entity} onUpdateEntity={onUpdateEntity} />
          <label>
            Section label
            <input
              value={String(props.label ?? "")}
              onChange={(e) => setProp("label", e.target.value)}
            />
          </label>
          <label>
            Color
            <input
              type="color"
              value={String(props.color ?? "#6c5ce7")}
              onChange={(e) => setProp("color", e.target.value)}
            />
          </label>
          <label>
            Notes
            <textarea
              rows={3}
              value={String(props.notes ?? "")}
              onChange={(e) => setProp("notes", e.target.value)}
            />
          </label>
          <p className="meta warn">Not exported to Godot — planning overlay only.</p>
        </>
      );

    default:
      return (
        <label>
          Props (JSON)
          <textarea
            rows={5}
            value={JSON.stringify(props, null, 2)}
            onBlur={(e) => {
              try {
                onUpdateEntity({ ...entity, props: JSON.parse(e.target.value) as Record<string, unknown> });
              } catch {
                /* keep */
              }
            }}
          />
        </label>
      );
  }
}

export function EntityInspector({
  plan,
  catalog,
  entity,
  onUpdatePlan,
  onUpdateEntity,
  onDeleteEntity,
  exportLines,
}: Props) {
  if (!entity) {
    const gameCount = plan.entities.filter((e) => !e.editor_only).length;
    const editorCount = plan.entities.filter((e) => e.editor_only).length;
    return (
      <aside className="inspector">
        <h2>Level</h2>
        <label>
          Name
          <input
            value={plan.level_name}
            onChange={(e) => onUpdatePlan({ ...plan, level_name: e.target.value })}
          />
        </label>
        <label>
          Scene path
          <input
            value={plan.scene_path}
            onChange={(e) => onUpdatePlan({ ...plan, scene_path: e.target.value })}
          />
        </label>
        <label>
          Grid width
          <input
            type="number"
            min={1}
            value={plan.grid.width}
            onChange={(e) => {
              const width = Math.max(1, num(e.target.value, 1));
              onUpdatePlan({
                ...plan,
                grid: { ...plan.grid, width },
                map_data: {
                  ...plan.map_data,
                  dimensions: [width * TILE_WORLD_UNITS, plan.grid.depth * TILE_WORLD_UNITS],
                },
              });
            }}
          />
        </label>
        <label>
          Grid depth
          <input
            type="number"
            min={1}
            value={plan.grid.depth}
            onChange={(e) => {
              const depth = Math.max(1, num(e.target.value, 1));
              onUpdatePlan({
                ...plan,
                grid: { ...plan.grid, depth },
                map_data: {
                  ...plan.map_data,
                  dimensions: [plan.grid.width * TILE_WORLD_UNITS, depth * TILE_WORLD_UNITS],
                },
              });
            }}
          />
        </label>
        <p className="meta">
          {gameCount} game entities · {editorCount} editor-only · {(plan.tiles ?? []).length}{" "}
          terrain tiles
        </p>
        <h3>Godot export preview</h3>
        <pre className="export-preview">{exportLines.join("\n") || "(empty)"}</pre>
      </aside>
    );
  }

  const world = tileToWorld(entity.x, entity.z);
  const fp = entity.size ?? { width: 1, depth: 1 };

  return (
    <aside className="inspector">
      <h2>{entity.kind}</h2>
      {entity.editor_only && <p className="meta warn">Editor only — excluded from game export</p>}
      <p className="meta">
        Tile ({entity.x}, {entity.z}) size {fp.width}×{fp.depth} → world origin ({world.x}, 0,{" "}
        {world.z})
      </p>
      <label>
        Anchor X (top-left tile)
        <input
          type="number"
          value={entity.x}
          onChange={(e) => onUpdateEntity({ ...entity, x: num(e.target.value, entity.x) })}
        />
      </label>
      <label>
        Anchor Z
        <input
          type="number"
          value={entity.z}
          onChange={(e) => onUpdateEntity({ ...entity, z: num(e.target.value, entity.z) })}
        />
      </label>
      <EntityFields entity={entity} plan={plan} catalog={catalog} onUpdateEntity={onUpdateEntity} />
      <button type="button" className="danger" onClick={onDeleteEntity}>
        Delete entity
      </button>
    </aside>
  );
}
