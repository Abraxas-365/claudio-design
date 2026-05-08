---
name: handoff
description: Developer handoff — spec.md generation, token extraction, Tailwind/CSS config, interaction documentation, and asset packaging
autoload: true
agents: [design]
---

# Developer Handoff Skill

Generate a complete developer handoff package from a finished design mockup. The handoff bridges design intent to implementation with zero ambiguity.

## When to Use

- Design is approved by the user/stakeholder
- Ready to hand off to a developer (or to yourself for implementation)
- Need to document design decisions for future reference

## Handoff Package Contents

### 1. spec.md — Design Specification

The central document. Structure:

```markdown
# [Project Name] — Design Specification
> Generated: YYYY-MM-DD
> Source: [path to HTML mockup]
> Status: Ready for development

## Overview
- **Product**: [what it is]
- **Target**: [web / iOS / Android / desktop]
- **Breakpoints**: [responsive behavior]
- **Key interactions**: [summary of dynamic behavior]

## Design Tokens

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | `oklch(0.55 0.15 250)` | Primary actions, links |
| `--color-surface` | `oklch(0.97 0.01 80)` | Page background |
| ... | ... | ... |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-display` | Source Serif 4, Georgia, serif | Headings, hero text |
| `--font-body` | Inter, system-ui, sans-serif | Body text, UI labels |
| ... | ... | ... |

### Spacing
| Token | Value | Usage |
|-------|-------|-------|
| `--space-4` | 16px | Standard component padding |
| `--space-8` | 32px | Section spacing |
| ... | ... | ... |

## Page Sections

### Section: [Name]
- **Layout**: [CSS Grid / Flexbox spec]
- **Dimensions**: [width × height, responsive behavior]
- **Background**: [token reference]
- **Content**: [what goes here]
- **Interactions**: [hover, click, scroll behavior]

#### Component: [Name]
- **Type**: [button / card / input / ...]
- **States**: [default, hover, active, disabled, focus]
- **Dimensions**: [w × h, padding, margin]
- **Typography**: [font, size, weight, line-height, color]
- **Border**: [width, color, radius]
- **Shadow**: [token reference]
- **Content**: [text, icon, image requirements]

## Interactions & Animations

### Interaction: [Name]
- **Trigger**: [click / hover / scroll / load]
- **Duration**: [ms]
- **Easing**: [CSS timing function]
- **Properties**: [what animates — opacity, transform, etc.]
- **Start state**: [CSS values]
- **End state**: [CSS values]

## Responsive Behavior

| Breakpoint | Layout Change |
|-----------|---------------|
| ≥1280px | [desktop layout] |
| ≥768px | [tablet layout] |
| <768px | [mobile layout] |

## Assets Required

| Asset | Format | Dimensions | Notes |
|-------|--------|-----------|-------|
| Logo | SVG | — | Provided in /assets/ |
| Hero image | PNG/WebP | 1920×1080 | Needs optimization |
| ... | ... | ... | ... |

## Implementation Notes
- [Framework-specific notes]
- [Accessibility requirements]
- [Performance considerations]
- [Known trade-offs from design phase]
```

### 2. tokens.css — CSS Custom Properties

Extract all design tokens into a standalone CSS file:

```css
/* tokens.css — Auto-generated from design mockup */
/* Import this file first, then reference tokens with var() */

:root {
  /* Colors */
  --color-primary: oklch(0.55 0.15 250);
  --color-primary-hover: oklch(0.48 0.17 250);
  /* ... all color tokens ... */

  /* Typography */
  --font-display: 'Source Serif 4', Georgia, serif;
  --font-body: 'Inter', -apple-system, system-ui, sans-serif;
  /* ... all typography tokens ... */

  /* Spacing */
  --space-1: 4px;
  --space-2: 8px;
  /* ... all spacing tokens ... */

  /* Borders */
  --radius-sm: 4px;
  --radius-md: 8px;
  /* ... */

  /* Shadows */
  --shadow-sm: 0 1px 2px oklch(0 0 0 / 0.05);
  /* ... */
}
```

### 3. tailwind.config.js (If Applicable)

Generate Tailwind CSS theme extension with extracted tokens.

### 4. Annotated Screenshots

Capture screenshots with Playwright at key breakpoints:
- Desktop (1440px)
- Tablet (768px)
- Mobile (375px)

Add dimension annotations and component boundaries.

### 5. Component Inventory

List all unique components with their props/variants:

```markdown
## Component Inventory

### Button
- Variants: primary, secondary, ghost, destructive
- Sizes: sm (32px), md (40px), lg (48px)
- States: default, hover, active, disabled, loading

### Card
- Variants: default, elevated, outlined
- Has: title, description, image (optional), actions (optional)

### Input
- Types: text, email, password, search, textarea
- States: default, focus, error, disabled
- Has: label, helper text, error message
```

## Process

1. **Read the design HTML** — parse all CSS custom properties, font imports, component patterns
2. **Extract tokens** — colors, typography, spacing, shadows, radii
3. **Document components** — identify recurring patterns, list variants and states
4. **Map interactions** — document all hover/click/scroll/load animations
5. **Capture screenshots** — desktop, tablet, mobile breakpoints
6. **Write spec.md** — comprehensive specification document
7. **Generate tokens.css** — standalone token file
8. **Package assets** — copy referenced images, fonts, icons

## Output Structure

```
handoff/
├── spec.md              # Design specification
├── tokens.css           # CSS custom properties
├── tailwind.config.js   # Tailwind theme (if applicable)
├── screenshots/
│   ├── desktop.png
│   ├── tablet.png
│   └── mobile.png
└── assets/
    ├── logo.svg
    └── [other referenced assets]
```

## Quality Checklist

- [ ] Every color in the design has a named token
- [ ] Every font size/weight combination is documented
- [ ] Every component has states documented (hover, active, disabled, focus)
- [ ] All animations have duration + easing specified
- [ ] Responsive breakpoints with layout changes documented
- [ ] Assets listed with required formats and dimensions
- [ ] No ambiguous descriptions ("make it look nice") — everything is measurable
