"use client";

import React, { useRef, useState, useEffect, useCallback } from "react";
import { toPng } from "html-to-image";

/* ─── Constants ─── */
const IPHONE_W = 1320, IPHONE_H = 2868;
const IPAD_W = 2048, IPAD_H = 2732;

const IPHONE_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
] as const;

const IPAD_SIZES = [
  { label: '13"', w: 2064, h: 2752 },
  { label: '12.9"', w: 2048, h: 2732 },
] as const;

type Device = "iphone" | "ipad";

/* ─── Phone mockup measurements ─── */
const MK_W = 1022, MK_H = 2082;
const SC_L = (52 / MK_W) * 100, SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100, SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100, SC_RY = (126 / 1990) * 100;

/* ─── Theme ─── */
const T = { bg: "#050505", accent: "#CCFF00", text: "#F0F0F5", muted: "#8E8E96" };

/* ─── Slides ─── */
const SLIDES = [
  { id: "01-hero", label: "WORKOUT TRACKER", headline: "Your gym.\nYour rules.",
    src: "/screenshots/01_workout.png", pos: "center" as const,
    bg: `radial-gradient(ellipse 120% 80% at 50% 110%, ${T.accent}18 0%, transparent 60%), linear-gradient(180deg, ${T.bg} 0%, #0a0a12 100%)` },
  { id: "02-progress", label: "PROGRESS", headline: "See every\ngain.",
    src: "/screenshots/03_progress.png", pos: "right" as const,
    bg: `radial-gradient(ellipse 100% 60% at 20% 80%, #4ECDC420 0%, transparent 50%), linear-gradient(160deg, #080810 0%, #0a0a0f 100%)` },
  { id: "03-exercises", label: "EXERCISES", headline: "50+ exercises.\nEvery muscle.",
    src: "/screenshots/04_exercises.png", pos: "left" as const,
    bg: `radial-gradient(ellipse 100% 60% at 80% 80%, ${T.accent}12 0%, transparent 50%), linear-gradient(200deg, #0a0a12 0%, ${T.bg} 100%)` },
  { id: "04-prs", label: "PERSONAL RECORDS", headline: "Beat your\nlast set.",
    src: "/screenshots/05_exercise_progress.png", pos: "center" as const,
    bg: `radial-gradient(ellipse 120% 80% at 50% 100%, #FF6B6B15 0%, transparent 50%), linear-gradient(180deg, #0a0a10 0%, ${T.bg} 100%)` },
  { id: "05-history", label: "ACTIVITY", headline: "Never forget\na workout.",
    src: "/screenshots/02_history.png", pos: "right" as const,
    bg: `radial-gradient(ellipse 100% 60% at 70% 90%, #45B7D115 0%, transparent 50%), linear-gradient(170deg, ${T.bg} 0%, #080812 100%)` },
  { id: "06-plan", label: "PLAN EDITOR", headline: "Build your\nperfect plan.",
    src: "/screenshots/06_plan_editor.png", pos: "center" as const,
    bg: `radial-gradient(ellipse 120% 70% at 50% 110%, ${T.accent}15 0%, transparent 50%), linear-gradient(180deg, #0a0a10 0%, ${T.bg} 100%)` },
];

/* ─── Phone Component ─── */
function Phone({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: `${MK_W}/${MK_H}`, ...style }}>
      <img src="/mockup.png" alt="" style={{ display: "block", width: "100%", height: "100%" }} draggable={false} />
      <div style={{ position: "absolute", zIndex: 10, overflow: "hidden",
        left: `${SC_L}%`, top: `${SC_T}%`, width: `${SC_W}%`, height: `${SC_H}%`,
        borderRadius: `${SC_RX}% / ${SC_RY}%` }}>
        <img src={src} alt={alt} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
      </div>
    </div>
  );
}

