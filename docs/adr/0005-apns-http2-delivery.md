# ADR-0005: APNs HTTP/2 delivery from spark-api

- Date: 2026-06-05
- Status: Accepted
- Context: MODULE-B needs match/activity/message pushes without FCM in v1. Cloud function already persists device tokens (ADR-0002 / A.3).
- Decision: Use Node `http2` + ES256 JWT (`.p8` key) in `lib/apns.js`. Business events call `lib/push-triggers.js` (MODULE-B.4). When `APNS_*` env vars are unset, pushes are no-ops / `202 queued` on manual send endpoint.
- Consequences:
  - **Pros:** No extra npm deps; same env as API; iOS routing already in `SparkAppDelegate`
  - **Cons:** Synchronous send per request (acceptable for Staging); no retry queue until v2
- Alternatives: `node-apn` package (rejected: dependency weight); FCM (deferred: MODULE-B v2 / CN)

## Required cloud function env

See [cloudfunctions/spark-api/README.md](../../cloudfunctions/spark-api/README.md#apns-env-module-b3).

Configure via:

```bash
npx mcporter call cloudbase.manageFunctions \
  action=updateFunctionConfig \
  functionName=spark-api \
  envVariables='{"APNS_KEY_ID":"...","APNS_TEAM_ID":"...","APNS_PRIVATE_KEY":"-----BEGIN PRIVATE KEY-----\\n...","APNS_BUNDLE_ID":"com.spark.app","APNS_USE_SANDBOX":"true"}'
```

Replace `\\n` with literal newlines in PEM when using CloudBase console UI.
