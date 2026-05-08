---
name: anti-slop-rules
description: Anti-AI slop checklist — avoid the visual lowest common denominator that makes every AI output look the same
autoload: true
agents: [design]
---

# Anti-AI Slop Rules

## What Is AI Slop? Why Fight It?

**AI slop = the most common "visual lowest common denominator" in AI training data.**

Purple gradients, emoji icons, rounded cards with left border accents, SVG-drawn faces — these are slop not because they're ugly, but because **they are the default AI output mode and carry zero brand information**.

**The logic chain**:
1. User asks you to design → they want **their brand recognized**
2. AI default output = training data average = all brands blended = **no brand recognized**
3. AI default output = diluting the user's brand into "another AI-made page"
4. Anti-slop isn't aesthetic snobbery — it's **protecting the user's brand identity**

This is why the Core Asset Protocol is the hardest constraint — **following the spec is the positive way to fight slop** (doing the right thing). This checklist is the negative way (not doing the wrong thing).

---

## Elements to Avoid (With Reasoning)

| Element | Why It's Slop | When You Can Use It |
|---------|--------------|-------------------|
| **Aggressive purple gradients** | AI training data's universal "tech feel" formula — appears on every SaaS/AI/web3 landing page | Brand itself uses purple gradients (e.g., Linear in some contexts), or task is satirizing/showcasing slop |
| **Emoji as icons** | Training data puts emoji on every bullet point — the "not professional enough, use emoji to fill" disease | Brand itself uses emoji (e.g., Notion), or product audience is children/casual |
| **Rounded card + left colored border accent** | 2020-2024 Material/Tailwind era's overused combination, now visual noise | User explicitly requests it, or it's preserved in brand spec |
| **SVG-drawn imagery (faces/scenes/objects)** | AI-drawn SVG people always have misaligned features and wrong proportions | **Almost never** — use real images (Wikimedia/Unsplash/AI-generated), or leave honest placeholder |
| **CSS silhouettes replacing real product photos** | Produces "generic tech animation" — black background + orange accent + rounded rectangles, any physical product looks the same, brand recognition = zero | **Almost never** — run Core Asset Protocol for real product images first |
| **Inter/Roboto/Arial/system fonts as display** | Too common — reader can't tell if this is "a designed product" or "a demo page" | Brand spec explicitly uses these fonts (e.g., Stripe uses Sohne/Inter variant, but customized) |
| **Cyber neon / dark blue `#0D1117`** | GitHub dark mode aesthetic copied to death | Developer tool product where brand itself goes this direction |
| **Flat icon sets (Flaticon-style stock)** | Generic, undifferentiated, communicates "we didn't care enough to choose" | Use proper icon libraries: Lucide, Feather, Phosphor — or no icons at all |

**Judgment boundary**: "Brand itself uses it" is the **only** valid exception. If the brand spec explicitly says purple gradient, then use it — at that point it's not slop, it's a brand signature.

---

## What to Do Instead (Positive Rules)

### Typography
- **Display**: Use a distinctive typeface — Source Serif 4, Fraunces, Newsreader, EB Garamond for serifs; or the brand's own display face
- **Body/UI**: Inter is fine for body text, never for display headings
- **Pairing**: One display + one body face. Don't mix three serif fonts

### Colors
- Use `oklch()` color space with CSS custom properties — perceptually uniform, better for generating harmonious palettes
- Never hardcode hex values inline — define CSS custom properties in `:root`
- All colors come from brand spec or a deliberate system, never invented on the fly
- Example: `--color-primary: oklch(0.55 0.15 250); --color-surface: oklch(0.97 0.01 80);`

### Layout
- **CSS Grid** for precision layouts — not flexbox-everything
- `text-wrap: pretty` for better text wrapping
- Use advanced CSS: `container-queries`, `has()`, `light-dark()` where appropriate
- These typographic details are the "taste tax" that distinguishes designer output from generic AI output

### Content
- Use **real content** over Lorem Ipsum — make up plausible data if needed
- If you don't have real content, write realistic placeholder that matches the domain
- Never add filler: decorative stats, meaningless numbers, stock quotes

### Images
- Prefer AI-generated images (for illustrations) over SVG hand-drawings
- Real photography from Unsplash/Wikimedia/official sources for product/editorial content
- HTML screenshots only when exact data tables are needed

### Contrast & Legibility
- **Minimum 4.5:1 contrast ratio** for all text (WCAG AA)
- Test light text on colored backgrounds — common failure point
- Use tools or `oklch` lightness channel to verify

### Animation
- One well-orchestrated page-load animation > scattered micro-interactions
- No animation within the canvas that mimics browser chrome (progress bars, timestamps) — that conflicts with Stage controls

---

## Quick Reference Table

| Category | Avoid | Use Instead |
|----------|-------|-------------|
| Fonts | Inter/Roboto/Arial for display | Distinctive display + system body pair |
| Colors | Purple gradients, random hex | Brand colors / `oklch()` system |
| Containers | Rounded + left border accent | Honest boundaries/dividers |
| Images | SVG-drawn people/objects | Real assets or placeholder |
| Icons | **Decorative** icons everywhere | Only icons that carry information |
| Filler | Invented stats/quotes for decoration | White space or real content |
| Animation | Scattered micro-interactions | One orchestrated page load |

---

## Anti-Example Isolation (For Demo Content)

When the task itself is about demonstrating bad design (e.g., "what is AI slop?", comparison reviews), **don't fill the whole page with slop**. Use an **honest bad-sample container** — dashed border + "Anti-example — don't do this" corner badge. The anti-example serves the narrative without polluting the page's main visual tone.

Not a hard template rule, but a principle: **anti-examples should be visually identifiable as anti-examples**.

---

## Taste Anchors (Defaults When No Design System)

When there's no design system and no brand context, default to these:

| Dimension | Prefer | Avoid |
|-----------|--------|-------|
| **Typography** | Serif display (Newsreader/Source Serif/EB Garamond) + `-apple-system` body | All-Inter or all-system-font — no personality |
| **Color** | One warm base + **single** accent throughout (rust orange/forest green/deep red) | Multi-color clusters (unless data truly has ≥3 categorical dimensions) |
| **Density (default: restrained)** | One fewer container, one fewer border, one fewer decorative icon — give content breathing room | Every card with meaningless icon + tag + status dot |
| **Density (exception: high-density)** | AI/data/context-aware products need ≥3 visible differentiating data points per screen | Single button + clock — the "intelligence" isn't communicated |
| **Signature detail** | One "screenshot-worthy" moment: faint oil-painting texture / serif italic pull quote / full-screen black waveform | Evenly distributed effort = nothing stands out |

**Two principles working together**:
1. Taste = one detail at 120%, everything else at 80% — not uniformly refined, but refined in the right place
2. Subtraction is the fallback, not a universal law — when the product's core value needs information density (AI/data/contextual), addition takes priority over restraint
