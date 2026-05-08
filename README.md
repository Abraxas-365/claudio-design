# claudio-design

A Claudio plugin that transforms Claudio into a professional design creation tool. Built on the huashu-design methodology — a structured approach to generating high-quality, brand-faithful design mockups, prototypes, animations, and presentations.

## Installation

Add to `~/.claudio/init.lua`:

```lua
-- Minimal
claudio.plugin.use({ source = "Abraxas-365/claudio-design" })
```

Then run `:PluginSync` to download and activate.

### With config (recommended)

```lua
claudio.plugin.use({
  source = "Abraxas-365/claudio-design",
  config = function()
    require("claudio-design").setup({
      critic_model   = "claude-opus-4-6",  -- optional, default: haiku
      fidelity_model = "claude-opus-4-6",  -- optional, default: haiku
    })
  end,
})
```

Both models also accept environment variable overrides:
- `CLAUDIO_DESIGN_CRITIC_MODEL`
- `CLAUDIO_DESIGN_FIDELITY_MODEL`

## Prerequisites

- **Node.js >= 18** — required for all scripts
- **Playwright** — `npx playwright install chromium` (for RenderMockup, ReviewDesignFidelity, ExportVideo, ExportPDF)
- **ffmpeg** — `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux) — for ExportVideo / BGM mixing

Optional:
- `npm install sharp` — enables automatic PNG cropping in VerifyMockup / ReviewDesignFidelity
- `npm install pptxgenjs sharp` — required for ExportPPTX

## What This Plugin Does

1. **Replaces bundled design skills** with enhanced versions based on the huashu-design methodology
2. **Registers 7 design tools** — full design workflow from session creation to developer handoff
3. **Registers 3 export tools** — ExportVideo (MP4), ExportPPTX (PowerPoint), ExportPDF
4. **Provides a component library** — device frames, animation engine, UI kit, slide deck engine
5. **Enforces design quality** — anti-AI-slop rules, brand asset protocol, 5-dimension critique scoring

## Design Tools

All design tools register with `agents = {"design"}` and `capabilities = {"design"}`.

### ListDesigns

List all design sessions for the current project.

```json
{ "project_path": "/path/to/project" }
```

Returns an array of sessions:

```json
[
  {
    "name": "1720000000-landing-page",
    "path": "~/.claudio/projects/my-project/designs/1720000000-landing-page",
    "created_at": "1720000000",
    "has_bundle": false,
    "has_handoff": false,
    "screens": 3
  }
]
```

### CreateDesignSession

Scaffold a new design session directory.

```json
{
  "session_name": "landing-page",
  "project_path": "/path/to/project"
}
```

Creates `~/.claudio/projects/{slug}/designs/{timestamp}-{name}/` with subdirectories:
`screenshots/`, `bundle/`, `handoff/`, `exports/`, `components/`

Returns:

```json
{
  "success": true,
  "session_dir": "~/.claudio/projects/my-project/designs/1720000000-landing-page",
  "session_name": "landing-page",
  "manifest_path": "~/.claudio/.../manifest.json"
}
```

### RenderMockup

Screenshot all `[data-artboard]` elements in an HTML file using Playwright.

```json
{
  "html_file": "/path/to/design.html",
  "session_dir": "/path/to/session",
  "viewport_width": 1440,
  "viewport_height": 900
}
```

HTML files should have `data-artboard="screen-name"` on each screen element:

```html
<div data-artboard="hero" style="width:1440px;height:900px;">...</div>
<div data-artboard="pricing" style="width:1440px;height:900px;">...</div>
```

### VerifyMockup

Score a design screenshot using a vision LLM (5 dimensions, total 0-50).

```json
{
  "screenshot_path": "/path/to/screenshots/screen-1.png",
  "session_dir": "/path/to/session"
}
```

Returns:

```json
{
  "success": true,
  "verified": true,
  "score": 38,
  "model_used": "claude-haiku-4-5-20251001",
  "analysis": "{\"score\":38,\"dimensions\":{\"composition\":8,\"typography\":7,\"color\":8,\"spacing\":8,\"polish\":7},\"feedback\":\"Strong layout with room to refine micro-details.\",\"strengths\":[\"Clear hierarchy\",\"Consistent spacing\"],\"improvements\":[\"Add subtle shadows\",\"Tighten type scale\"]}"
}
```

Dimensions: composition, typography, color, spacing, polish (each 0-10).

### BundleMockup

Inline all CDN scripts and stylesheets into a self-contained HTML file.

```json
{ "session_dir": "/path/to/session" }
```

Reads `session_dir/index.html`, downloads CDN resources via `curl`, writes to `session_dir/bundle/mockup.html`.

### ExportHandoff

Generate a developer handoff package from an HTML mockup.

```json
{
  "session_dir": "/path/to/session",
  "framework": "tailwind"
}
```

Applies 12 extraction patterns (artboards, class inventory, images, links, fonts, icons,
components, animations, CSS tokens, colors, typography, framework utilities) and generates:

- `handoff/spec.md` — full design specification
- `handoff/tokens.css` — CSS custom properties
- `handoff/tailwind.config.js` — Tailwind theme extension (Tailwind only)
- `handoff/tokens-used.json` — raw extracted data

### ReviewDesignFidelity

Compare live implementations against original design screenshots using a vision LLM.

```json
{
  "session_name": "landing-page",
  "screens": [
    { "name": "hero",    "url": "https://example.com/" },
    { "name": "pricing", "url": "https://example.com/pricing" }
  ]
}
```

Returns:

```json
{
  "success": true,
  "overall_score": 84,
  "model_used": "claude-haiku-4-5-20251001",
  "screens": [
    {
      "name": "hero",
      "score": 87,
      "analysis": "{\"score\":87,\"issues\":[\"Font weight differs\"],\"matches\":[\"Layout\",\"Color palette\"],\"feedback\":\"High fidelity with minor typography deviation.\"}"
    }
  ]
}
```

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

### Full design workflow

```
> "Create a SaaS landing page design."
```

1. Claudio triggers `design-direction-advisor`, asks clarifying questions
2. Produces 3 directions using `design-canvas.jsx`
3. On approval: `CreateDesignSession` → `RenderMockup` → `VerifyMockup`
4. After iteration: `BundleMockup` → `ExportHandoff`

### Review live implementation

```
> "Review the fidelity of the landing page implementation."
```

Calls `ReviewDesignFidelity` with the live URL and compares against session screenshots.

### Video export with music

```
> "Export my design as a video with tech background music."
```

Calls `ExportVideo` with `bgm: "tech"`, renders via Playwright, mixes BGM with ffmpeg.

## Scripts

| Script | Purpose | Dependencies |
|--------|---------|-------------|
| `render-video.js` | HTML animation to MP4 | Node.js, Playwright, ffmpeg |
| `export-pdf.mjs` | HTML slides to vector PDF | Node.js, Playwright, pdf-lib |
| `html2pptx.js` | HTML to editable PowerPoint | Node.js, Playwright, pptxgenjs, sharp |
| `crop-image.js` | Read PNG, crop to ≤7000px, output base64 JSON | Node.js, (sharp optional) |
| `screenshot-url.js` | Take Playwright screenshot of URL, output base64 JSON | Node.js, Playwright |
| `convert-formats.sh` | MP4 to 60fps MP4 + optimized GIF | ffmpeg |
| `add-music.sh` | Mix BGM track into video | ffmpeg |

Make shell scripts executable:

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
