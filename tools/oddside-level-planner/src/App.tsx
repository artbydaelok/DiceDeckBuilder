import { useCallback, useEffect, useMemo, useState } from "react";
import "./App.css";
import { ControlsHelp } from "./components/ControlsHelp";
import { GridCanvas } from "./components/GridCanvas";
import { idsIntersectingRect, topEntityAt } from "./gridEntities";
import { EntityPalette } from "./components/EntityPalette";
import { EntityInspector } from "./components/EntityInspector";
import { createEntity } from "./entityFactory";
import { exportEntitySummary, planForGameExport } from "./exportPlan";
import type { EntityKind, GameCatalog, LevelPlan, TileCoord, TileSize, TileType } from "./types";
import {
  emptyPlan,
  placementForKind,
  rectTiles,
  PLAN_VERSION,
  type PlacementMode,
} from "./types";
import { applyPaint, floodFillTiles, tilesInRect, tilesOnLine } from "./paintUtils";
import type { PaintTool } from "./terrainTypes";
import { TerrainPaint } from "./components/TerrainPaint";
import { validatePlan } from "./validate";

function defaultCatalog(): GameCatalog {
  return {
    generatedAt: "",
    gameRoot: "",
    tileWorldUnits: 2,
    palette: [],
    enemies: [],
    bosses: [],
    decks: [],
    breakables: [],
    checkpoints: [],
    dialogues: [],
    phantomFollowModes: [],
    phantomLookAtModes: [],
    gridMoverPresets: [],
    tileTypes: ["floor", "water", "pit", "deck_floor"],
  };
}

function migratePlan(raw: LevelPlan): LevelPlan {
  if (raw.version === PLAN_VERSION) return raw;
  return {
    ...raw,
    version: PLAN_VERSION,
    entities: raw.entities.map((e) => ({
      ...e,
      kind: (e.kind as string) === "debug_player_start" ? "player_start" : e.kind,
      size: e.size ?? { width: 1, depth: 1 },
      editor_only: e.editor_only ?? false,
    })),
  };
}

