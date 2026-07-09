# Inputs

> Dependencies: `colors.md`, `radius.md`

## Core Specs

- **Display:** block, full width
- **Radius:** 16px (base)
- **Border:** 1px, border-default-medium
- **Background:** neutral-secondary-medium
- **Shadow:** shadow-xs
- **Font:** 14px, heading color
- **Padding:** 12px horizontal, 10px vertical
- **Placeholder:** body color
- **Transition:** all properties, 200ms

## Label

- Display: block
- Font: 14px, medium weight, heading color
- Margin bottom: 8px
- Label `htmlFor` must match the input `id`

## States

### Default
- Border: border-default-medium
- Background: neutral-secondary-medium

### Hover
- Border: border-default-strong

### Focus
- No outline
- Border: border-brand
- Ring: 1px, brand color

### Success
- Border: border-success
- Focus ring: 1px, success color

### Error / Danger
- Border: border-danger
- Focus ring: 1px, danger color

### Disabled
- Background: disabled
- Text: fg-disabled
- Cursor: not-allowed

## Input with Icons

- Icon size: 16x16px
- Icon color: body
- Container: relative positioned wrapper
- Start icon: absolutely positioned left, 12px left padding — input gets 36px left padding
- End icon: absolutely positioned right, 12px right padding — input gets 36px right padding
- Icons vertically centered within the wrapper

## Rules

- Every input must have a unique `id`
- Every label must have a matching `htmlFor`
- Padding: 12px horizontal, 10px vertical unless overridden for icon variants
- No arbitrary hex or hardcoded colors
