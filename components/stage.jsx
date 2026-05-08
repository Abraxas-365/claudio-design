/**
 * stage.jsx — Convenience re-export wrapper for the Stage animation engine.
 *
 * This file re-exports Stage, Sprite, useTime, Easing, and interpolate
 * from animations.jsx. Use this import when you only need the Stage component
 * without the full animation toolkit.
 *
 * Usage in HTML (after loading animations.jsx):
 *   const { Stage, Sprite, useTime, Easing, interpolate } = window.AnimationKit;
 *
 * Or load this file standalone — it provides the same components.
 *
 * ─────────────────────────────────────────────────────────────────────
 *
 * Stage: Top-level animation container.
 *   Props:
 *     duration   — total animation duration in seconds (default: 3)
 *     phases     — array of named phase strings (optional)
 *     autoplay   — start immediately on mount (default: true)
 *     onComplete — callback when animation finishes
 *     children   — Sprite components or any React elements
 *
 * Sprite: Animated element within a Stage.
 *   Props:
 *     appear     — time (0-1 normalized) when element appears
 *     exit       — time (0-1 normalized) when element exits (optional)
 *     duration   — animation duration in seconds
 *     easing     — easing function from Easing object
 *     from       — start styles { opacity, x, y, scale, rotate }
 *     to         — end styles { opacity, x, y, scale, rotate }
 *     children   — content to animate
 *
 * useTime(): Hook returning normalized time [0, 1] within current phase.
 *
 * Easing: Object with standard easing functions:
 *   .linear, .easeIn, .easeOut, .easeInOut, .spring
 *
 * interpolate(t, from, to): Linear interpolation helper.
 *
 * ─────────────────────────────────────────────────────────────────────
 *
 * The full implementation lives in animations.jsx. This file exists so
 * that both `components/stage.jsx` and `components/animations.jsx` are
 * valid entry points. Load either one — the exports are identical.
 *
 * If you need the Stage component in your HTML, load animations.jsx:
 *
 *   <script src="components/animations.jsx" type="text/babel"></script>
 *
 * Then access via window.AnimationKit:
 *
 *   const { Stage, Sprite, useTime, Easing, interpolate } = window.AnimationKit;
 */

// If loaded after animations.jsx, re-export from window.AnimationKit
(function() {
  if (typeof window !== 'undefined' && window.AnimationKit) {
    // Already loaded via animations.jsx — nothing to do
    return;
  }

  // ── Minimal standalone Stage implementation ─────────────────────────
  // For the full-featured version with phases, progress bar, replay,
  // and video export support, use animations.jsx instead.

  const React = window.React;
  const { useState, useEffect, useRef, useContext, createContext, useCallback } = React;

  // ── Easing functions ────────────────────────────────────────────────
  const Easing = {
    linear: t => t,
    easeIn: t => t * t,
    easeOut: t => 1 - (1 - t) * (1 - t),
    easeInOut: t => t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2,
    spring: t => {
      const c4 = (2 * Math.PI) / 3;
      return t === 0 ? 0 : t === 1 ? 1
        : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
    },
  };

  // ── Interpolation ───────────────────────────────────────────────────
  function interpolate(t, from, to) {
    if (typeof from === 'number' && typeof to === 'number') {
      return from + (to - from) * t;
    }
    return t < 0.5 ? from : to;
  }

  // ── Time context ────────────────────────────────────────────────────
  const TimeContext = createContext(0);
  function useTime() { return useContext(TimeContext); }

  // ── Stage ───────────────────────────────────────────────────────────
  function Stage({ duration = 3, autoplay = true, onComplete, children }) {
    const [time, setTime] = useState(0);
    const startRef = useRef(null);
    const rafRef = useRef(null);

    const tick = useCallback((now) => {
      if (!startRef.current) startRef.current = now;
      const elapsed = (now - startRef.current) / 1000;
      const t = Math.min(elapsed / duration, 1);
      setTime(t);
      if (t < 1) {
        rafRef.current = requestAnimationFrame(tick);
      } else {
        onComplete?.();
      }
    }, [duration, onComplete]);

    useEffect(() => {
      if (autoplay) {
        rafRef.current = requestAnimationFrame(tick);
        window.__ready = true;
      }
      return () => {
        if (rafRef.current) cancelAnimationFrame(rafRef.current);
      };
    }, [autoplay, tick]);

    return React.createElement(TimeContext.Provider, { value: time }, children);
  }

  // ── Sprite ──────────────────────────────────────────────────────────
  function Sprite({
    appear = 0, exit, duration: spriteDur = 0.5,
    easing = Easing.easeOut, from = {}, to = {},
    children,
  }) {
    const t = useTime();
    if (t < appear) return null;
    if (exit !== undefined && t > exit) return null;

    const local = Math.min((t - appear) / (spriteDur || 0.5), 1);
    const eased = easing(local);

    const style = {
      opacity: interpolate(eased, from.opacity ?? 0, to.opacity ?? 1),
      transform: [
        `translateX(${interpolate(eased, from.x ?? 0, to.x ?? 0)}px)`,
        `translateY(${interpolate(eased, from.y ?? 0, to.y ?? 0)}px)`,
        `scale(${interpolate(eased, from.scale ?? 1, to.scale ?? 1)})`,
        `rotate(${interpolate(eased, from.rotate ?? 0, to.rotate ?? 0)}deg)`,
      ].join(' '),
      willChange: 'transform, opacity',
    };

    return React.createElement('div', { style }, children);
  }

  // ── Export ──────────────────────────────────────────────────────────
  const AnimationKit = { Stage, Sprite, useTime, Easing, interpolate };
  if (typeof window !== 'undefined') {
    window.AnimationKit = AnimationKit;
  }
})();
