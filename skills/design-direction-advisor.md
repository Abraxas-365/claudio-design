---
name: design-direction-advisor
description: When the brief is vague, generate 3 differentiated design directions from 5 schools × 20 philosophies, with live HTML demos for user selection
autoload: true
agents: [design]
---

# Design Direction Advisor

## When to Trigger

The user has **no design context** and **vague requirements**:
- "Make it look good"
- "Help me design something"
- "I don't know what style I want"
- "Design a landing page" (no brand, no references, no mood)
- Requirements gathered but zero visual direction given

**Do not guess a direction.** Enter this advisory flow instead.

## The Framework: 5 Schools × 20 Philosophies

### School 1 — Information Architecture
*"Data drives the form. Clarity is beauty."*

| Philosophy | DNA | When to Recommend |
|-----------|-----|-------------------|
| **Edward Tufte** | Maximized data-ink ratio, chartjunk elimination, small multiples, micro-typography | Data-heavy dashboards, analytics, research reports |
| **Pentagram** | Systematic identity, grid discipline, type-as-structure, institutional gravitas | Corporate identity, brand systems, institutional sites |
| **Isotype (Neurath)** | Pictographic communication, universal symbols, quantity visualization, democratic access | Public-facing data, infographics, educational content |
| **Paula Scher** | Expressive typography as architecture, scale contrast, paint-brush energy, cultural institution aesthetic | Cultural events, exhibitions, bold editorial |

### School 2 — Motion Poetics
*"Movement is meaning. Code is choreography."*

| Philosophy | DNA | When to Recommend |
|-----------|-----|-------------------|
| **Field.io** | Data-driven particle systems, emergent behavior, organic geometry from algorithms | Tech product launches, AI/ML visualization, generative art |
| **Zeitguised** | Simulated material physics, uncanny surfaces, 3D textile/liquid forms | Fashion tech, material innovation, luxury products |
| **Refik Anadol** | Machine learning data sculptures, environmental projection, synesthesia visualization | Immersive experiences, art installations, spatial computing |
| **Zach Lieberman** | Poetic code, hand-gesture interaction, typographic motion, openFrameworks aesthetic | Creative tools, artist portfolios, experimental interfaces |

### School 3 — Minimalism
*"Less, but more considered."*

| Philosophy | DNA | When to Recommend |
|-----------|-----|-------------------|
| **Kenya Hara** | White as possibility (not absence), tactile emptiness, the quality of "nothing" | Wellness, meditation, premium consumer, Japanese aesthetics |
| **Dieter Rams** | 10 principles, honest materials, quiet confidence, systematic restraint | Hardware products, design tools, engineering-driven brands |
| **Jony Ive** | Material honesty through glass/aluminum, precision radius, singular focus, breath-held silence | Consumer electronics, premium SaaS, Apple ecosystem |
| **Naoto Fukasawa** | "Without thought" design, disappearing interface, found-object familiarity | Everyday tools, ambient computing, smart home |

### School 4 — Expressive Generativism
*"Rules exist to be broken with intent."*

| Philosophy | DNA | When to Recommend |
|-----------|-----|-------------------|
| **Stefan Sagmeister** | Provocative honesty, hand-made meets digital, emotional impact over beauty | Creative agencies, art publications, personal brands |
| **Experimental Jetset** | Helvetica-as-ideology, systematic rebellion, Bauhaus-meets-punk, reduction as statement | Design studios, cultural institutions, independent publishers |
| **David Carson** | Anti-legibility as expression, grunge typography, surf-culture energy, deliberate chaos | Music, youth culture, counter-culture brands, editorial |
| **Marian Bantjes** | Ornament as content, mathematical patterns, intricate hand-work digitized | Luxury packaging, wedding/events, editorial illustration |

### School 5 — Contemporary East Asian
*"Tradition and technology in conversation."*

