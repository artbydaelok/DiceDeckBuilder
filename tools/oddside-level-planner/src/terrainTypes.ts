import type { TileType } from "./types";

export type PaintTool = "brush" | "rectangle" | "line" | "fill";

export interface TerrainTypeInfo {
  id: TileType;
  label: string;
  description: string;
}

export const TERRAIN_TYPES: TerrainTypeInfo[] = [
  {
    id: "floor",
    label: "Floor (Default)",
    description: "Default walkable — unpainted grey cells. Use to erase terrain paint.",
  },
  {
    id: "water",
    label: "Water",
    description: "Hazard / water area — builder can spawn water blocks here later.",
  },
  {
    id: "pit",
    label: "Pit",
    description: "Hole or non-walkable gap in the plan.",
  },
  {
    id: "deck_floor",
    label: "Deck zone hint",
    description:
      "Purple overlay only: marks where a deck puzzle zone should go. Not a Godot tile — use a Deck zone entity for the real mechanic.",
  },
];
