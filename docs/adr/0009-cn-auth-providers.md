# ADR-0009: CN third-party authentication providers

- Date: 2026-06-08
- Status: Accepted
- Context: Email/password login does not match CN user habits. App Store Guideline 4.8 requires Sign in with Apple when offering third-party login. MODULE-H previously No-Go for WeChat SDK; product direction now prioritizes CN auth for domestic distribution.
- Decision: Replace login UI with **WeChat**, **carrier phone one-tap** (Aliyun + Tencent with primary/fallback), and **Alipay**. Keep **Apple** as secondary provider. Extend `AuthService` + `/v1/auth/*` token exchange; native SDKs live in App target behind `SPARK_HAS_*` flags; Staging bridge magic tokens for QA without vendor credentials.
- Consequences:
  - **Pros:** Matches CN expectations; clean protocol boundary in `SparkAuth`; staging smoke keeps internal email auth.
  - **Cons:** Large vendor binaries; ongoing compliance (ICP, privacy labels, SDK updates); dual phone SDK increases bundle size.
- Alternatives considered:
  - SMS OTP fallback — rejected (user chose one-tap only).
  - WeChat-only — rejected (phone + Alipay required for coverage).
