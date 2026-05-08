---
name: prototype
description: Interactive prototypes with Stage+Sprite animation engine, device frames, state management, multi-screen flows, and hotspot mode for walkthroughs
autoload: true
agents: [design]
---

# Prototype Skill — Interactive Prototypes

Build stateful, interactive prototypes with animated transitions, device frames, multi-screen flows, and presentation-ready hotspot mode.

## Architecture

### Animation Engine: Stage + Sprite

All prototypes use the `animations.jsx` component library which provides:

- **Stage**: Top-level animation container with timeline, playback controls, and `window.__ready` signal for video export
- **Sprite**: Individual animated element with `appear`/`exit` timing, easing, and transform interpolation
- **useTime()**: Hook returning normalized time `[0, 1]` within the current phase
- **Easing**: Object with standard easing functions (`easeInOut`, `easeOut`, `spring`, etc.)
- **interpolate(t, from, to)**: Linear interpolation helper

```jsx
// Basic animated prototype
const { Stage, Sprite, useTime, Easing, interpolate } = window.AnimationKit;

function App() {
  return (
    <Stage duration={3} phases={['intro', 'main', 'outro']}>
      <Sprite appear={0} duration={0.5} easing={Easing.easeOut}
        from={{ opacity: 0, y: 20 }} to={{ opacity: 1, y: 0 }}>
        <HeroSection />
      </Sprite>
    </Stage>
  );
}
```

### Device Frames

Always use the provided device frame components:

| Device | Component | Notes |
|--------|-----------|-------|
| iPhone | `ios-frame.jsx` | Mandatory for iOS prototypes — calibrated to iPhone 15 Pro specs |
| Android | `android-frame.jsx` | Material-style device bezel |
| Mac Desktop | `macos-window.jsx` | Traffic lights + title bar |
| Browser | `browser-window.jsx` | URL bar + tab strip |

**Rule**: Never hand-draw device chrome. The components handle status bars, notches, Dynamic Islands, and home indicators with pixel-accurate dimensions.

### State Management

Prototypes use React state for screen transitions and interactions:

```jsx
function Prototype() {
  const [screen, setScreen] = React.useState('home');
  const [prevScreen, setPrevScreen] = React.useState(null);

  const navigate = (to) => {
    setPrevScreen(screen);
    setScreen(to);
  };

  return (
    <IPhoneFrame>
      <ScreenTransition current={screen} previous={prevScreen}>
        {screen === 'home' && <HomeScreen onNavigate={navigate} />}
        {screen === 'detail' && <DetailScreen onNavigate={navigate} />}
        {screen === 'settings' && <SettingsScreen onNavigate={navigate} />}
      </ScreenTransition>
    </IPhoneFrame>
  );
}
```

## Screen Transition Patterns

### iOS Push (Default for Navigation)

```jsx
function ScreenTransition({ current, previous, children }) {
  return (
    <div style={{ position: 'relative', overflow: 'hidden', width: '100%', height: '100%' }}>
      <div style={{
        position: 'absolute', inset: 0,
        transition: 'transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.35s ease',
        transform: current !== previous ? 'translateX(0)' : 'translateX(100%)',
      }}>
        {children}
      </div>
    </div>
  );
}
```

### Modal (Bottom Sheet)

```jsx
const [showModal, setShowModal] = React.useState(false);

<div style={{
  position: 'fixed', bottom: 0, left: 0, right: 0,
  transform: showModal ? 'translateY(0)' : 'translateY(100%)',
  transition: 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
  background: 'white', borderRadius: '16px 16px 0 0',
  padding: 24, boxShadow: '0 -4px 24px rgba(0,0,0,0.12)',
}}>
  {/* Modal content */}
</div>
```

### Fade Cross-Dissolve

```jsx
<div style={{
  opacity: isActive ? 1 : 0,
  transition: 'opacity 0.3s ease',
  position: 'absolute', inset: 0,
}}>
  {children}
</div>
```

## Hotspot Mode

For stakeholder walkthroughs, add a hotspot overlay that highlights interactive areas:

```jsx
function HotspotOverlay({ hotspots, visible }) {
  if (!visible) return null;

  return hotspots.map((h, i) => (
    <div key={i} style={{
      position: 'absolute',
      left: h.x, top: h.y, width: h.w, height: h.h,
      background: 'oklch(0.6 0.2 250 / 0.2)',
      border: '2px solid oklch(0.6 0.2 250)',
      borderRadius: 8,
      cursor: 'pointer',
      animation: 'pulse 2s ease-in-out infinite',
    }}>
      <span style={{
        position: 'absolute', top: -24, left: 0,
        background: 'oklch(0.3 0.05 250)', color: 'white',
        padding: '2px 8px', borderRadius: 4, fontSize: 11,
        fontFamily: 'var(--font-mono)',
        whiteSpace: 'nowrap',
      }}>
        {h.label}
      </span>
    </div>
  ));
}
```

Toggle with keyboard shortcut:
```jsx
React.useEffect(() => {
  const handler = (e) => {
    if (e.key === 'h' || e.key === 'H') setShowHotspots(v => !v);
  };
  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
}, []);
```

## Interactive Elements

### Tap Feedback

```jsx
function TapButton({ children, onTap, ...props }) {
  const [pressed, setPressed] = React.useState(false);

  return (
    <div
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => { setPressed(false); onTap?.(); }}
      onPointerLeave={() => setPressed(false)}
      style={{
        transform: pressed ? 'scale(0.96)' : 'scale(1)',
        transition: 'transform 0.1s ease',
        cursor: 'pointer',
        ...props.style,
      }}
    >
      {children}
    </div>
  );
}
```

### Loading States

```jsx
function LoadingTransition({ loading, children }) {
  if (loading) {
    return (
      <div style={{ display: 'grid', placeItems: 'center', minHeight: 200 }}>
        <div style={{
          width: 24, height: 24,
          border: '3px solid oklch(0.9 0 0)',
          borderTopColor: 'oklch(0.5 0.15 250)',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite',
        }} />
      </div>
    );
  }
  return children;
}
```

## Animation Best Practices

Read `references/animation-best-practices.md` and `references/animation-pitfalls.md` before implementing animations.

Key rules:
1. **Read pitfalls first** — `references/animation-pitfalls.md` covers the most common failures
2. **Stage controls its own timeline** — don't add separate progress bars or timers that conflict
3. **Use `appear` and `exit` props on Sprite** — don't manage visibility manually
4. **Easing matters**: `easeOut` for entrances, `easeIn` for exits, `easeInOut` for loops
5. **Duration budget**: Total animation ≤ 30s for video export, ≤ 5s for micro-interactions
6. **One orchestrated entrance** > many scattered micro-interactions

## Process

1. Map the screen flow (which screens, which transitions)
2. Define interaction model (tap targets, gestures, keyboard shortcuts)
3. Choose device frame
4. Build screens with placeholder content first (Junior Designer mode)
5. Add transitions and animations
6. Add hotspot overlay
7. Test all paths through the flow
8. Verify with Playwright screenshot

## Output

- Self-contained HTML with React + Babel
- Device frame wrapping all content
- Keyboard navigation: arrow keys for screens, H for hotspots
- `window.__ready = true` set after first paint (enables video export)
- All interactions documented in HTML comments
