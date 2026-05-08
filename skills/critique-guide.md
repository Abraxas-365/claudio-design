---
name: critique-guide
description: 5-dimension design critique scoring model (each 0–10, total /50) with actionable fixes per dimension
autoload: true
agents: [design]
---

# Design Critique Guide

A structured 5-dimension scoring system for evaluating design work. Each dimension scores 0–10 for a total of /50. Every score includes rationale and 3 specific, actionable fixes.

## When to Use

- User asks for design feedback/review/critique
- Self-evaluation before delivery (recommended)
- Comparing multiple design directions
- Post-mortem on completed design work

## The 5 Dimensions

### Dimension 1 — Philosophical Coherence (0–10)
*"Does this design embody a clear design philosophy?"*

**What to evaluate:**
- Is there a recognizable design DNA? Can you name the influence?
- Are all elements unified by a single visual language?
- Does the design make a statement, or is it a collection of parts?
- Could you explain the "why" behind every major decision?

**Scoring guide:**
| Score | Description |
|-------|-------------|
| 0–2 | No discernible philosophy — random collection of trends |
| 3–4 | Hints of a direction but inconsistent — Dieter Rams headline + Material Design buttons |
| 5–6 | Clear direction but not fully committed — safe, doesn't offend or inspire |
| 7–8 | Strong philosophy carried through most elements — occasional breaks |
| 9–10 | Every pixel serves the philosophy — could be in a design book |

**Common fixes:**
1. Choose one design school/philosopher as anchor (see `design-direction-advisor` skill)
2. Remove elements that contradict the chosen philosophy
3. Strengthen the "signature detail" — one moment at 120%

### Dimension 2 — Visual Hierarchy (0–10)
*"Is information priority immediately clear?"*

**What to evaluate:**
- Can you identify the #1 most important element within 1 second?
- Is there a clear reading order (primary → secondary → tertiary)?
- Does the eye flow naturally through the content?
- Are interactive elements (CTAs, links) visually distinct from content?

**Scoring guide:**
| Score | Description |
|-------|-------------|
| 0–2 | Everything competes — wall of text, uniform sizing, no focal point |
| 3–4 | Primary element exists but secondary/tertiary levels are muddy |
| 5–6 | Hierarchy works but relies on size alone (no color, weight, or spacing) |
| 7–8 | Clear 3-level hierarchy with size, color, and spatial relationships |
| 9–10 | Masterful — guides the eye precisely, every level distinct and purposeful |

**Common fixes:**
1. Increase size contrast — make the hero 3× bigger than body, not 1.5×
2. Use color/weight to create secondary hierarchy (not just size)
3. Add white space to separate hierarchy levels (spacing > borders)

### Dimension 3 — Execution Craft (0–10)
*"How polished is the typography, spacing, color, and technical implementation?"*

**What to evaluate:**
- Typography: consistent sizes, proper line-height, appropriate tracking, text-wrap quality
- Spacing: consistent rhythm, alignment on grid, no orphaned elements
- Color: harmonious palette, sufficient contrast (4.5:1 AA), consistent usage
- Polish: borders, shadows, radius, transitions — do details hold up at zoom?

**Scoring guide:**
| Score | Description |
|-------|-------------|
| 0–2 | Sloppy — misaligned elements, inconsistent spacing, poor contrast |
| 3–4 | Functional but rough — spacing inconsistencies, default font sizes |
| 5–6 | Clean but generic — everything aligned, but no craft decisions |
| 7–8 | Polished — deliberate typography, harmonious colors, consistent rhythm |
| 9–10 | Meticulous — micro-typography perfect, color system rigorous, zero defects |

**Common fixes:**
1. Audit spacing with a ruler — are gaps between sections truly consistent?
2. Check all text contrast ratios (use oklch lightness channel to verify)
3. Reduce border-radius variance — pick 2-3 values and use them everywhere

### Dimension 4 — Functionality (0–10)
*"Does this solve the design problem it was given?"*

**What to evaluate:**
- Does it communicate the intended message?
- Can the user accomplish their goal? (if interactive)
- Is the content appropriate for the audience and context?
- Does it work at the intended viewing distance (phone/laptop/projector)?
- Are there usability issues? (unclear CTAs, hidden navigation, confusing flow)

