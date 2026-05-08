---
name: hifi
description: High-fidelity design with oklch color system, film grain textures, glass morphism, Source Serif 4 typography, and live Tweaks panel
autoload: true
agents: [design]
---

# Hi-Fi Design Skill

Create polished, high-fidelity designs with depth, texture, and professional-grade visual quality. This skill elevates beyond flat mockups with deliberate material choices.

## Design System Foundation

### Color System — oklch()

All hi-fi designs use the `oklch()` color space for perceptually uniform, harmonious palettes:

```css
:root {
  /* Semantic tokens */
  --color-primary: oklch(0.55 0.15 250);
  --color-primary-hover: oklch(0.50 0.17 250);
  --color-surface: oklch(0.97 0.01 80);
  --color-surface-elevated: oklch(0.99 0.005 80);
  --color-ink: oklch(0.25 0.02 250);
  --color-ink-muted: oklch(0.55 0.02 250);
  --color-accent: oklch(0.65 0.20 30);
  --color-border: oklch(0.88 0.01 250);
  --color-error: oklch(0.55 0.22 25);
  --color-success: oklch(0.60 0.18 145);

  /* Dark mode (use light-dark() or media query) */
  --color-surface-dark: oklch(0.15 0.02 250);
  --color-ink-dark: oklch(0.90 0.01 250);
}
```

**Never hardcode hex values inline.** Define tokens in `:root`, reference with `var()`.

### Typography

- **Display**: Source Serif 4 (Google Fonts) — warm, authoritative, distinctive
- **Body/UI**: Inter — clean, readable, professional
- **Mono** (data/code): JetBrains Mono or IBM Plex Mono
- **Sizing scale**: 12 / 14 / 16 / 20 / 24 / 32 / 40 / 48 / 64

```css
@import url('https://fonts.googleapis.com/css2?family=Source+Serif+4:ital,opsz,wght@0,8..60,300;0,8..60,400;0,8..60,600;0,8..60,700;1,8..60,400&family=Inter:wght@400;500;600&display=swap');

:root {
  --font-display: 'Source Serif 4', Georgia, serif;
  --font-body: 'Inter', -apple-system, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
}
```

## Depth & Texture Techniques

### Film Grain / Texture Overlays

Add subtle texture to prevent flat, sterile surfaces:

```css
.surface-textured::after {
  content: '';
  position: absolute;
  inset: 0;
  opacity: 0.03;
  pointer-events: none;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
}
```

### Glass Morphism Toolkit

```css
.glass {
  background: oklch(0.97 0.005 250 / 0.7);
  backdrop-filter: blur(20px) saturate(1.2);
  -webkit-backdrop-filter: blur(20px) saturate(1.2);
  border: 1px solid oklch(1 0 0 / 0.15);
  box-shadow:
    0 1px 2px oklch(0 0 0 / 0.05),
    0 4px 16px oklch(0 0 0 / 0.08);
}

.glass-dark {
  background: oklch(0.15 0.02 250 / 0.6);
  backdrop-filter: blur(20px) saturate(1.3);
  border: 1px solid oklch(1 0 0 / 0.08);
}
```

### Elevation System

```css
.elevation-1 { box-shadow: 0 1px 3px oklch(0 0 0 / 0.08); }
.elevation-2 { box-shadow: 0 4px 12px oklch(0 0 0 / 0.1); }
.elevation-3 { box-shadow: 0 8px 24px oklch(0 0 0 / 0.12); }
.elevation-4 { box-shadow: 0 16px 48px oklch(0 0 0 / 0.15); }
```

## Tweaks Panel

Every hi-fi design includes a Tweaks panel for live parameter variation. This is a floating UI panel (bottom-right corner) that lets the user adjust design parameters in real time via `localStorage`:

### Implementation Pattern