| Philosophy | DNA | When to Recommend |
|-----------|-----|-------------------|
| **Kashiwa Sato** | Extreme simplification, iconic reduction (Uniqlo, 7-Eleven), brand as single gesture | Global brands seeking universal recognition, retail |
| **Nendo** | "!" moments in everyday objects, hidden wit, playful minimalism | Product design, consumer goods, experience design |
| **Wang Zhihong** | Typography as architecture, Chinese-Western hybrid, structural poetry | Publishing, bilingual design, cultural exchange |
| **Jianping He** | Calligraphic abstraction, ink-meets-pixel, East-West philosophical tension | Cultural institutions, art exhibitions, heritage brands |

## Advisory Process (6 Phases)

### Phase 1 — Understand the Brief

Ask focused questions:
1. What is the product/service?
2. Who is the target audience?
3. What's the deliverable? (landing page, app, dashboard, presentation)
4. What feeling should the viewer have? (3 adjectives)
5. Any brands you admire? (even outside your industry)
6. Any hard constraints? (existing colors, required content, platform)

### Phase 2 — Select 3 Directions

Choose 3 philosophies from **different schools** that could serve the brief. The selections should be:
- **Direction A**: The safest, most conventional choice for this domain
- **Direction B**: A refined, elevated choice that adds distinction
- **Direction C**: An unexpected choice that reframes the problem

Each direction must come from a different school. Avoid two directions from the same school.

### Phase 3 — Name and Describe Each Direction

For each direction, provide:
- **Name**: A short, evocative title (not the philosopher's name)
- **Philosophy source**: Which school × philosopher inspired it
- **Design DNA**: 3-4 defining visual characteristics
- **Color system**: 4-5 oklch tokens
- **Typography**: Display + body pair
- **Layout**: Grid strategy
- **Signature detail**: The one "120% moment"
- **Risk**: What could go wrong with this direction

### Phase 4 — Generate Visual Demos

Create a single HTML file with 3 mini-demos, each showing a representative section (hero, card, or data display) in that direction's visual language.

Use `design-canvas.jsx` for side-by-side presentation:

```jsx
<DesignCanvas columns={3} labels={['Direction A: Quiet Authority', 'Direction B: Data Poetry', 'Direction C: Broken Grid']}>
  <DirectionA />
  <DirectionB />
  <DirectionC />
</DesignCanvas>
```

Each demo should be ~300px tall, showing enough to communicate the direction without being a full mockup.

### Phase 5 — Present and Wait

Show the user:
1. The 3 directions side by side
2. Brief rationale for each
3. What each direction does well and what it risks

**Stop and wait for the user to choose.** Do not proceed to full mockup until they pick a direction (or ask to mix elements).

### Phase 6 — Execute

User picks a direction → hand off to `mockup` or `hifi` skill with the chosen direction as the design brief.

If user wants to mix: document which elements from which directions, create a combined design system, then execute.

## Example Recommendations by Product Type

| Product Type | Direction A (Safe) | Direction B (Elevated) | Direction C (Unexpected) |
|-------------|-------------------|----------------------|------------------------|
| B2B SaaS | Pentagram (systematic) | Dieter Rams (honest) | Tufte (data-rich) |
| Consumer App | Jony Ive (minimal) | Naoto Fukasawa (invisible) | Zach Lieberman (poetic) |
| AI/ML Product | Field.io (generative) | Tufte (data-ink) | Kenya Hara (empty) |
| E-commerce | Kashiwa Sato (iconic) | Pentagram (systematic) | Marian Bantjes (ornamental) |
| Creative Agency | Sagmeister (provocative) | Experimental Jetset (systematic) | Wang Zhihong (typographic) |
| Cultural Institution | Paula Scher (expressive) | Jianping He (calligraphic) | Isotype (pictographic) |

## Anti-Slop Note

Even in the advisory phase, the mini-demos must follow anti-slop rules:
- No purple gradients (unless the chosen philosophy calls for it)
- No emoji icons
- Use oklch color tokens
- Real or realistic placeholder content
- Distinctive typography choices per direction