**Scoring guide:**
| Score | Description |
|-------|-------------|
| 0–2 | Doesn't solve the problem — beautiful but wrong |
| 3–4 | Partially solves it — missing key content or broken interactions |
| 5–6 | Solves the problem but with friction — extra clicks, unclear labels |
| 7–8 | Solves it well — clear, usable, appropriate for context |
| 9–10 | Solves it elegantly — delightful, anticipates edge cases, reduces cognitive load |

**Common fixes:**
1. Re-read the brief — does the design actually deliver what was asked?
2. Test the primary user flow — can you complete the main task without confusion?
3. Check content appropriateness — is the tone/language/density right for the audience?

### Dimension 5 — Innovation (0–10)
*"Does this transcend the obvious?"*

**What to evaluate:**
- Would a viewer remember this design tomorrow?
- Does it offer something they haven't seen before?
- Is there a creative insight — a visual metaphor, unexpected layout, surprising interaction?
- Does it push the medium (HTML/CSS/JS) to do something impressive?

**Scoring guide:**
| Score | Description |
|-------|-------------|
| 0–2 | Template-level — could be any brand, any product |
| 3–4 | Professional but forgettable — competent execution of a common pattern |
| 5–6 | One interesting choice — a nice detail in an otherwise conventional design |
| 7–8 | Memorable — clear creative insight, distinctive approach |
| 9–10 | Breakthrough — reframes the problem, sets a new standard |

**Common fixes:**
1. Identify the "expected" solution for this category — then break one convention deliberately
2. Add one interaction or visual detail that surprises (but serves the content)
3. Look at the design schools framework — could a different philosophy add unexpected richness?

## Scoring Template

```markdown
## Design Critique: [Project Name]
> Date: YYYY-MM-DD
> Evaluator: Claudio Design Agent
> Source: [path to HTML]

### Summary
Total: XX/50
Grade: [see grade scale below]

### Scores

| Dimension | Score | Key Observation |
|-----------|-------|-----------------|
| Philosophical Coherence | X/10 | [one sentence] |
| Visual Hierarchy | X/10 | [one sentence] |
| Execution Craft | X/10 | [one sentence] |
| Functionality | X/10 | [one sentence] |
| Innovation | X/10 | [one sentence] |

### Dimension Details

#### 1. Philosophical Coherence — X/10
**Rationale**: [2-3 sentences explaining the score]

**Fixes**:
1. [Specific, actionable fix]
2. [Specific, actionable fix]
3. [Specific, actionable fix]

#### 2. Visual Hierarchy — X/10
[Same format...]

#### 3. Execution Craft — X/10
[Same format...]

#### 4. Functionality — X/10
[Same format...]

#### 5. Innovation — X/10
[Same format...]

### Overall Recommendation
[1-2 paragraphs: what's working, what to prioritize fixing, and whether the design is ready for delivery]
```

## Grade Scale

| Score | Grade | Meaning |
|-------|-------|---------|
| 45–50 | A+ | Exceptional — portfolio-worthy |
| 40–44 | A | Excellent — ready for delivery |
| 35–39 | B+ | Strong — minor refinements needed |
| 30–34 | B | Good — specific areas need attention |
| 25–29 | C+ | Adequate — significant improvements possible |
| 20–24 | C | Below expectations — major rework needed |
| <20 | D | Does not meet standard — restart recommended |

## Anti-Slop Bonus Check

In addition to the 5 dimensions, flag any anti-slop violations (see `anti-slop-rules` skill):
- Purple gradient without brand justification? Flag it.
- Emoji as icons? Flag it.
- Generic Inter headings? Flag it.
- SVG silhouette replacing real product image? Flag it.

These don't reduce the score directly but are listed as "Anti-Slop Flags" in the critique for immediate correction.

## Process

1. Open the design in a browser (or screenshot with Playwright)
2. Spend 10 seconds on first impression — note what you see first (hierarchy check)
3. Score each dimension independently
4. Write rationale and 3 fixes per dimension
5. Calculate total and assign grade
6. Write overall recommendation
7. Run anti-slop check
8. Deliver the critique