export default function App() {
  const [catalog, setCatalog] = useState<GameCatalog>(defaultCatalog);
  const [plan, setPlan] = useState<LevelPlan>(emptyPlan);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [activeKind, setActiveKind] = useState<EntityKind>("enemy");
  const [activeEnemyId, setActiveEnemyId] = useState("frog");
  const [activeBossId, setActiveBossId] = useState("forest_demon");
  const [activeDeckId, setActiveDeckId] = useState("color_deck_6");
  const [activeBreakableId, setActiveBreakableId] = useState("log");
  const [activeCheckpointId, setActiveCheckpointId] = useState("");
  const [paintTile, setPaintTile] = useState<TileType | null>(null);
  const [paintTool, setPaintTool] = useState<PaintTool>("brush");
  const [isBrushPainting, setIsBrushPainting] = useState(false);
  const [paintRectAnchor, setPaintRectAnchor] = useState<TileCoord | null>(null);
  const [paintRectPreview, setPaintRectPreview] = useState<{
    x: number;
    z: number;
    w: number;
    d: number;
  } | null>(null);
  const [linePaintStart, setLinePaintStart] = useState<TileCoord | null>(null);
  const [linePaintHover, setLinePaintHover] = useState<TileCoord | null>(null);
  const [showEditorRegions, setShowEditorRegions] = useState(true);
  const [rectAnchor, setRectAnchor] = useState<TileCoord | null>(null);
  const [rectPreview, setRectPreview] = useState<{ x: number; z: number; w: number; d: number } | null>(
    null,
  );
  const [pathDraft, setPathDraft] = useState<TileCoord[]>([]);
  const [draftSize, setDraftSize] = useState<TileSize>({ width: 1, depth: 1 });

  const placementMode: PlacementMode = placementForKind(catalog, activeKind);

  const defaultDraftSizeForKind = useCallback(
    (kind: EntityKind): TileSize => {
      const item = catalog.palette.find((p) => p.kind === kind);
      if (item?.defaultSize) return { ...item.defaultSize };
      return { width: 1, depth: 1 };
    },
    [catalog.palette],
  );

  useEffect(() => {
    fetch("/catalog.json")
      .then((r) => r.json())
      .then((c: GameCatalog) => {
        setCatalog(c);
        if (c.enemies[0]) setActiveEnemyId(c.enemies[0].id);
        if (c.bosses[0]) setActiveBossId(c.bosses[0].id);
        if (c.decks[0]) setActiveDeckId(c.decks[0].id);
        if (c.breakables[0]) setActiveBreakableId(c.breakables[0].id);
        if (c.checkpoints[0]) setActiveCheckpointId(c.checkpoints[0].id);
      })
      .catch(() => console.warn("Run npm run catalog to generate public/catalog.json"));
  }, []);

  useEffect(() => {
    setPathDraft([]);
    setRectAnchor(null);
    setRectPreview(null);
    setDraftSize(defaultDraftSizeForKind(activeKind));
  }, [activeKind, catalog.palette, defaultDraftSizeForKind]);

  useEffect(() => {
    if (!paintTile) {
      setPaintRectAnchor(null);
      setPaintRectPreview(null);
      setLinePaintStart(null);
      setLinePaintHover(null);
      setIsBrushPainting(false);
    }
  }, [paintTile]);

  const cancelRectDraw = useCallback(() => {
    setRectAnchor(null);
    setRectPreview(null);
  }, []);

  const setPreviewFromAnchorAndSize = useCallback(
    (anchor: TileCoord, size: TileSize) => {
      setRectPreview({
        x: anchor.x,
        z: anchor.z,
        w: Math.min(size.width, plan.grid.width - anchor.x),
        d: Math.min(size.depth, plan.grid.depth - anchor.z),
      });
    },
    [plan.grid.width, plan.grid.depth],
  );

  const handleDraftSizeChange = (size: TileSize) => {
    const next = {
      width: Math.max(1, size.width),
      depth: Math.max(1, size.depth),
    };
    setDraftSize(next);
    if (rectAnchor) setPreviewFromAnchorAndSize(rectAnchor, next);
  };

  const removeByIds = useCallback((ids: string[]) => {
    if (!ids.length) return;
    setPlan((p) => ({ ...p, entities: p.entities.filter((e) => !ids.includes(e.id)) }));
    setSelectedId((sid) => (sid && ids.includes(sid) ? null : sid));
  }, []);

  useEffect(() => {
    const onKey = (ev: KeyboardEvent) => {
      if (ev.key !== "Delete" && ev.key !== "Backspace") return;
      if (selectedId) {
        ev.preventDefault();
        removeByIds([selectedId]);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [selectedId, removeByIds]);

  useEffect(() => {
    const onUp = () => {
      setIsBrushPainting(false);
      if (paintRectAnchor) {
        setPaintRectAnchor(null);
        setPaintRectPreview(null);
      }
      if (rectAnchor && !paintTile) cancelRectDraw();
    };
    window.addEventListener("mouseup", onUp);
    return () => window.removeEventListener("mouseup", onUp);
  }, [rectAnchor, paintRectAnchor, paintTile, cancelRectDraw]);

  const issues = useMemo(() => validatePlan(plan), [plan]);
  const selectedEntity = plan.entities.find((e) => e.id === selectedId) ?? null;

  const exportPreview = useMemo(() => {
    const exported = planForGameExport(plan);
    return exported.entities.flatMap((e) => exportEntitySummary(e));
  }, [plan]);

  const updateEntity = useCallback((entity: import("./types").PlanEntity) => {
    setPlan((p) => ({
      ...p,
      entities: p.entities.map((e) => (e.id === entity.id ? entity : e)),
    }));
  }, []);

  const placeCtx = () => ({
    enemyId: activeEnemyId,
    bossId: activeBossId,
    deckId: activeDeckId,
    breakableId: activeBreakableId,
    checkpointId: activeCheckpointId,
    pathPoints: pathDraft,
  });

  const addEntity = (x: number, z: number, size?: { width: number; depth: number }) => {
    const sz = size ?? { width: 1, depth: 1 };
    const ent = createEntity(catalog, activeKind, x, z, sz, placeCtx());
    setPlan((p) => {
      const drop = idsIntersectingRect(p, x, z, sz.width, sz.depth);
      const withoutOverlap = p.entities.filter((e) => !drop.includes(e.id));
      const withoutPlayerStart =
        activeKind === "player_start"
          ? withoutOverlap.filter((e) => e.kind !== "player_start")
          : withoutOverlap;
      return {
        ...p,
        entities: [...withoutPlayerStart, ent],
      };
    });
    setSelectedId(ent.id);
    setPathDraft([]);
    setRectPreview(null);
    setRectAnchor(null);
    if (placementMode === "rectangle" || placementMode === "path") {
      setDraftSize(defaultDraftSizeForKind(activeKind));
    }
  };

  const paintCells = (cells: TileCoord[], type: TileType) => {
    setPlan((p) => ({ ...p, ...applyPaint(p, cells, type) }));
  };

  const paintAt = (x: number, z: number) => {
    if (paintTile) paintCells([{ x, z }], paintTile);
  };

  const downloadJson = (gameOnly: boolean) => {
    const payload = gameOnly ? planForGameExport(plan) : plan;
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `${plan.level_name.replace(/\s+/g, "_").toLowerCase()}${gameOnly ? ".game" : ""}.plan.json`;
    a.click();
  };

  const loadJsonFile = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const parsed = migratePlan(JSON.parse(String(reader.result)) as LevelPlan);
        setPlan(parsed);
        setSelectedId(null);
      } catch (err) {
        alert(`Invalid JSON: ${err}`);
      }
    };
    reader.readAsText(file);
  };

  const handleCellClick = (x: number, z: number, e: React.MouseEvent) => {
    if (paintTile) {
      if (paintTool === "fill") {
        paintCells(floodFillTiles(plan, x, z, paintTile), paintTile);
        return;
      }
      if (paintTool === "line") {
        if (!linePaintStart) {
          setLinePaintStart({ x, z });
          setLinePaintHover({ x, z });
        } else {
          paintCells(tilesOnLine(linePaintStart.x, linePaintStart.z, x, z), paintTile);
          setLinePaintStart(null);
          setLinePaintHover(null);
        }
      }
      return;
    }
    if (placementMode === "path") {
      if (e.detail === 2 && pathDraft.length >= 2) {
        addEntity(pathDraft[0].x, pathDraft[0].z, { ...draftSize });
        return;
      }
      setPathDraft((pts) => [...pts, { x, z }]);
      return;
    }
    if (placementMode === "rectangle") return;

    if (e.shiftKey) {
      const hit = topEntityAt(plan, x, z);
      setSelectedId(hit?.id ?? null);
      return;
    }
    addEntity(x, z);
  };

  const handleCellMouseDown = (x: number, z: number) => {
    if (paintTile) {
      if (paintTool === "brush") {
        setIsBrushPainting(true);
        paintAt(x, z);
      } else if (paintTool === "rectangle") {
        setPaintRectAnchor({ x, z });
        setPaintRectPreview({ x, z, w: 1, d: 1 });
      }
      return;
    }
    if (placementMode !== "rectangle") return;
    const anchor = { x, z };
    setRectAnchor(anchor);
    setPreviewFromAnchorAndSize(anchor, draftSize);
  };

  const handleCellMouseEnter = (x: number, z: number) => {
    if (paintTile) {
      if (paintTool === "brush" && isBrushPainting) paintAt(x, z);
      if (paintTool === "rectangle" && paintRectAnchor) {
        const r = rectTiles(paintRectAnchor.x, paintRectAnchor.z, x, z);
        setPaintRectPreview({ x: r.x, z: r.z, w: r.w, d: r.d });
      }
      if (paintTool === "line" && linePaintStart) setLinePaintHover({ x, z });
      return;
    }
    if (!rectAnchor || placementMode !== "rectangle") return;
    const r = rectTiles(rectAnchor.x, rectAnchor.z, x, z);
    setRectPreview({ x: r.x, z: r.z, w: r.w, d: r.d });
  };

  const handleCellMouseUp = (x: number, z: number) => {
    if (paintTile && paintTool === "rectangle" && paintRectAnchor) {
      paintCells(tilesInRect(paintRectAnchor.x, paintRectAnchor.z, x, z), paintTile);
      setPaintRectAnchor(null);
      setPaintRectPreview(null);
      return;
    }
    if (!rectAnchor || placementMode !== "rectangle") return;
    const sameCell = rectAnchor.x === x && rectAnchor.z === z;
    const size = sameCell
      ? { ...draftSize }
      : (() => {
          const r = rectTiles(rectAnchor.x, rectAnchor.z, x, z);
          return { width: r.w, depth: r.d };
        })();
    const pos = sameCell ? rectAnchor : rectTiles(rectAnchor.x, rectAnchor.z, x, z);
    addEntity(pos.x, pos.z, size);
    cancelRectDraw();
  };

  const handleRemoveAt = (x: number, z: number) => {
    if (paintTile && paintTool === "line" && linePaintStart) {
      setLinePaintStart(null);
      setLinePaintHover(null);
      return;
    }
    if (placementMode === "path" && pathDraft.length > 0) {
      setPathDraft((pts) => pts.slice(0, -1));
      return;
    }
    const hit = topEntityAt(plan, x, z);
    if (hit) removeByIds([hit.id]);
  };

  return (
    <div className="app">
      <header>
        <h1>Oddside Level Planner</h1>
        <ControlsHelp />
        <div className="toolbar">
          <button type="button" onClick={() => setPlan(emptyPlan())}>
            New
          </button>
          <label className="file-btn">
            Open…
            <input
              type="file"
              accept="application/json,.json"
              onChange={(ev) => {
                const f = ev.target.files?.[0];
                if (f) loadJsonFile(f);
              }}
            />
          </label>
          <button type="button" onClick={() => downloadJson(false)}>
            Export full plan
          </button>
          <button type="button" onClick={() => downloadJson(true)}>
            Export for Godot
          </button>
          <label className="checkbox-row toolbar-check">
            <input
              type="checkbox"
              checked={showEditorRegions}
              onChange={(ev) => setShowEditorRegions(ev.target.checked)}
            />
            Show editor regions
          </label>
        </div>
        {issues.length > 0 ? (
          <ul className="issues">
            {issues.map((i, idx) => (
              <li key={idx}>
                <strong>{i.path}</strong>: {i.message}
              </li>
            ))}
          </ul>
        ) : (
          <p className="ok">Plan validates</p>
        )}
      </header>

      <div className="workspace">
        <div className="sidebar-left">
          <EntityPalette
            catalog={catalog}
            activeKind={activeKind}
            activeEnemyId={activeEnemyId}
            activeBossId={activeBossId}
            activeDeckId={activeDeckId}
            activeBreakableId={activeBreakableId}
            activeCheckpointId={activeCheckpointId}
            placementMode={placementMode}
            pathDraftLength={pathDraft.length}
            draftSize={draftSize}
            rectPreview={rectPreview ? { w: rectPreview.w, d: rectPreview.d } : null}
            onDraftSizeChange={handleDraftSizeChange}
            onKindChange={(k) => {
              setPaintTile(null);
              setActiveKind(k);
            }}
            onEnemyChange={setActiveEnemyId}
            onBossChange={setActiveBossId}
            onDeckChange={setActiveDeckId}
            onBreakableChange={setActiveBreakableId}
            onCheckpointChange={setActiveCheckpointId}
            onFinishPath={() => {
              if (pathDraft.length >= 2) addEntity(pathDraft[0].x, pathDraft[0].z, { ...draftSize });
            }}
            onCancelPath={() => setPathDraft([])}
          />
          <TerrainPaint
            activeType={paintTile}
            paintTool={paintTool}
            linePending={!!linePaintStart}
            onTypeChange={setPaintTile}
            onToolChange={setPaintTool}
          />
        </div>
        <main>
          <GridCanvas
            catalog={catalog}
            plan={plan}
            selectedEntityId={selectedId}
            activeKind={activeKind}
            rectPreview={rectPreview}
            pathPreview={pathDraft}
            pathPlatformSize={draftSize}
            paintTileType={paintTile}
            paintRectPreview={paintRectPreview}
            linePreview={
              linePaintStart && linePaintHover
                ? { from: linePaintStart, to: linePaintHover }
                : null
            }
            showEditorRegions={showEditorRegions}
            onCellClick={handleCellClick}
            onCellMouseDown={handleCellMouseDown}
            onCellMouseUp={handleCellMouseUp}
            onCellMouseEnter={handleCellMouseEnter}
            onRemoveAt={handleRemoveAt}
          />
        </main>
        <EntityInspector
          plan={plan}
          catalog={catalog}
          entity={selectedEntity}
          onUpdatePlan={setPlan}
          onUpdateEntity={updateEntity}
          onDeleteEntity={() => {
            if (!selectedEntity) return;
            setPlan((p) => ({
              ...p,
              entities: p.entities.filter((e) => e.id !== selectedEntity.id),
            }));
            setSelectedId(null);
          }}
          exportLines={exportPreview}
        />
      </div>
    </div>
  );
}
