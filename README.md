# claudio-design

A Claudio plugin that transforms Claudio into a professional design creation tool. Built on the huashu-design methodology — a structured approach to generating high-quality, brand-faithful design mockups, prototypes, animations, and presentations.

## Installation

Add to `~/.claudio/init.lua`:

```lua
claudio.plugin.use({
  source = "Abraxas-365/claudio-design",
  config = function()
    -- All fields optional — defaults are shown below
    claudio.design.configure({
      critic_model   = "claude-haiku-4-5-20251001",  -- vision scoring model
      fidelity_model = "claude-haiku-4-5-20251001",  -- fidelity review model
    })
  end,
})
```

Then run `:PluginSync` to download and activate.

### Minimal install (use defaults)

```lua
claudio.plugin.use({ source = "Abraxas-365/claudio-design" })
```

### Upgrade critic model for best quality

```lua
claudio.plugin.use({
  source = "Abraxas-365/claudio-design",
  config = function()
    claudio.design.configure({
      critic_model   = "claude-opus-4-6",
      fidelity_model = "claude-opus-4-6",
    })
  end,
})

## Prerequisites

- **Node.js >= 18** — required for export scripts
- **Playwright** — `npx playwright install chromium` (for video/PDF export)
- **ffmpeg** — `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux) — for video export and BGM mixing

Optional (for PPTX export):
- `npm install pptxgenjs sharp` — in the plugin directory

## What This Plugin Does

1. **Replaces bundled design skills** with enhanced versions based on the huashu-design methodology
2. **Registers export tools** — ExportVideo (MP4), ExportPPTX (PowerPoint), ExportPDF
3. **Provides a component library** — device frames, animation engine, UI kit, slide deck engine
4. **Enforces design quality** — anti-AI-slop rules, brand asset protocol, 5-dimension critique scoring

## Skills

| Skill | Description |
|-------|-------------|
| `design-flow` | Core orchestration — junior designer workflow, asset protocol, Claudio pipeline, delivery formats |
| `core-asset-protocol` | 5-step brand asset verification: ask, search, download, verify, freeze to spec |
| `anti-slop-rules` | Anti-AI slop checklist — avoid purple gradients, emoji icons, generic layouts |
| `mockup` | Multi-direction mockups with assumption-placeholder-real iteration cycle |
| `hifi` | High-fidelity design with oklch colors, film grain, glass morphism, Tweaks panel |
| `wireframe` | Fast lo-fi grayscale wireframes with interaction annotations |
| `prototype` | Interactive prototypes with Stage+Sprite animation, device frames, state management |
| `design-direction-advisor` | 3 differentiated directions from 5 schools x 20 philosophies when brief is vague |
| `design-system` | Extract design tokens, component patterns, and style guide from existing UI |
| `handoff` | Developer handoff: spec.md, token extraction, Tailwind/CSS config, interaction docs |
| `critique-guide` | 5-dimension scoring model (each 0-10, total /50) with actionable fixes |

## Export Tools

### ExportVideo

Export an HTML design/animation as an MP4 video with optional background music.

```json
{
  "html_file": "/path/to/design.html",
  "output_path": "/path/to/output.mp4",
  "fps": 25,
  "duration": 3,
  "bgm": "tech"
}
```

Available BGM moods: `tech`, `ad`, `educational`, `educational-alt`, `tutorial`, `tutorial-alt`

### ExportPPTX

Export HTML slides as an editable PowerPoint file.

```json
{
  "html_file": "/path/to/slides.html",
  "output_path": "/path/to/output.pptx"
}
```

### ExportPDF

Export HTML slide files as a single vector PDF (text preserved, copyable, searchable).

```json
{
  "html_file": "/path/to/slides-directory/",
  "output_path": "/path/to/output.pdf"
}
```

## Component Library

| Component | File | Description |
|-----------|------|-------------|
| Stage + Sprite | `animations.jsx` | Animation engine with timeline, phases, easing, and video export support |
| Stage (standalone) | `stage.jsx` | Lightweight re-export of Stage/Sprite from animations.jsx |
| iOS Frame | `ios-frame.jsx` | iPhone 15 Pro bezel with Dynamic Island, status bar, home indicator |
| Android Frame | `android-frame.jsx` | Android device bezel |
| macOS Window | `macos-window.jsx` | Desktop window chrome with traffic lights |
| Browser Window | `browser-window.jsx` | Browser chrome with URL bar and tab strip |
| Design Canvas | `design-canvas.jsx` | Side-by-side comparison grid for design variations |
| Deck Stage | `deck-stage.js` | Web component for single-file slide decks with keyboard nav |
| UI Kit | `ui-kit.jsx` | Button, Card, Badge, Input, Modal, Toast, Navbar, Sidebar |

