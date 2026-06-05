import type { HTMLAttributes } from "react";

/** Render a public/ SVG on the grid — SVG <image href="*.svg"> is blocked in most browsers. */
interface Props {
  href: string;
  x: number;
  y: number;
  size: number;
  opacity?: number;
}

export function GridSvgIcon({ href, x, y, size, opacity = 0.95 }: Props) {
  return (
    <foreignObject x={x} y={y} width={size} height={size} pointerEvents="none">
      <div
        {...({ xmlns: "http://www.w3.org/1999/xhtml" } as HTMLAttributes<HTMLDivElement>)}
        style={{ width: size, height: size, margin: 0, padding: 0 }}
      >
        <img
          src={href}
          alt=""
          width={size}
          height={size}
          style={{
            display: "block",
            filter: "invert(0.9)",
            opacity,
          }}
        />
      </div>
    </foreignObject>
  );
}
