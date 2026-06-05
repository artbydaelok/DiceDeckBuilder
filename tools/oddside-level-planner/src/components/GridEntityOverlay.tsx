import type { GameCatalog, PlanEntity } from "../types";
import { entityFootprint } from "../types";
import { iconForEntity } from "../iconManifest";
import { GridSvgIcon } from "./GridSvgIcon";

const TILE_PX = 28;

const KIND_TINT: Record<string, string> = {
  enemy: "#e74c3c",
  boss: "#9b59b6",
  deck_zone: "#3498db",
  breakable: "#8d6e63",
  static_body: "#636e72",
  moving_platform: "#e67e22",
  checkpoint: "#1abc9c",
  player_start: "#2ecc71",
  camera: "#f39c12",
  camera_zone: "#e1b12c",
  dialogue_zone: "#9b59b6",
  custom: "#95a5a6",
  editor_region: "#6c5ce7",
};

function cameraConePath(cx: number, cy: number, yawDeg: number, len: number, spread = 28): string {
  const rad = (yawDeg * Math.PI) / 180;
  const fx = Math.sin(rad);
  const fz = -Math.cos(rad);
  const half = (spread * Math.PI) / 180 / 2;
  const a1 = Math.atan2(fz, fx) - half;
  const a2 = Math.atan2(fz, fx) + half;
  const x1 = cx + Math.cos(a1) * len;
  const y1 = cy + Math.sin(a1) * len;
  const x2 = cx + Math.cos(a2) * len;
  const y2 = cy + Math.sin(a2) * len;
  return `M ${cx} ${cy} L ${x1} ${y1} L ${x2} ${y2} Z`;
}

interface Props {
  ent: PlanEntity;
  catalog: GameCatalog;
  selected: boolean;
}

export function GridEntityOverlay({ ent, catalog, selected }: Props) {
  const { width: ew, depth: ed } = entityFootprint(ent);
  const tint = KIND_TINT[ent.kind] ?? "#aaa";
  const px = ent.x * TILE_PX;
  const py = ent.z * TILE_PX;
  const pw = ew * TILE_PX - 1;
  const ph = ed * TILE_PX - 1;
  const cx = px + pw / 2;
  const cy = py + ph / 2;
  const icon = iconForEntity(ent.kind, ent.scene, catalog);
  const iconSize = Math.min(TILE_PX * 1.4, Math.min(pw, ph) * 0.55);
  const label =
    ent.kind === "breakable"
      ? String(ent.props?.object_id ?? "")
      : ent.kind === "editor_region" || ent.kind === "custom"
        ? String(ent.props?.label ?? "")
        : ent.kind === "camera_zone"
          ? ent.links?.camera_id
            ? `→ ${ent.links.camera_id}`
            : "no cam"
          : ent.kind === "dialogue_zone"
            ? String(ent.props?.title_to_play ?? "start")
            : ent.kind === "camera"
              ? `F${Number(ent.props?.follow_mode ?? 2)} L${Number(ent.props?.look_at_mode ?? 0)}`
              : "";

  const yaw = Number(ent.props?.rotation_y_deg ?? 0);
  const isStatic = ent.kind === "static_body";
  const isCamera = ent.kind === "camera";

  return (
    <g key={`ov-${ent.id}`} pointerEvents="none">
      {isStatic && (
        <rect
          x={px}
          y={py}
          width={pw}
          height={ph}
          fill="url(#static-stripes)"
          fillOpacity={0.85}
          stroke={selected ? "#fff" : tint}
          strokeWidth={selected ? 2 : 1}
        />
      )}
      {!isStatic && (
        <rect
          x={px}
          y={py}
          width={pw}
          height={ph}
          fill={tint}
          fillOpacity={ent.editor_only ? 0.15 : 0.32}
          stroke={selected ? "#fff" : tint}
          strokeWidth={selected ? 2 : 1}
          strokeDasharray={ent.editor_only ? "4 2" : undefined}
        />
      )}
      {isCamera && (
        <path
          d={cameraConePath(cx, cy, yaw, Math.min(pw, ph) * 0.9)}
          fill={tint}
          fillOpacity={0.5}
          stroke="#fff"
          strokeWidth={1}
        />
      )}
      <GridSvgIcon
        href={icon}
        x={cx - iconSize / 2}
        y={cy - iconSize / 2}
        size={iconSize}
      />
      {ent.path && ent.path.length >= 2 && (
        <polyline
          points={ent.path.map((p) => `${p.x * TILE_PX + TILE_PX / 2},${p.z * TILE_PX + TILE_PX / 2}`).join(" ")}
          fill="none"
          stroke="#f39c12"
          strokeWidth={2}
        />
      )}
      {label && (
        <text x={px + 2} y={py + ph - 3} fill="#fff" fontSize={8} opacity={0.95}>
          {label.length > 16 ? `${label.slice(0, 14)}…` : label}
        </text>
      )}
    </g>
  );
}