/* ─── iPad Component (CSS-only frame) ─── */
function IPad({ src, alt, style }: { src: string; alt: string; style?: React.CSSProperties }) {
  return (
    <div style={{ position: "relative", aspectRatio: "770/1000", ...style }}>
      <div style={{ width: "100%", height: "100%", borderRadius: "5% / 3.6%",
        background: "linear-gradient(180deg, #2C2C2E 0%, #1C1C1E 100%)",
        position: "relative", overflow: "hidden",
        boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.1), 0 8px 40px rgba(0,0,0,0.6)" }}>
        <div style={{ position: "absolute", top: "1.2%", left: "50%", transform: "translateX(-50%)",
          width: "0.9%", height: "0.65%", borderRadius: "50%", background: "#111113",
          border: "1px solid rgba(255,255,255,0.08)", zIndex: 20 }} />
        <div style={{ position: "absolute", inset: 0, borderRadius: "5% / 3.6%",
          border: "1px solid rgba(255,255,255,0.06)", pointerEvents: "none", zIndex: 15 }} />
        <div style={{ position: "absolute", left: "4%", top: "2.8%", width: "92%", height: "94.4%",
          borderRadius: "2.2% / 1.6%", overflow: "hidden", background: "#000" }}>
          <img src={src} alt={alt} style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }} draggable={false} />
        </div>
      </div>
    </div>
  );
}

/* ─── Slide Renderer ─── */
function Slide({ slide, W, H, device }: { slide: typeof SLIDES[number]; W: number; H: number; device: Device }) {
  const isIPad = device === "ipad";
  const isR = slide.pos === "right", isL = slide.pos === "left";
  const phoneW = isIPad ? W * 0.52 : W * 0.82;
  const offset = isIPad ? W * -0.02 : W * -0.04;
  const headSz = isIPad ? W * 0.06 : W * 0.095;
  const lblSz = isIPad ? W * 0.02 : W * 0.028;
  const MockupC = isIPad ? IPad : Phone;

  return (
    <div style={{ width: W, height: H, background: slide.bg, position: "relative", overflow: "hidden",
      fontFamily: "var(--font-space-grotesk), 'Space Grotesk', sans-serif" }}>
      <div style={{ marginTop: H * 0.07 }}>
        <div style={{ textAlign: isR ? "left" : isL ? "right" : "center", padding: `0 ${W * 0.06}px` }}>
          <div style={{ fontSize: lblSz, fontWeight: 600, color: T.accent, letterSpacing: "0.15em", marginBottom: W * 0.015 }}>{slide.label}</div>
          <div style={{ fontSize: headSz, fontWeight: 700, color: T.text, lineHeight: 1.0, letterSpacing: "-0.02em", whiteSpace: "pre-line" }}>{slide.headline}</div>
        </div>
      </div>
      <div style={{ position: "absolute", bottom: 0, width: phoneW,
        ...(isR ? { right: offset, transform: "translateY(10%)" }
          : isL ? { left: offset, transform: "translateY(10%)" }
          : { left: "50%", transform: "translateX(-50%) translateY(12%)" }) }}>
        <MockupC src={slide.src} alt={slide.label} />
      </div>
    </div>
  );
}

/* ─── Preview with ResizeObserver ─── */
function Preview({ slide, W, H, device, onClick }: {
  slide: typeof SLIDES[number]; W: number; H: number; device: Device; onClick: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.2);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const obs = new ResizeObserver(([e]) => setScale(e.contentRect.width / W));
    obs.observe(el); return () => obs.disconnect();
  }, [W]);
  return (
    <div ref={ref} onClick={onClick} className="group" style={{ width: "100%", aspectRatio: `${W}/${H}`, overflow: "hidden", borderRadius: 12, cursor: "pointer", position: "relative" }}>
      <div style={{ width: W, height: H, transform: `scale(${scale})`, transformOrigin: "top left" }}>
        <Slide slide={slide} W={W} H={H} device={device} />
      </div>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center",
        opacity: 0, background: "rgba(0,0,0,0.4)", borderRadius: 12, transition: "opacity 0.2s" }}
        className="group-hover:!opacity-100">
        <span style={{ color: "#fff", fontWeight: 600, fontSize: 13 }}>Click to export</span>
      </div>
    </div>
  );
}