### iOS Frame Rule

When making iPhone mockups, **always use `ios-frame.jsx`**. Never hand-write Dynamic Island, status bar, or Home Indicator. The component is calibrated to iPhone 15 Pro exact specifications.

## Design Methodology

### Junior Designer Workflow

You are the manager's junior designer. Don't produce a grand reveal — show assumptions and reasoning early, iterate based on feedback.

1. **Ask first** — 6-asset checklist (logo, product shots, UI screenshots, colors, fonts, guidelines)
2. **State assumptions** — `<!--ASSUMPTION: ... -->` comments in HTML
3. **Placeholder first** — gray boxes with text labels, not bad implementations
4. **Show early** — even gray boxes get feedback before full implementation
5. **Iterate** — fill real assets and content after direction is confirmed

### Core Asset Protocol

For any brand work, execute the 5-step protocol:

1. **Ask** — complete asset checklist, all items at once
2. **Search** — official channels (brand.com/brand, press kits, launch films)
3. **Download** — three fallback paths per asset type
4. **Verify + Extract** — check resolution, extract hex colors from real assets
5. **Freeze** — write `brand-spec.md` with paths and CSS variables

### Anti-AI Slop Rules

The plugin enforces quality by avoiding the visual lowest common denominator:

- No purple gradients as default palette
- No emoji as decorative icons (use Lucide, Feather, Phosphor)
- No "card + left border accent" as default layout
- No SVG silhouettes as illustrations
- No Inter as display typography (use Source Serif 4 or brand font)
- Use `oklch()` color space with CSS custom properties
- Use CSS Grid for precision layouts
- Use real content, not Lorem Ipsum

### Color System

All designs use the `oklch()` color space for perceptually uniform, harmonious palettes:

```css
:root {
  --color-primary: oklch(0.55 0.15 250);
  --color-surface: oklch(0.97 0.01 80);
  --color-ink: oklch(0.25 0.02 250);
  --color-accent: oklch(0.65 0.20 30);
}
```

## Usage Examples

### Landing page with style exploration

> "I want to make a SaaS product landing page. Show me 3 style directions."

Claudio will trigger `design-direction-advisor`, ask clarifying questions, then produce 3 differentiated directions using `design-canvas.jsx` for side-by-side comparison.

### Brand-specific design

> "Create a design for Stripe's new pricing page."

Claudio will trigger `core-asset-protocol`, search for Stripe's brand assets, extract colors from stripe.com, write a `brand-spec.md`, then produce a design faithful to Stripe's visual identity.

### App prototype

> "Design a Habit Tracker App prototype."

Claudio will use `ios-frame.jsx` for device framing, produce 5-7 screens in overview layout with proper information density, and follow `anti-slop-rules` for visual quality.

### Video export with music

> "Export my design as a video with tech background music."

Claudio will call `ExportVideo` with `bgm: "tech"`, rendering via Playwright and mixing BGM with ffmpeg.

## Scripts

All scripts in `scripts/` support a `--json` flag for structured output:

| Script | Purpose | Dependencies |
|--------|---------|-------------|
| `render-video.js` | HTML animation to MP4 | Node.js, Playwright, ffmpeg |
| `export-pdf.mjs` | HTML slides to vector PDF | Node.js, Playwright, pdf-lib |
| `html2pptx.js` | HTML to editable PowerPoint | Node.js, Playwright, pptxgenjs, sharp |
| `convert-formats.sh` | MP4 to 60fps MP4 + optimized GIF | ffmpeg |
| `add-music.sh` | Mix BGM track into video | ffmpeg |

Make scripts executable:

```bash
chmod +x scripts/convert-formats.sh scripts/add-music.sh
```

## References

The `references/` directory contains design methodology documentation:

- Workflow and process guidelines
- Animation best practices and common pitfalls
- React + Babel project setup
- Slide deck conventions
- Tweaks panel system
- Video export and audio design rules
- Content guidelines and verification procedures
- Design styles and direction frameworks
- Editable PPTX constraints
- Critique scoring guide
- SFX library reference

## License

MIT
