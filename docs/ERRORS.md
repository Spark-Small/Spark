# Error handling

## Layers

| Layer | Type | User-facing |
|-------|------|-------------|
| HTTP | `AppError` via `HTTPErrorMapper` | `errorDescription` + recovery where defined |
| Feature | e.g. `MessagesError`, `AuthError` | `LocalizedError` |
| ViewModel | `LoadState.failure(String)` or typed state | Copy from `errorDescription`, not `localizedDescription` of raw `NSError` |

## Rules

- Never show bare `"Network error"` or `error.localizedDescription` for unknown failures without context.
- `try?` only with a comment why failure is safe.
- `401` → clear session (auth); do not infinite-retry authenticated calls.
- Log with `Logger`; never log tokens, email, or message body (`.privacy(.private)` when needed).

## Auth

- Invalid credentials → `AuthError.invalidCredentials` with localized message.
- Apple Sign In cancel → silent return (no failure banner).
- Authenticated `401` → `UnauthorizedSessionInterceptor` invokes `AuthSessionInvalidating`, then `AuthViewModel.handleSessionInvalidated()` clears Keychain (see `ClearLocalSessionUseCase`). Login attempts without `Authorization` header do not trigger invalidation.
