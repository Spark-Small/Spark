# Spark design philosophy

## Principle

**形式必须绝对服从于功能。**  
一切不为核心体验服务的装饰，都是成本的浪费和注意力的干扰。

**Form must absolutely serve function.**  
Any ornament that does not serve the core experience is wasted cost and attention noise.

## What this means in practice

| Do | Don't |
|----|--------|
| One primary action per screen | Extra CTAs “for balance” |
| System materials for separation & readability | Fake glass, shadows, opacity cards |
| Real empty / error / loading states | Decorative skeleton shimmer everywhere |
| Remove stub UI (voice search, fake badges) until the flow exists | Ship “looks done” controls |
| Fewer, denser list rows with clear labels | Duplicate placeholder rows to fill the screen |

## Relationship to other rules

- **Liquid Glass** (`.cursor/rules/ios-liquid-glass.mdc`): allowed when it improves hierarchy and native feel — not as decoration.
- **HIG & a11y** (`.cursor/rules/ios-design-system.mdc`): mandatory; never sacrificed for visuals.
- **Cursor AI**: `.cursor/rules/ios-product-philosophy.mdc` (always on).

## Review question

Before merging UI: *Does this element help the user complete the core task on this screen?* If no, delete it.
