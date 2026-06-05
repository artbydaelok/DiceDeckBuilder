import type { MouseEvent } from "react";
import { tilesOnLine } from "../paintUtils";
import { TERRAIN_ICONS } from "../iconManifest";
import type { GameCatalog, LevelPlan, TileCoord, TileType } from "../types";
import { GridEntityOverlay } from "./GridEntityOverlay";
import { GridSvgIcon } from "./GridSvgIcon";

const TILE_PX = 28;

const KIND_COLORS: Record<string, string> = {
  enemy: "#e74c3c",
  boss: "#9b59b6",
  deck_zone: "#3498db",
  breakable: "#8d6e63",
  static_body: "#636e72",
  moving_platform: "#e67e22",
  checkpoint: "#1abc9c",
  debug_player_start: "#2ecc71",
  editor_region: "#6c5ce7",
  item_pickup: "#27ae60",
  coin_pickup: "#f1c40f",
  water_block: "#0984e3",
};

const TILE_COLORS: Record<TileType, string> = {
  floor: "#2d3436",
  water: "#0984e3",
  pit: "#000000",
  deck_floor: "#6c5ce7",
};

interface Props {
  catalog: GameCatalog;
  plan: LevelPlan;
  selectedEntityId: string | null;
  activeKind: string;
  rectPreview: { x: number; z: number; w: number; d: number } | null;
  pathPreview: TileCoord[];
  pathPlatformSize: { width: number; depth: number };
  paintTileType: TileType | null;
  paintRectPreview: { x: number; z: number; w: number; d: number } | null;
  linePreview: { from: TileCoord; to: TileCoord } | null;
  showEditorRegions: boolean;
  onCellClick: (x: number, z: number, e: MouseEvent) => void;
  onCellMouseDown: (x: number, z: number) => void;
  onCellMouseUp: (x: number, z: number) => void;
  onCellMouseEnter: (x: number, z: number) => void;
  onRemoveAt: (x: number, z: number) => void;
}

function tileAt(tiles: LevelPlan["tiles"], x: number, z: number): TileType {
  return tiles?.find((t) => t.x === x && t.z === z)?.type ?? "floor";
}

