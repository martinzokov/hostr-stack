# Shadows

| Token | CSS value |
|---|---|
| shadow-2xs | `0 1px rgb(0 0 0 / 0.04)` |
| shadow-xs | `0 1px 2px 0 rgb(0 0 0 / 0.04)` |
| shadow-sm | `0 2px 4px 0 rgb(0 0 0 / 0.06), 0 1px 2px -1px rgb(0 0 0 / 0.04)` |
| shadow-md | `0 4px 8px -2px rgb(0 0 0 / 0.08), 0 2px 4px -2px rgb(0 0 0 / 0.04)` |
| shadow-lg | `0 12px 20px -4px rgb(0 0 0 / 0.08), 0 4px 8px -4px rgb(0 0 0 / 0.04)` |
| shadow-xl | `0 20px 32px -8px rgb(0 0 0 / 0.1), 0 8px 16px -6px rgb(0 0 0 / 0.06)` |
| shadow-2xl | `0 28px 56px -16px rgb(0 0 0 / 0.2)` |

## Component Mapping

| Component type | Token |
|---|---|
| Subtle separators, tiny UI details | shadow-2xs or shadow-xs |
| Inputs, buttons, small controls, lightweight cards | shadow-xs or shadow-sm |
| Standard cards, popovers, dropdowns | shadow-md |
| Prominent cards, sticky surfaces | shadow-lg |
| Modals, high-priority overlays | shadow-xl |
| Hero overlays, top-level emphasis (sparingly) | shadow-2xl |

## Rules

- Use only these tokens — no custom box-shadow values
- Keep elevation steps intentional; avoid jumping multiple levels
- Components in the same family share the same baseline elevation
- Hover/focus on interactive elevated elements: step up by one level
- Never stack multiple shadow tokens on one element
- Never use shadow-xl/shadow-2xl for dense list items or body containers
