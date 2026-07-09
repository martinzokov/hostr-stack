# Cards

> Dependencies: `colors.md`, `radius.md`, `shadows.md`, `typography.md`

## Core Specs

- **Background:** neutral-primary-soft
- **Border:** 1px, border-default color
- **Radius:** 16px (base)
- **Shadow:** shadow-xs

## Card Heading

- Desktop: 20px, medium weight, heading color
- Mobile: 16px, medium weight, heading color
- Never skip heading levels — the page hierarchy must logically arrive at the card heading level.

## States

### Static Card (no interactivity)
- Background: neutral-primary-soft
- Border: 1px, border-default
- Radius: 16px
- Shadow: shadow-xs
- No hover styles. Non-interactive cards must NOT have hover background changes.

### Interactive Card (clickable)
- Same base styles as static card
- Hover: neutral-secondary-medium background
- Transition: colors
- Cursor: pointer

## Rules

- Background: neutral-primary-soft
- Border: 1px, border-default
- Radius: 16px
- Shadow: shadow-xs
- Interactive hover: neutral-secondary-medium background
- Non-interactive: no hover styles

## Premium Marketing Cards (Apple-style)

When building feature grids for premium landing pages:
- **Radius:** Use massive border radius (32px).
- **Overflow:** Always use hidden overflow.
- **Padding:** Use generous internal padding (40px or 64px).
- **Structure:** Split the card into a text area (using the `neutral-primary-soft` background token) and an image area (using the `neutral-secondary-soft` background token).
- **Mockups inside cards:** Place product PNGs in the image area using object fit contain, extra large drop shadow, and scale them up (110% or 125% scale) so they break the bounds of their internal container slightly.
