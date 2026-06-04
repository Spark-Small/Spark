# Naming conventions

## Packages & targets

- `Spark{Feature}` — PascalCase, e.g. `SparkActivity`, `SparkMessages`
- Tests: `Spark{Feature}Tests`

## Swift

| Item | Convention |
|------|------------|
| View | `{Feature}RootView`, `ConversationDetailView` |
| ViewModel | `{Feature}ViewModel` |
| Repository protocol | `{Feature}Repository` |
| Live / Mock | `Live{Feature}Repository`, `Mock{Feature}Repository` |
| UseCase | `{Verb}{Noun}UseCase`, callable with `callAsFunction()` |
| DTO | `{Name}DTO`, `CodingKeys` → `snake_case` wire keys |

## Git

- Branch: `feat/scope`, `fix/scope`, `chore/scope`, `docs/scope`
- Commits: Conventional Commits — `feat(messages): add thread list`

## Localization keys

- Dot-separated: `tab.activity.browse`, `activity.browse.*`, `screen.activity.browse`, `messages.markRead`
- Add en + zh-Hans in `Spark/Localizable.xcstrings` when copy stabilizes
