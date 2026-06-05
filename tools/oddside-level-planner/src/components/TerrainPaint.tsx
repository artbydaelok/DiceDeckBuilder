import { TERRAIN_ICONS } from "../iconManifest";
import { TERRAIN_TYPES, type PaintTool } from "../terrainTypes";
import type { TileType } from "../types";

interface Props {
  activeType: TileType | null;
  paintTool: PaintTool;
  linePending: boolean;
  onTypeChange: (type: TileType | null) => void;
  onToolChange: (tool: PaintTool) => void;
}

export function TerrainPaint({ activeType, paintTool, linePending, onTypeChange, onToolChange }: Props) {
  const activeInfo = TERRAIN_TYPES.find((t) => t.id === activeType);

  return (
    <section className="terrain-paint">
      <h2>Terrain paint</h2>
      <h3>Tool</h3>
      <div className="palette-kinds">
        {(
          [
            ["brush", "Brush (drag)"],
            ["rectangle", "Rectangle"],
            ["line", "Line (2 clicks)"],
            ["fill", "Fill (bucket)"],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            className={paintTool === id && activeType ? "active" : ""}
            disabled={!activeType}
            onClick={() => onToolChange(id)}
          >
            {label}
          </button>
        ))}
      </div>

      <h3>Tile type</h3>
      <div className="terrain-types">
        {TERRAIN_TYPES.map((t) => (
          <button
            key={t.id}
            type="button"
            className={`terrain-type-btn terrain-${t.id}${activeType === t.id ? " active" : ""}`}
            onClick={() => onTypeChange(activeType === t.id ? null : t.id)}
            title={t.description}
          >
            {TERRAIN_ICONS[t.id] && (
              <img src={TERRAIN_ICONS[t.id]} alt="" className="terrain-type-icon" />
            )}
            {t.label}
          </button>
        ))}
      </div>

      {activeInfo && (
        <p className="meta terrain-desc">{activeInfo.description}</p>
      )}
      {activeType && paintTool === "line" && (
        <p className="meta">{linePending ? "Click end tile for line." : "Click start tile for line."}</p>
      )}
      {activeType && paintTool === "brush" && (
        <p className="meta">Click or drag across cells to paint.</p>
      )}
      {activeType && paintTool === "rectangle" && (
        <p className="meta">Drag a box to fill with this terrain.</p>
      )}
      {activeType && paintTool === "fill" && (
        <p className="meta">Click a region to flood-fill matching tiles.</p>
      )}
    </section>
  );
}
