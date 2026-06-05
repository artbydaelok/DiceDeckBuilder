import { useCallback, useRef } from "react";

interface Props {
  value: number;
  onChange: (deg: number) => void;
  step?: number;
  label?: string;
}

const SIZE = 132;
const CX = SIZE / 2;
const CY = SIZE / 2;
const RING_R = 46;

function normalizeDeg(deg: number): number {
  let v = deg % 360;
  if (v < 0) v += 360;
  return v;
}

function snapDeg(deg: number, step: number): number {
  if (step <= 0) return deg;
  return Math.round(deg / step) * step;
}

/** Matches grid cone: 0° = −Z (up on the planner). */
function degFromPointer(clientX: number, clientY: number, svg: SVGSVGElement): number {
  const rect = svg.getBoundingClientRect();
  const scale = rect.width / SIZE;
  const dx = (clientX - rect.left) / scale - CX;
  const dy = (clientY - rect.top) / scale - CY;
  return (Math.atan2(dx, -dy) * 180) / Math.PI;
}

export function RotationDial({ value, onChange, step = 5, label = "Y rotation" }: Props) {
  const svgRef = useRef<SVGSVGElement>(null);
  const draggingRef = useRef(false);

  const applyPointer = useCallback(
    (clientX: number, clientY: number) => {
      const svg = svgRef.current;
      if (!svg) return;
      onChange(normalizeDeg(snapDeg(degFromPointer(clientX, clientY, svg), step)));
    },
    [onChange, step],
  );

  const onPointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    e.preventDefault();
    draggingRef.current = true;
    e.currentTarget.setPointerCapture(e.pointerId);
    applyPointer(e.clientX, e.clientY);
  };

  const onPointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!draggingRef.current) return;
    applyPointer(e.clientX, e.clientY);
  };

  const endDrag = (e: React.PointerEvent<SVGSVGElement>) => {
    draggingRef.current = false;
    if (e.currentTarget.hasPointerCapture(e.pointerId)) {
      e.currentTarget.releasePointerCapture(e.pointerId);
    }
  };

  const yaw = normalizeDeg(value);
  const rad = (yaw * Math.PI) / 180;
  const knobX = CX + RING_R * Math.sin(rad);
  const knobY = CY - RING_R * Math.cos(rad);
  const spread = (14 * Math.PI) / 180;
  const wedgeR = 34;
  const wedgePath = `M ${CX} ${CY} L ${CX + wedgeR * Math.sin(rad - spread)} ${CY - wedgeR * Math.cos(rad - spread)} L ${CX + wedgeR * Math.sin(rad + spread)} ${CY - wedgeR * Math.cos(rad + spread)} Z`;

  return (
    <div className="rotation-dial-field">
      <span className="rotation-dial-label">{label}</span>
      <div className="rotation-dial-wrap">
        <svg
          ref={svgRef}
          width={SIZE}
          height={SIZE}
          viewBox={`0 0 ${SIZE} ${SIZE}`}
          className="rotation-dial"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={endDrag}
          onPointerCancel={endDrag}
        >
          <circle cx={CX} cy={CY} r={RING_R + 10} className="rotation-dial-hit" />
          <circle cx={CX} cy={CY} r={RING_R} className="rotation-dial-ring" />
          {[0, 45, 90, 135, 180, 225, 270, 315].map((tick) => {
            const tr = (tick * Math.PI) / 180;
            const inner = RING_R - 5;
            const outer = RING_R + 3;
            return (
              <line
                key={tick}
                x1={CX + inner * Math.sin(tr)}
                y1={CY - inner * Math.cos(tr)}
                x2={CX + outer * Math.sin(tr)}
                y2={CY - outer * Math.cos(tr)}
                className="rotation-dial-tick"
              />
            );
          })}
          <path d={wedgePath} className="rotation-dial-cone" />
          <line x1={CX} y1={CY} x2={knobX} y2={knobY} className="rotation-dial-beam" />
          <circle cx={knobX} cy={knobY} r={9} className="rotation-dial-knob" />
          <text x={CX} y={CY + 5} textAnchor="middle" className="rotation-dial-value">
            {Math.round(yaw)}°
          </text>
        </svg>
        <p className="meta rotation-dial-hint">Drag around the ring · top = −Z forward</p>
      </div>
    </div>
  );
}