export function GridCanvas({
  catalog,
  plan,
  selectedEntityId,
  activeKind,
  rectPreview,
  pathPreview,
  pathPlatformSize,
  paintTileType,
  paintRectPreview,
  linePreview,
  showEditorRegions,
  onCellClick,
  onCellMouseDown,
  onCellMouseUp,
  onCellMouseEnter,
  onRemoveAt,
}: Props) {
  const { width, depth } = plan.grid;
  const w = width * TILE_PX;
  const h = depth * TILE_PX;

  const visibleEntities = plan.entities.filter(
    (e) => showEditorRegions || !e.editor_only,
  );

  const overlays = visibleEntities.map((ent) => (
    <GridEntityOverlay
      key={ent.id}
      ent={ent}
      catalog={catalog}
      selected={ent.id === selectedEntityId}
    />
  ));

  if (paintRectPreview && paintTileType) {
    const c = TILE_COLORS[paintTileType];
    overlays.push(
      <g key="paint-rect-preview" pointerEvents="none">
        <rect
          x={paintRectPreview.x * TILE_PX}
          y={paintRectPreview.z * TILE_PX}
          width={paintRectPreview.w * TILE_PX - 1}
          height={paintRectPreview.d * TILE_PX - 1}
          fill={c}
          fillOpacity={0.45}
          stroke="#fdcb6e"
          strokeWidth={2}
        />
      </g>,
    );
  }

  if (linePreview && paintTileType) {
    const { from, to } = linePreview;
    const cells = tilesOnLine(from.x, from.z, to.x, to.z)
      .map((p) => `${p.x * TILE_PX + TILE_PX / 2},${p.z * TILE_PX + TILE_PX / 2}`)
      .join(" ");
    overlays.push(
      <polyline
        key="paint-line-preview"
        points={cells}
        fill="none"
        stroke={TILE_COLORS[paintTileType]}
        strokeWidth={TILE_PX - 4}
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity={0.7}
        pointerEvents="none"
      />,
    );
  }

  if (rectPreview) {
    const previewFill = KIND_COLORS[activeKind] ?? "#fdcb6e";
    overlays.push(
      <g key="rect-preview" pointerEvents="none">
        <rect
          x={rectPreview.x * TILE_PX}
          y={rectPreview.z * TILE_PX}
          width={rectPreview.w * TILE_PX - 1}
          height={rectPreview.d * TILE_PX - 1}
          fill={previewFill}
          fillOpacity={0.35}
          stroke="#fdcb6e"
          strokeWidth={2}
        />
        <text
          x={rectPreview.x * TILE_PX + (rectPreview.w * TILE_PX) / 2}
          y={rectPreview.z * TILE_PX + (rectPreview.d * TILE_PX) / 2}
          fill="#fff"
          fontSize={11}
          fontWeight="bold"
          textAnchor="middle"
          dominantBaseline="middle"
        >
          {rectPreview.w}×{rectPreview.d}
        </text>
      </g>,
    );
  }

  if (pathPreview.length >= 1) {
    const p0 = pathPreview[0];
    overlays.push(
      <g key="path-platform-preview" pointerEvents="none">
        <rect
          x={p0.x * TILE_PX}
          y={p0.z * TILE_PX}
          width={pathPlatformSize.width * TILE_PX - 1}
          height={pathPlatformSize.depth * TILE_PX - 1}
          fill={KIND_COLORS.moving_platform}
          fillOpacity={0.25}
          stroke="#e67e22"
          strokeWidth={1}
          strokeDasharray="4 2"
        />
        <text
          x={p0.x * TILE_PX + 4}
          y={p0.z * TILE_PX + 12}
          fill="#fdcb6e"
          fontSize={9}
        >
          {pathPlatformSize.width}×{pathPlatformSize.depth}
        </text>
      </g>,
    );
  }

  if (pathPreview.length >= 1) {
    overlays.push(
      <polyline
        key="path-preview-line"
        points={pathPreview
          .map((p) => `${p.x * TILE_PX + TILE_PX / 2},${p.z * TILE_PX + TILE_PX / 2}`)
          .join(" ")}
        fill="none"
        stroke="#fdcb6e"
        strokeWidth={2}
        strokeDasharray="4 2"
        pointerEvents="none"
      />,
    );
    for (const [i, p] of pathPreview.entries()) {
      overlays.push(
        <circle
          key={`path-prev-${i}`}
          cx={p.x * TILE_PX + TILE_PX / 2}
          cy={p.z * TILE_PX + TILE_PX / 2}
          r={5}
          fill="#fdcb6e"
          pointerEvents="none"
        />,
      );
    }
  }

  const cells = [];
  for (let z = 0; z < depth; z++) {
    for (let x = 0; x < width; x++) {
      const type = tileAt(plan.tiles, x, z);
      cells.push(
        <g
          key={`${x}-${z}`}
          transform={`translate(${x * TILE_PX}, ${z * TILE_PX})`}
          className="grid-cell"
          onMouseDown={() => onCellMouseDown(x, z)}
          onMouseUp={() => onCellMouseUp(x, z)}
          onMouseEnter={() => onCellMouseEnter(x, z)}
          onContextMenu={(ev) => {
            ev.preventDefault();
            onRemoveAt(x, z);
          }}
          onClick={(ev) => onCellClick(x, z, ev)}
        >
          <rect
            width={TILE_PX - 1}
            height={TILE_PX - 1}
            fill={TILE_COLORS[type]}
            stroke="#636e72"
            strokeWidth={0.5}
          />
          {type !== "floor" && TERRAIN_ICONS[type] && (
            <GridSvgIcon
              href={TERRAIN_ICONS[type]}
              x={3}
              y={3}
              size={TILE_PX - 8}
              opacity={0.35}
            />
          )}
        </g>,
      );
    }
  }

  return (
    <div
      className={`grid-wrap${rectPreview || paintRectPreview || paintTileType ? " is-drawing" : ""}`}
    >
      <p className="hint">−Z is forward in Godot. Path platforms: click waypoints, then Finish path.</p>
      <svg width={w + 40} height={h + 20} className="grid-svg">
        <defs>
          <pattern id="static-stripes" patternUnits="userSpaceOnUse" width="8" height="8">
            <path d="M0,8 L8,0" stroke="#4a5568" strokeWidth="2" />
          </pattern>
        </defs>
        <g transform="translate(20, 10)">
          {cells}
          {overlays}
        </g>
      </svg>
    </div>
  );
}
