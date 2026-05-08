---
name: core-asset-protocol
description: 5-step brand asset verification protocol — find, download, verify, and freeze brand assets before starting design work
autoload: true
agents: [design]
---

# Core Asset Protocol

> **This is the single most important constraint for brand design work.** Whether you execute this protocol directly determines if the output scores 40/100 or 90/100. Do not skip any step.

## When to Trigger

The task involves a specific brand — the user mentioned a product name, company name, or specific client (Stripe, Linear, Anthropic, Notion, DJI, etc.), regardless of whether the user proactively provided brand materials.

**Prerequisite**: Before running this protocol, you must have already verified the product/brand exists via WebSearch (see Principle #0 in `design-flow`).

## Core Principle: Assets > Specifications

**A brand is recognized by its assets**, not its color codes. Recognition priority:

| Asset Type | Recognition Value | Required? |
|-----------|------------------|-----------|
| **Logo** | Highest — instant brand recognition | **Any brand: mandatory** |
| **Product photos/renders** | Very high — the physical "hero" | **Physical products: mandatory** |
| **UI screenshots** | Very high — the digital "hero" | **Digital products: mandatory** |
| **Colors** | Medium — supplementary recognition | Supplementary |
| **Fonts** | Low — requires other assets for context | Supplementary |
| **Mood keywords** | Low — self-check only | Supplementary |

**Execution rules**:
- Extracting only colors + fonts, without logo / product images / UI → **violates this protocol**
- Using CSS silhouettes or hand-drawn SVGs to replace real product images → **violates this protocol**
- Can't find assets, don't tell the user, and forge ahead with generic fills → **violates this protocol**
- Better to stop and ask the user for assets than to fill with generic content

---

## Step 1 — Ask (Complete Asset Checklist, Ask All at Once)

Don't just ask "do you have brand guidelines?" — that's too vague. Ask by item:

```
About <brand/product>, do you have any of the following? Listed by priority:

1. Logo (SVG / high-res PNG) — required for any brand
2. Product photos / official renders — required for physical products (e.g. product photos)
3. UI screenshots / interface assets — required for digital products (e.g. app screenshots)
4. Color palette (HEX / RGB / brand colors)
5. Font list (Display / Body typefaces)
6. Brand guidelines PDF / Figma design system / brand website link

Send me what you have — I'll search for / extract / generate what's missing.
```

## Step 2 — Search Official Channels (By Asset Type)

| Asset | Search Path |
|-------|-------------|
| **Logo** | `<brand>.com/brand` · `<brand>.com/press` · `<brand>.com/press-kit` · `brand.<brand>.com` · homepage header inline SVG |
| **Product photos** | `<brand>.com/<product>` product page hero image + gallery · official YouTube launch film stills · official press release images |
| **UI screenshots** | App Store / Google Play product page · website screenshots section · official demo video stills |
| **Colors** | Website inline CSS / Tailwind config / brand guidelines PDF |
| **Fonts** | Website `<link rel="stylesheet">` references · Google Fonts tracking · brand guidelines |

**WebSearch fallback keywords**:
- Logo not found → `<brand> logo download SVG`, `<brand> press kit`
- Product photos not found → `<brand> <product> official renders`, `<brand> <product> product photography`
- UI not found → `<brand> app screenshots`, `<brand> dashboard UI`

## Step 3 — Download Assets (Three Fallback Paths Per Type)

### 3.1 Logo (Any Brand, Mandatory)

Three paths in descending success rate:
1. **Standalone SVG/PNG file** (ideal): Direct download from brand/press page
2. **Extract inline SVG from homepage HTML** (80% of cases): Fetch homepage HTML, grep for `<svg>...</svg>` logo node
3. **Official social media avatar** (last resort): GitHub/Twitter/LinkedIn company avatar (usually 400×400 or 800×800 transparent PNG)

### 3.2 Product Photos/Renders (Physical Products, Mandatory)

By priority:
1. **Official product page hero image** — usually 2000px+ resolution
2. **Official press kit** — high-res product photos available for download
3. **Official launch video stills** — download YouTube video with `yt-dlp`, extract frames with ffmpeg
4. **Wikimedia Commons** — public domain
5. **AI generation fallback** — use real product images as reference for AI-generated variants. **Never use CSS/SVG hand-drawings as substitutes**

### 3.3 UI Screenshots (Digital Products, Mandatory)

- App Store / Google Play product page screenshots
- Website screenshots section
- Official demo video stills
- Official Twitter/X launch screenshots (often the latest version)
- User's own account screenshots

### 3.4 Asset Quality Threshold: "5-10-2-8" Rule (Ironclad)

> Logo is exempt from this rule (use any logo you find — it's a recognition foundation).
> All other assets follow the 5-10-2-8 quality gate.

| Dimension | Standard | Anti-pattern |
|-----------|----------|-------------|
| **5 rounds of searching** | Multi-channel cross-search (website / press kit / social media / YouTube stills / Wikimedia) | Grabbing the first 2 results |
| **10 candidates** | Gather at least 10 options before filtering | Only finding 2, no choice |
| **Select 2 good ones** | Cherry-pick the 2 best from 10 | Using all of them = visual overload |
| **Each scores 8/10+** | Below 8 → **don't use it**; use honest placeholder or AI generation | Settling for 7-point assets |

**8/10 scoring dimensions**:
1. **Resolution** — ≥2000px (≥3000px for print/large screen)
2. **Copyright clarity** — official source > public domain > free stock > suspicious (suspicious = 0)
3. **Brand mood fit** — matches brand-spec.md mood keywords
4. **Light/composition consistency** — two assets placed together shouldn't clash
5. **Independent narrative ability** — can carry a narrative role alone (not just decoration)

## Step 4 — Verify + Extract

| Asset | Verification Action |
|-------|-------------------|
| **Logo** | File exists + opens as SVG/PNG + at least two versions (dark bg / light bg) + transparent background |
| **Product photos** | At least one 2000px+ resolution + clean background or de-backgrounded + multiple angles |
| **UI screenshots** | Real resolution (1x / 2x) + latest version (not outdated) + no user data leakage |
| **Colors** | `grep -hoE '#[0-9A-Fa-f]{6}' assets/<brand>-brand/*.{svg,html,css} \| sort \| uniq -c \| sort -rn \| head -20`, filter black/white/gray |

**Watch for demo brand contamination**: Product screenshots often contain demo brand colors (e.g., a tool's screenshot showing a different brand's red) — that's not the tool's own color.

**Brand multi-facet**: Same brand's marketing site colors and product UI colors are often different (e.g., marketing site: warm cream + orange; product UI: charcoal + lime). **Both are real** — choose the right facet for the deliverable.

## Step 5 — Freeze to `brand-spec.md`

Write a specification file that becomes the single source of truth:

```markdown
# <Brand> · Brand Spec
> Collection date: YYYY-MM-DD
> Asset sources: <list download sources>
> Asset completeness: <complete / partial / inferred>

## Core Assets (First-class Citizens)

### Logo
- Primary: `assets/<brand>-brand/logo.svg`
- Light-background inverse: `assets/<brand>-brand/logo-white.svg`
- Usage: <opener/closer/corner watermark/global>
- Prohibited transforms: <no stretching/recoloring/adding strokes>

### Product Photos (physical products — required)
- Hero angle: `assets/<brand>-brand/product-hero.png` (2000x1500)
- Detail shots: `assets/<brand>-brand/product-detail-1.png`
- Scene shot: `assets/<brand>-brand/product-scene.png`

### UI Screenshots (digital products — required)
- Home: `assets/<brand>-brand/ui-home.png`
- Core feature: `assets/<brand>-brand/ui-feature-<name>.png`

## Supplementary Assets

### Color Palette
- Primary: #XXXXXX  <source annotation>
- Background: #XXXXXX
- Ink: #XXXXXX
- Accent: #XXXXXX
- Prohibited colors: <colors the brand explicitly doesn't use>

### Typography
- Display: <font stack>
- Body: <font stack>
- Mono (data HUD): <font stack>

### Signature Details
- <which details get "120% treatment">

### Prohibited Zone
- <explicitly off-limits: e.g., Brand X never uses blue>

### Mood Keywords
- <3-5 adjectives>
```

**Post-spec execution discipline (mandatory)**:
- All HTML must **reference** asset file paths from `brand-spec.md` — no CSS silhouettes
- Logo as `<img>` referencing real file — never redraw
- Product images as `<img>` referencing real files — never CSS silhouette
- CSS variables from spec: `:root { --brand-primary: ...; }`, HTML only uses `var(--brand-*)`
- Brand consistency shifts from "self-discipline" to "structural enforcement"

## Failure Fallbacks (By Asset Type)

| Missing | Action |
|---------|--------|
| **Logo completely unfindable** | **Stop and ask the user** — don't proceed without it |
| **Product photos (physical)** | AI generation with official reference as base → ask user → honest placeholder (gray block + "product image pending" label) |
| **UI screenshots (digital)** | Ask user for their own account screenshot → official demo video stills. Don't use mockup generators |
| **Colors completely unfindable** | Enter Design Direction Advisor mode, recommend 3 directions, mark assumptions |

**Prohibited**: Silently using CSS silhouettes or generic gradients when assets are missing. **Better to stop and ask than to fake it.**

## Protocol Cost vs. Not Doing It

| Scenario | Time |
|----------|------|
| Protocol done correctly | Download logo 5 min + 3-5 product photos 10 min + grep colors 5 min + write spec 10 min = **30 minutes** |
| Skipping the protocol | Generic output → user rework 1-2 hours, possibly full redo |

**This is the cheapest stability investment.** Especially for client work, launches, and important projects — 30 minutes of asset protocol is insurance.
