# Typography

> Dependencies: `colors.md`

## Core Rules

- **Font:** "Miranda Sans", sans-serif — configured at app level, never override
- **Headings:** semibold weight (600), heading text color
- **Body copy:** body text color, never use brand color for paragraphs longer than one sentence
- **Semantic HTML:** Use `h1`–`h6` in order, never skip levels

## Heading Scale

### Desktop

| Element | Size | Line-height | Letter-spacing | Margin-bottom |
|---|---|---|---|---|
| `Hero` | 80px | 1.05 | -1.5px | 32px |
| `h1` | 56px | 1.05 | -1.5px | 24px |
| `h2` | 48px | 1.07 | -0.5px | — |
| `h3` | 36px | 1.1 | — | — |
| `h4` | 28px | 1.2 | — | — |
| `h5` | 24px | 1.3 | — | — |
| `h6` | 20px | 1.3 | — | — |

### Responsive

| Element | Tablet (≥768px) | Mobile (default) |
|---|---|---|
| `Hero` | 64px | 44px |
| `h1` | 44px | 34px |
| `h2` | 40px | 32px |
| `h3` | 30px | 26px |
| `h4` | 24px | 22px |
| `h5` | 22px | 20px |
| `h6` | 18px | 18px |

Mobile-first: start with mobile sizes, scale up at tablet and desktop breakpoints.

Never reduce line-height below 1.05 for any heading.

### Premium Marketing Headings
For premium product pages (Apple-style):
- **Hero Title:** Use the `Hero` scale (44px mobile, 64px tablet, 80px desktop), 1.05 line-height, -1.5px letter-spacing, semibold weight (600).
- **Section Title:** Use the `h2` scale (32px mobile, 40px tablet, 48px desktop), 1.07 line-height, -0.5px letter-spacing, semibold weight (600).
- **Eyebrow Text:** Place above hero titles. Use 16px size, medium weight (500), body text color, uppercase, wide letter-spacing, and 16px bottom margin.

## Paragraphs

### Leading Paragraph
- Size: 18px
- Weight: normal
- Color: body
- Line-height: 1.6
- Max width: ~68 characters

### Normal Paragraph
- Size: 16px
- Weight: normal
- Color: body
- Line-height: 1.6
- Max width: ~68 characters

### Small Supporting Copy
- Size: 14px
- Weight: normal
- Color: body
- Line-height: 1.5
- Use only for helper text, legal text, captions, metadata.

## UI Labels

| Context | Size | Weight |
|---|---|---|
| Button labels | 16px | 500 (medium) |
| Input labels | 14px or 16px | 500 (medium) |
| Captions / meta / badges | 12px or 14px | 500 (medium) |

Do not apply paragraph line-height (1.6) to control labels.

## Links

- **Inline links:** Same size as surrounding text, fg-brand color, underline, hover → no underline
- **CTA links:** fg-brand color, medium weight, underline, hover → no underline

## Emphasis

- `<strong>` for high-priority emphasis in body text
- `<em>` for tone emphasis only, not visual hierarchy
- All-caps only for short labels: uppercase, 0.4px letter-spacing, 12px or 14px

## Dark Mode

Hierarchy stays identical. Only color tokens change (automatic via CSS custom properties). Size, weight, and spacing remain constant.
