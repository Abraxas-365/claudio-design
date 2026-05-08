---
name: wireframe
description: Fast lo-fi grayscale wireframes with annotations for early-stage ideation — no design tokens, no polish, just structure
autoload: true
agents: [design]
---

# Wireframe Skill

Generate lo-fi grayscale wireframes for rapid structural exploration. No colors, no branding, no polish — just information architecture and interaction flow.

## When to Use

- Early-stage ideation before visual direction is chosen
- Layout exploration — testing if content fits
- Flow documentation — mapping screen-to-screen navigation
- Stakeholder alignment — "is this the right structure?"

**Not for**: Pixel-perfect mockups, brand work, client deliverables (use `mockup` or `hifi` instead).

## Visual Rules

### Color Palette (Grayscale Only)

```css
:root {
  --wire-bg: #FFFFFF;
  --wire-surface: #F5F5F5;
  --wire-border: #E0E0E0;
  --wire-text: #333333;
  --wire-text-muted: #999999;
  --wire-placeholder: #CCCCCC;
  --wire-accent: #666666;      /* For interactive elements */
  --wire-highlight: #4A90D9;   /* Single blue for annotations */
}
```

No oklch, no brand colors. This is intentionally flat.

### Typography

```css
:root {
  --wire-font: -apple-system, system-ui, sans-serif;
  --wire-font-mono: 'SF Mono', 'Menlo', monospace;
}
```

Single font stack. Content hierarchy via size and weight only.

### Elements

| Element | Representation |
|---------|---------------|
| Image | Gray box with × cross and `[Image: description]` label |
| Icon | 20×20 gray circle with text abbreviation |
| Button | Rounded rectangle with centered text, slightly darker fill |
| Input | Bordered rectangle with placeholder text |
| Text block | Actual text (not lines) — use real or realistic content |
| Navigation | Simple horizontal or vertical list |
| Card | Light gray surface with subtle border |

### Placeholder Pattern

```html
<div class="wire-image-placeholder" style="
  background: var(--wire-placeholder);
  aspect-ratio: 16/9;
  display: grid;
  place-items: center;
  border: 2px dashed var(--wire-border);
  font-family: var(--wire-font-mono);
  font-size: 12px;
  color: var(--wire-text-muted);
">
  [Hero Image — Product Screenshot]
</div>
```

## Annotation System

### Interaction Annotations

Use blue callout boxes positioned adjacent to interactive elements:

```html
<div class="wire-annotation" style="
  position: absolute;
  background: var(--wire-highlight);
  color: white;
  font-size: 11px;
  padding: 4px 8px;
  border-radius: 4px;
  font-family: var(--wire-font-mono);
  max-width: 200px;
">
  Tap → Navigate to /checkout
</div>
```

### Flow Arrows

Use CSS borders or SVG lines to show navigation flow between screens:

```css
.wire-flow-arrow {
  border-top: 2px solid var(--wire-highlight);
  position: relative;
  margin: 16px 0;
}
.wire-flow-arrow::after {
  content: '→';
  color: var(--wire-highlight);
  position: absolute;
  right: -4px;
  top: -10px;
}
```

### Numbering

Number screens and annotate interactions:

```
Screen 1: Home
  [1a] Tap "Get Started" → Screen 2
  [1b] Tap "Login" → Screen 3
  [1c] Scroll → reveals pricing section

Screen 2: Onboarding
  [2a] Complete form → Screen 4
  [2b] Tap "Back" → Screen 1
```

## Layout

- Use CSS Grid for page structure
- Maximum 12-column grid
- Show grid lines with faint dashed borders if layout is complex
- Side-by-side screen comparison for multi-screen flows

## Multi-Screen Flows

When wireframing a flow (e.g., onboarding, checkout):

1. **Overview**: All screens on one page, numbered, with flow arrows
2. **Individual**: Each screen at full size with annotations
3. **Decision map**: Branching paths shown as a tree

Use `design-canvas.jsx` for side-by-side screen comparison.

## Process

1. Ask user for content priorities and screen list
2. Sketch all screens as fast wireframes
3. Add interaction annotations
4. Add flow documentation
5. Present to user for structural feedback

**Speed over polish.** The point is to validate structure before investing in visual design.

## Output

- Single HTML file with all screens
- Grayscale only
- Interaction annotations in blue
- Flow arrows between screens
- No React components needed (plain HTML/CSS is fine for wireframes)
- No anti-slop check needed (wireframes are intentionally generic)
