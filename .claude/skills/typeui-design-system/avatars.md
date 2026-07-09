# Avatars

> Dependencies: `colors.md`, `radius.md`

## Core Specs

- **Circular shape:** fully rounded (9999px)
- **Rounded square shape:** 16px radius
- **Default size:** 40x40px
- **Image fit:** cover

## Sizes

| Size | Dimensions | Radius |
|---|---|---|
| Extra Small | 18x18px | 6px |
| Small | 24x24px | 6px |
| Base | 32x32px | 16px |
| Large | 44x44px | 16px |
| XL | 56x56px | 16px |
| 2XL | 64x64px | 16px |

## Bordered Avatar

- 4px padding, fully rounded, 2px outline in border-default color
- Alternative: 2px box-shadow ring in border-default color

## Stacked Avatars

- Displayed in a row (flex)
- Each avatar: 40x40px, fully rounded, 2px border in border-buffer color
- Overlap: -16px negative margin on all except first

### Stacked Counter
- Same size as avatars (40x40px), fully rounded
- Background: dark-strong, text: white, 12px font, medium weight
- Same overlap margin as other avatars

## Avatar with Text

- Flex row, 10px gap between avatar and text
- Avatar: 40x40px, fully rounded, cover fit
- Name: heading color, medium weight
- Subtitle: 14px, body color
