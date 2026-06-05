import { ENTITY_ICONS, iconForCatalogEntry } from "../iconManifest";
import type { EntityKind, GameCatalog, PaletteItem, PlacementMode } from "../types";

interface Props {
  catalog: GameCatalog;
  activeKind: EntityKind;
  activeEnemyId: string;
  activeBossId: string;
  activeDeckId: string;
  activeBreakableId: string;
  activeCheckpointId: string;
  placementMode: PlacementMode;
  pathDraftLength: number;
  draftSize: { width: number; depth: number };
  rectPreview: { w: number; d: number } | null;
  onDraftSizeChange: (size: { width: number; depth: number }) => void;
  onKindChange: (kind: EntityKind) => void;
  onEnemyChange: (id: string) => void;
  onBossChange: (id: string) => void;
  onDeckChange: (id: string) => void;
  onBreakableChange: (id: string) => void;
  onCheckpointChange: (id: string) => void;
  onFinishPath: () => void;
  onCancelPath: () => void;
}

const PLACEMENT_HINT: Record<PlacementMode, string> = {
  point: "Click to place (replaces underneath)",
  rectangle: "Drag — replaces anything in the box",
  path: "Click waypoints → Finish path · right-click undo waypoint",
};

export function EntityPalette({
  catalog,
  activeKind,
  activeEnemyId,
  activeBossId,
  activeDeckId,
  activeBreakableId,
  activeCheckpointId,
  placementMode,
  pathDraftLength,
  draftSize,
  rectPreview,
  onDraftSizeChange,
  onKindChange,
  onEnemyChange,
  onBossChange,
  onDeckChange,
  onBreakableChange,
  onCheckpointChange,
  onFinishPath,
  onCancelPath,
}: Props) {
  const activePalette = catalog.palette.find((p) => p.kind === activeKind);
  const activeEnemy = catalog.enemies.find((e) => e.id === activeEnemyId);
  const activeBoss = catalog.bosses.find((b) => b.id === activeBossId);
  const placeIcon =
    activeKind === "enemy" && activeEnemy
      ? iconForCatalogEntry(activeEnemy)
      : activeKind === "boss" && activeBoss
        ? iconForCatalogEntry(activeBoss)
        : activePalette?.icon ?? ENTITY_ICONS[activeKind] ?? "/icons/custom.svg";

  return (
    <aside className="palette">
      <h2>Place</h2>
      <p className="placement-hint">{PLACEMENT_HINT[placementMode]}</p>
      {(activeKind === "enemy" || activeKind === "boss") && (
        <p className="meta place-preview">
          <img src={placeIcon} alt="" className="palette-icon" />
          Placing: {activeEnemy?.label ?? activeBoss?.label ?? activeKind}
        </p>
      )}
      <div className="palette-kinds">
        {catalog.palette.map((item: PaletteItem) => (
          <button
            key={item.kind}
            type="button"
            className={activeKind === item.kind ? "active" : ""}
            onClick={() => onKindChange(item.kind)}
            title={item.editorOnly ? "Not exported to Godot" : item.container}
          >
            <img
              src={item.icon ?? ENTITY_ICONS[item.kind] ?? "/icons/custom.svg"}
              alt=""
              className="palette-icon"
            />
            <span>{item.label}</span>
            {item.editorOnly ? " ◇" : ""}
          </button>
        ))}
      </div>

      {(placementMode === "rectangle" || placementMode === "path") && (
        <div className="size-tools">
          <h3>Placement size (tiles)</h3>
          {rectPreview && (
            <p className="meta preview-live">
              Live: {rectPreview.w} × {rectPreview.d}
            </p>
          )}
          <label>
            Width
            <input
              type="number"
              min={1}
              value={draftSize.width}
              onChange={(e) =>
                onDraftSizeChange({
                  ...draftSize,
                  width: Math.max(1, Number(e.target.value) || 1),
                })
              }
            />
          </label>
          <label>
            Depth
            <input
              type="number"
              min={1}
              value={draftSize.depth}
              onChange={(e) =>
                onDraftSizeChange({
                  ...draftSize,
                  depth: Math.max(1, Number(e.target.value) || 1),
                })
              }
            />
          </label>
          <p className="meta">Drag to resize on grid, or set numbers (updates preview while dragging).</p>
        </div>
      )}

      {placementMode === "path" && (
        <div className="path-tools">
          <p className="meta">Waypoints: {pathDraftLength}</p>
          <button type="button" disabled={pathDraftLength < 2} onClick={onFinishPath}>
            Finish path
          </button>
          <button type="button" className="secondary" onClick={onCancelPath}>
            Cancel path
          </button>
        </div>
      )}

      {activePalette?.pickSceneFrom === "enemies" && (
        <>
          <h3>Enemy type</h3>
          <div className="pawn-icon-picker">
            {catalog.enemies.map((e) => (
              <button
                key={e.id}
                type="button"
                className={activeEnemyId === e.id ? "active" : ""}
                title={e.label}
                onClick={() => onEnemyChange(e.id)}
              >
                <img src={iconForCatalogEntry(e)} alt="" className="palette-icon" />
                <span>{e.label}</span>
              </button>
            ))}
          </div>
        </>
      )}

      {activePalette?.pickSceneFrom === "bosses" && (
        <>
          <h3>Boss</h3>
          <div className="pawn-icon-picker">
            {catalog.bosses.map((b) => (
              <button
                key={b.id}
                type="button"
                className={activeBossId === b.id ? "active" : ""}
                title={b.label}
                onClick={() => onBossChange(b.id)}
              >
                <img src={iconForCatalogEntry(b)} alt="" className="palette-icon" />
                <span>{b.label.replace(/^Boss:\s*/i, "")}</span>
              </button>
            ))}
          </div>
        </>
      )}

      {activePalette?.pickDeckFrom === "decks" && (
        <>
          <h3>Deck (replaces faces in zone)</h3>
          <select value={activeDeckId} onChange={(e) => onDeckChange(e.target.value)}>
            {catalog.decks.map((d) => (
              <option key={d.id} value={d.id}>
                {d.label}
              </option>
            ))}
          </select>
        </>
      )}

      {activePalette?.pickSceneFrom === "breakables" && (
        <>
          <h3>Breakable type</h3>
          <select value={activeBreakableId} onChange={(e) => onBreakableChange(e.target.value)}>
            {catalog.breakables.map((b) => (
              <option key={b.id} value={b.id}>
                {b.label}
              </option>
            ))}
          </select>
        </>
      )}

      {activePalette?.pickCheckpointFrom === "checkpoints" && (
        <>
          <h3>Checkpoint data</h3>
          <select value={activeCheckpointId} onChange={(e) => onCheckpointChange(e.target.value)}>
            {catalog.checkpoints.length === 0 && <option value="">(run npm run catalog)</option>}
            {catalog.checkpoints.map((c) => (
              <option key={c.id} value={c.id}>
                {c.label}
              </option>
            ))}
          </select>
        </>
      )}

    </aside>
  );
}
