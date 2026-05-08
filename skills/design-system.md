---
name: design-system
description: Extract design tokens, component patterns, and style guide from an existing UI — screenshots, URLs, or Figma
autoload: true
agents: [design]
---

# Design System Extraction

Extract a complete design token system from an existing UI — whether provided as screenshots, live URLs, Figma links, or code.

## When to Use

- User has an existing product/brand and wants consistency
- Porting a design from Figma to code
- Creating a style guide from screenshots
- Establishing tokens for a design that's been built ad-hoc

## Extraction Process

### Step 1 — Gather Sources

Ask the user for any of:
- Live URL (best — can inspect CSS directly)
- Screenshots (good — visual extraction)
- Figma file link (good — structured data)
- Existing codebase CSS/Tailwind config
- Brand guidelines PDF

### Step 2 — Extract Color Palette

**From live URLs:**
```
Inspect CSS custom properties, Tailwind config, or computed styles.
Look for: backgrounds, text colors, borders, accents, interactive states.
```

**From screenshots:**
```
Use color picker on key areas: backgrounds, headings, buttons, links, borders, icons.
Group by role (primary, secondary, surface, ink, accent, error, success).
```

Convert all colors to oklch for perceptual uniformity:

```css
:root {
  /* Surfaces */
  --color-surface: oklch(0.97 0.01 80);
  --color-surface-elevated: oklch(0.99 0.005 80);
  --color-surface-sunken: oklch(0.93 0.015 80);

  /* Ink (text) */
  --color-ink: oklch(0.20 0.02 250);
  --color-ink-muted: oklch(0.55 0.02 250);
  --color-ink-subtle: oklch(0.70 0.01 250);

  /* Brand */
  --color-primary: oklch(0.55 0.15 250);
  --color-primary-hover: oklch(0.48 0.17 250);
  --color-secondary: oklch(0.65 0.10 150);

  /* Feedback */
  --color-error: oklch(0.55 0.22 25);
  --color-warning: oklch(0.70 0.15 80);
  --color-success: oklch(0.60 0.18 145);
  --color-info: oklch(0.60 0.12 250);

  /* Borders */
  --color-border: oklch(0.88 0.01 250);
  --color-border-strong: oklch(0.75 0.02 250);
}
```

### Step 3 — Extract Typography

Identify:
- **Display font**: Headlines, hero text
- **Body font**: Paragraphs, UI labels
- **Mono font**: Code, data, tabular content

Document the type scale:

```css
:root {
  --font-display: 'Source Serif 4', Georgia, serif;
  --font-body: 'Inter', -apple-system, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;

  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.25rem;    /* 20px */
  --text-xl: 1.5rem;     /* 24px */
  --text-2xl: 2rem;      /* 32px */
  --text-3xl: 2.5rem;    /* 40px */
  --text-4xl: 3rem;      /* 48px */

  --leading-tight: 1.2;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;

  --tracking-tight: -0.02em;
  --tracking-normal: 0;
  --tracking-wide: 0.04em;
}
```

### Step 4 — Extract Spacing & Layout

```css
:root {
  /* Spacing scale (4px base) */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  --space-12: 48px;
  --space-16: 64px;
  --space-24: 96px;

  /* Border radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;

  /* Container widths */
  --container-sm: 640px;
  --container-md: 768px;
  --container-lg: 1024px;
  --container-xl: 1280px;
}
```

### Step 5 — Extract Component Patterns

Document recurring components:

#### Buttons
```css
.btn { /* base styles */ }
.btn-primary { /* filled + brand color */ }
.btn-secondary { /* outlined or muted fill */ }
.btn-ghost { /* transparent + text color */ }
```

#### Cards
```css
.card { /* surface + border + radius + shadow */ }
.card-interactive { /* hover state */ }
```

#### Form Inputs
```css
.input { /* border + radius + padding + focus ring */ }
```

### Step 6 — Document Elevation & Shadows

```css
:root {
  --shadow-sm: 0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-md: 0 4px 8px oklch(0 0 0 / 0.08);
  --shadow-lg: 0 8px 24px oklch(0 0 0 / 0.1);
  --shadow-xl: 0 16px 48px oklch(0 0 0 / 0.12);
}
```

## Output Format

Generate a `design-system.html` file that serves as a living style guide:

1. **Color swatches**: Visual grid of all tokens with oklch values
2. **Typography samples**: Each size/weight at actual rendered size
3. **Spacing ruler**: Visual representation of the spacing scale
4. **Component gallery**: All documented components at each variant
5. **Icon set**: If icons were identified, document which library/set

Also generate a `tokens.css` file with all CSS custom properties for direct import.

## Tailwind Config Export (Optional)

If the user uses Tailwind CSS, generate a `tailwind.config.js` extension:

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'oklch(0.55 0.15 250)',
        surface: 'oklch(0.97 0.01 80)',
        ink: 'oklch(0.20 0.02 250)',
        // ...
      },
      fontFamily: {
        display: ['Source Serif 4', 'Georgia', 'serif'],
        body: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
};
```
