# Layout & Spacing

## Spacing Rhythm

Base unit: **8px**. All spacing values should be multiples of 8px.

| Context | Value |
|---|---|
| Section vertical padding | 120px |
| Section header → content | 56px or 72px |
| Heading → paragraph | 16px |
| Container horizontal padding | 24px |
| Flex/grid row gap | 16px |
| Card grid gap | 24px |
| Wide component grid gap | 32px |
| Column layout gap | 56px |

## Container

Standard section container: max-width 1200px, centered, 24px horizontal padding.

Every major section wraps content in this container.

## Content Composition Order

Inside each section, follow this order:
1. Heading (`h1`–`h3`)
2. Leading paragraph
3. Normal paragraph(s)
4. Lists, CTA links, or component grids

## Section Pattern

Each section has:
- 120px vertical padding
- A background color (alternate between `neutral-primary-soft` and `neutral-secondary-soft`)
- A centered container (max-width 1200px, 24px horizontal padding)
- A section header area with 56px or 72px bottom margin
- Section content below

## Premium Product Landing Pages (Apple-style)

When building premium marketing or product landing pages, follow these specific layout patterns:
- **Hero Sections:** Use massive typography, centered alignment, and large floating product mockups. Add 120px top padding and 80px bottom padding.
- **Floating Mockups:** Product images (like laptops or phones) should break out of their containers slightly. Use object fit contain, extra large drop shadows, and scale up by 10% or 25%.
- **Image Containers:** Wrap mockups in a relative container with 16/10, 16/9, or 4/3 aspect ratios. If the container has a background color, use 32px border radius and hidden overflow. If the mockup is meant to float freely, use a transparent container.
- **Feature Grids:** Use a 12-column grid system. Mix full-width cards (12 columns wide) with half-width cards (6 columns wide) to create dynamic, magazine-like layouts.

## Motion & Animation

- Prefer CSS-native: `transition`, `animation`, `@keyframes`. Use Motion library only when CSS cannot achieve the behavior.
- Prioritize high-impact orchestrated moments over scattered micro-interactions. A single well-sequenced page-load animation using staggered `animation-delay` delivers more perceived quality than many isolated effects.
- Reserve scroll-triggered and hover transitions for moments that reinforce hierarchy or reward attention.

## Backgrounds & Visual Depth

- Default to clean, minimal backgrounds. White and light gray are primary surfaces.
- Apply subtle contextual treatments — gentle gradients, fine separators — that align with a minimalist aesthetic.
- Every decorative element must serve a compositional purpose (depth, separation, or emphasis). Avoid ornamental effects that compete with content. Let whitespace do the heavy lifting.

## Must

- All sections: consistent 120px vertical padding
- All containers: max-width 1200px, centered, 24px horizontal padding
- Section headers: 56px or 72px bottom margin
- Consistent vertical rhythm, no crowded sections
- Layouts readable and properly spaced on both desktop and mobile