/* ─── Main Page ─── */
export default function ScreenshotsPage() {
  const [device, setDevice] = useState<Device>("iphone");
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState(false);
  const [status, setStatus] = useState("");
  const exportRefs = useRef<(HTMLDivElement | null)[]>([]);

  const sizes = device === "iphone" ? IPHONE_SIZES : IPAD_SIZES;
  const designW = device === "iphone" ? IPHONE_W : IPAD_W;
  const designH = device === "iphone" ? IPHONE_H : IPAD_H;
  const exportW = sizes[sizeIdx].w;
  const exportH = sizes[sizeIdx].h;

  // Reset size index when switching device
  useEffect(() => setSizeIdx(0), [device]);

  const doExport = useCallback(async (index: number) => {
    const el = exportRefs.current[index]; if (!el) return;

    el.style.position = "fixed";
    el.style.left = "0px";
    el.style.top = "0px";
    el.style.zIndex = "-1";

    const opts = { width: designW, height: designH, pixelRatio: 1, cacheBust: true };
    await toPng(el, opts); // warm-up
    await new Promise(r => setTimeout(r, 200));
    const dataUrl = await toPng(el, opts);

    el.style.position = "absolute";
    el.style.left = "-9999px";
    el.style.zIndex = "";

    // Resize if export size differs from design size
    let finalUrl = dataUrl;
    if (exportW !== designW || exportH !== designH) {
      const img = new Image();
      await new Promise<void>(res => { img.onload = () => res(); img.src = dataUrl; });
      const c = document.createElement("canvas"); c.width = exportW; c.height = exportH;
      c.getContext("2d")!.drawImage(img, 0, 0, exportW, exportH);
      finalUrl = c.toDataURL("image/png");
    }

    const a = document.createElement("a");
    a.download = `${String(index + 1).padStart(2, "0")}-${SLIDES[index].id}-${device}-${exportW}x${exportH}.png`;
    a.href = finalUrl; a.click();
  }, [device, designW, designH, exportW, exportH]);

  const exportAll = useCallback(async () => {
    setExporting(true);
    for (let i = 0; i < SLIDES.length; i++) {
      setStatus(`${i + 1}/${SLIDES.length}`);
      await doExport(i);
      await new Promise(r => setTimeout(r, 400));
    }
    setStatus("Done!"); setExporting(false);
    setTimeout(() => setStatus(""), 2000);
  }, [doExport]);

  return (
    <div style={{ background: "#111", minHeight: "100vh", padding: 24 }}>
      {/* ─── Toolbar ─── */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24,
        padding: "12px 16px", background: "#1a1a1a", borderRadius: 12,
        position: "sticky", top: 12, zIndex: 100, flexWrap: "wrap" }}>
        <span style={{ color: T.accent, fontWeight: 700, fontSize: 16 }}>IronRep</span>

        {/* Device toggle */}
        {(["iphone", "ipad"] as Device[]).map(d => (
          <button key={d} onClick={() => setDevice(d)} style={{
            padding: "5px 12px", borderRadius: 6, border: "none", cursor: "pointer", fontSize: 13,
            background: device === d ? T.accent : "#333", color: device === d ? "#000" : "#888",
            fontWeight: device === d ? 700 : 400 }}>{d === "iphone" ? "iPhone" : "iPad"}</button>
        ))}

        <div style={{ width: 1, height: 20, background: "#333" }} />

        {/* Size selector */}
        {sizes.map((s, i) => (
          <button key={s.label} onClick={() => setSizeIdx(i)} style={{
            padding: "5px 10px", borderRadius: 6, border: "none", cursor: "pointer", fontSize: 12,
            background: i === sizeIdx ? "#444" : "transparent", color: i === sizeIdx ? "#fff" : "#666",
            fontWeight: i === sizeIdx ? 600 : 400 }}>{s.label}</button>
        ))}

        <div style={{ flex: 1 }} />
        {status && <span style={{ color: "#888", fontSize: 13 }}>{status}</span>}
        <button onClick={exportAll} disabled={exporting} style={{
          padding: "8px 20px", borderRadius: 8, border: "none", fontWeight: 700, fontSize: 14,
          background: exporting ? "#555" : T.accent, color: "#000",
          cursor: exporting ? "not-allowed" : "pointer" }}>{exporting ? "Exporting..." : "Export All"}</button>
      </div>

      {/* ─── Preview Grid ─── */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: 20 }}>
        {SLIDES.map((slide, i) => (
          <div key={slide.id}>
            <Preview slide={slide} W={designW} H={designH} device={device}
              onClick={async () => { setExporting(true); await doExport(i); setExporting(false); }} />
            <div style={{ color: "#555", fontSize: 11, marginTop: 6, textAlign: "center" }}>{slide.id}</div>
          </div>
        ))}
      </div>

      {/* ─── Offscreen export containers (full resolution, no transform) ─── */}
      {SLIDES.map((slide, i) => (
        <div key={`exp-${slide.id}`} ref={el => { exportRefs.current[i] = el; }}
          style={{ position: "absolute", left: "-9999px", top: 0, width: designW, height: designH,
            fontFamily: "var(--font-space-grotesk), 'Space Grotesk', sans-serif" }}>
          <Slide slide={slide} W={designW} H={designH} device={device} />
        </div>
      ))}
    </div>
  );
}
