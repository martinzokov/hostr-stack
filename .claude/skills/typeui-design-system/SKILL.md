---
name: "premium"
description: "Premium design skill for AI coding agents."
metadata:
  author: typeui.sh
  source: workspace-importer
  projectName: "VoxTale"
  projectLogoUrl: ""
  importSource: "Manual TypeUI setup"
  primaryColorReference: "#C82E23"
  surfaceColorReference: "#F0F5F4"
  textColorReference: "#111827"
  typographyScale: "Inter-style sans serif, 12/14/16/20/24/32 scale, medium labels, semibold headings."
  spacingScale: "4px base grid with 8px, 12px, 16px, 24px, and 32px layout steps."
  radiusScale: "6px controls, 8px cards, 12px overlays, nested radii reduced by inner padding."
---

# Design System — Agent Instructions

This skill describes the visual design language for all UI output. Every component, layout, and page should follow the design specs in the module files below. These describe *what the design looks like* — you choose how to implement the styles.

## Style
A clean, minimalist interface inspired by Apple's design language — pure backgrounds, precise typography, generous whitespace, and restrained color use that lets content breathe

## Before Writing Any Code

1. **Read every module that applies.** For a landing page, read at minimum: `layout.md`, `typography.md`, `colors.md`, `buttons.md`, `cards.md`, `shadows.md`, `radius.md`, `borders.md`. Do NOT write JSX until you have loaded all relevant modules.

## Critical Rules

- **Brand color precedence:** When `brand.md` is available, color tokens from `brand.md` overwrite same-name tokens in `colors.md`.

- **Tokens are AGNOSTIC, NOT Tailwind classes:** The tokens defined in the `.md` files (like `neutral-primary-soft`, `heading`, `border-default`) are agnostic design system tokens, NOT literal Tailwind classes. Do not blindly use classes like `bg-neutral-primary-soft` unless you have explicitly mapped them in the CSS/Tailwind configuration. You must implement the mapping yourself.

- **Cross-reference modules.** A card containing buttons must satisfy both `cards.md` AND `buttons.md`.
- **Dark mode is automatic.** The CSS custom properties resolve differently in light/dark via `@media (prefers-color-scheme: dark)`. Never manually swap colors.
- **Every interactive element needs hover, focus, and disabled states** — defined in the relevant module.
- **Use semantic HTML:** proper heading hierarchy (`h1`→`h6`), `<button>` for actions, `<a>` for navigation, ARIA attributes where needed.

## Module Index

### Foundation (read first for any UI work)
- [brand.md](brand.md) — Brand
- [colors.md](colors.md) — Color
- [typography.md](typography.md) — Typography
- [layout.md](layout.md) — Layout
- [radius.md](radius.md) — Radius
- [shadows.md](shadows.md) — Shadow
- [borders.md](borders.md) — Borders

### Components
- [buttons.md](buttons.md) — Button
- [button-group.md](button-group.md) — Button Group
- [cards.md](cards.md) — Card
- [inputs.md](inputs.md) — Input
- [alerts.md](alerts.md) — Alert
- [badges.md](badges.md) — Badge
- [lists.md](lists.md) — List
- [avatars.md](avatars.md) — Avatar
- [icon-shapes.md](icon-shapes.md) — Icon Shape
- [accordion.md](accordion.md) — Accordion
- [dropdown.md](dropdown.md) — Dropdown
- [modals.md](modals.md) — Modal
- [tabs.md](tabs.md) — Tabs
- [tables.md](tables.md) — Table
- [pagination.md](pagination.md) — Pagination
- [sidebars.md](sidebars.md) — Sidebar
- [radios-checkboxes-toggle.md](radios-checkboxes-toggle.md) — Radio, Checkbox, Toggle
- [tooltips-popovers.md](tooltips-popovers.md) — Tooltip, Popovers
- [content.md](content.md) — Content