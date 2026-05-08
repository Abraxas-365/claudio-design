---
name: mockup
description: Generate multi-direction mockups with assumption-placeholder-real iteration cycle, anti-slop enforcement, and oklch color tokens
autoload: true
agents: [design]
---

# Mockup Skill — Enhanced

Generate complete design mockups using the assumption-placeholder-real iteration cycle. This skill combines the Claudio built-in mockup capability with the huashu-design methodology for higher-quality, brand-faithful output.

## Process

### Phase 1 — Direction Generation (3 Variants)

Every mockup task generates **3 differentiated directions** before execution:

1. **By-the-book**: Safe, professional, follows established patterns for the domain
2. **Refined**: Elevated execution with one or two distinctive design choices
3. **Novel**: An unexpected approach that reframes the problem

Each direction gets:
- A name and 1-sentence rationale
- Color system defined in `oklch()` CSS custom properties
- Typography pairing (display + body)
- Layout strategy (grid structure)
- One "signature detail" — the 120% moment

Present all three to the user using `design-canvas.jsx` for side-by-side comparison.

### Phase 2 — Assumption-Placeholder Pass (Junior Designer Mode)

After the user picks a direction:

1. Write the HTML file with `<!--ASSUMPTION: ... -->` comments for every design decision
2. Use placeholder blocks (gray with text labels) for images, icons, and data
3. Include reasoning comments: `<!--WHY: Using serif display because brand mood is "authoritative" -->`
4. Show this to the user immediately — even if it's just gray boxes

```html
<!--ASSUMPTION: Primary CTA is "Get Started" based on typical SaaS landing pages -->
<!--ASSUMPTION: Hero image is a product screenshot — awaiting real asset -->
<!--WHY: Using CSS Grid 12-column because the content has 3 distinct hierarchy levels -->

<div class="hero-placeholder" style="background: oklch(0.9 0.01 250); height: 400px; display: grid; place-items: center;">
  <span style="color: oklch(0.5 0 0); font-family: monospace;">[Hero Image — Product Screenshot]</span>
</div>
```

### Phase 3 — Full Implementation

After user confirms direction:

1. Replace placeholders with real content / real assets
2. Implement the design system with oklch tokens:
   ```css
   :root {
     --color-primary: oklch(0.55 0.15 250);
     --color-surface: oklch(0.97 0.01 80);
     --color-ink: oklch(0.25 0.02 250);
     --color-accent: oklch(0.65 0.20 30);
     --color-muted: oklch(0.75 0.03 250);
   }
   ```
3. Apply typography:
   - Display: Source Serif 4, Fraunces, or brand-specific
   - Body: Inter, system stack, or brand-specific
4. Add Tweaks panel for live parameter variation (see `references/tweaks-system.md`)

### Phase 4 — Verification

1. Screenshot with Playwright at multiple viewport sizes
2. Check console for errors
3. Verify contrast ratios (4.5:1 minimum)
4. Run anti-slop self-check (see below)
5. Eyeball the result in a real browser

## Anti-Slop Self-Check (Run Before Delivery)

Before delivering any mockup, scan for:

- [ ] No purple gradients (unless brand spec)
- [ ] No emoji as icons (use Lucide/Feather/Phosphor or none)
- [ ] No rounded-card + left-border-accent pattern (unless brand spec)
- [ ] No SVG-drawn people or objects (use real images or placeholders)
- [ ] No Inter/Roboto as display font (distinctive serif or brand font)
- [ ] All colors from oklch system or brand spec (no random hex)
- [ ] No filler content (every element earns its place)
- [ ] Text contrast ≥ 4.5:1

## Component Usage

| Need | Component |
|------|-----------|
| Side-by-side variants | `design-canvas.jsx` |
| iOS app mockup | `ios-frame.jsx` (mandatory — never hand-write Dynamic Island) |
| Android app mockup | `android-frame.jsx` |
| Desktop app mockup | `macos-window.jsx` |
| Web page mockup | `browser-window.jsx` |
| Shared UI elements | `ui-kit.jsx` |

## For Brand Work

Execute the `core-asset-protocol` skill **before** starting any mockup that involves a specific brand. The brand-spec.md file must exist and be referenced by all HTML.

## Output

- Single self-contained HTML file (or multi-file with React components if >1000 lines)
- All assets referenced from `brand-spec.md` paths
- oklch CSS custom properties in `:root`
- Descriptive filename: `Landing Page.html`, `Dashboard v2.html`