```jsx
function TweaksPanel() {
  const [open, setOpen] = React.useState(false);
  const [params, setParams] = React.useState(() => {
    const saved = localStorage.getItem('design-tweaks');
    return saved ? JSON.parse(saved) : {
      colorScheme: 'light',
      accentHue: 250,
      density: 'comfortable',
      borderRadius: 12,
      fontScale: 1.0,
    };
  });

  React.useEffect(() => {
    localStorage.setItem('design-tweaks', JSON.stringify(params));
    // Apply to CSS custom properties
    const root = document.documentElement;
    root.style.setProperty('--accent-hue', params.accentHue);
    root.style.setProperty('--border-radius', params.borderRadius + 'px');
    root.style.setProperty('--font-scale', params.fontScale);
    root.dataset.theme = params.colorScheme;
  }, [params]);

  const update = (key, value) => setParams(p => ({ ...p, [key]: value }));

  if (!open) {
    return (
      <button onClick={() => setOpen(true)}
        style={{ position: 'fixed', bottom: 16, right: 16, zIndex: 9999,
                 padding: '8px 16px', borderRadius: 8,
                 background: 'oklch(0.25 0.02 250)', color: 'white',
                 border: 'none', cursor: 'pointer', fontSize: 13 }}>
        Tweaks
      </button>
    );
  }

  return (
    <div style={{ position: 'fixed', bottom: 16, right: 16, zIndex: 9999,
                  width: 280, background: 'white', borderRadius: 12,
                  boxShadow: '0 8px 32px rgba(0,0,0,0.15)', padding: 20 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <strong>Tweaks</strong>
        <button onClick={() => setOpen(false)} style={{ border: 'none', background: 'none', cursor: 'pointer' }}>×</button>
      </div>
      {/* Add sliders, toggles, selects for each parameter */}
      <label style={{ display: 'block', marginBottom: 12, fontSize: 13 }}>
        Color Scheme
        <select value={params.colorScheme} onChange={e => update('colorScheme', e.target.value)}
          style={{ display: 'block', width: '100%', marginTop: 4 }}>
          <option value="light">Light</option>
          <option value="dark">Dark</option>
        </select>
      </label>
      <label style={{ display: 'block', marginBottom: 12, fontSize: 13 }}>
        Accent Hue: {params.accentHue}
        <input type="range" min="0" max="360" value={params.accentHue}
          onChange={e => update('accentHue', parseInt(e.target.value))}
          style={{ display: 'block', width: '100%' }} />
      </label>
      <label style={{ display: 'block', marginBottom: 12, fontSize: 13 }}>
        Border Radius: {params.borderRadius}px
        <input type="range" min="0" max="24" value={params.borderRadius}
          onChange={e => update('borderRadius', parseInt(e.target.value))}
          style={{ display: 'block', width: '100%' }} />
      </label>
    </div>
  );
}
```

Full specification: `references/tweaks-system.md`

## Signature Detail Rule

> **Taste = one detail at 120%, everything else at 80%.**

Every hi-fi design must have one "screenshot-worthy" moment:
- A serif italic pull quote with faint texture
- A full-bleed hero with film grain overlay
- A glass card floating over a background image
- A precision data visualization with micro-typography

This is the detail that makes the viewer stop scrolling.

## Anti-Slop Enforcement

This skill inherits all rules from `anti-slop-rules`. Additionally:
- Film grain overlay opacity must be ≤ 0.05 (subtle, not grungy)
- Glass morphism blur ≥ 16px (anything less looks broken)
- No more than 2 elevation levels on one viewport (visual clutter)
- Shadows use oklch with alpha, not `rgba(0,0,0,0.x)`

## Delivery Checklist

- [ ] oklch color tokens defined in `:root`
- [ ] Source Serif 4 loaded for display, Inter for body
- [ ] At least one texture/depth technique applied
- [ ] Tweaks panel functional (parameters save to localStorage)
- [ ] Anti-slop self-check passed
- [ ] Contrast ratios verified (4.5:1 minimum)
- [ ] Verified in browser via Playwright screenshot
