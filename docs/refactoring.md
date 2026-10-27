# Customer app refactoring

Baseline: `c860232bfdcf470dfb184870cbc62a9b6b6b7704` (`main`). The baseline
contains 344 Dart files under `lib/`, approximately 60,840 lines, and 86 calls to
the shared `ApiHelper` HTTP methods across 18 files. This is the customer Flutter
application; the ERP/backend repository is outside this change.

## First slice: shared networking

The five HTTP methods repeated connectivity checks, response mapping, transport
error handling, and completion callbacks. `ApiClient` now runs these through one
pipeline and accepts its dependencies explicitly. Tests use a local recording
Dio adapter, with no server, account, Hive box, or navigation state required.

`ApiHelper` remains the application singleton and inherits the same five method
signatures. It wires the production Dio logger, current Hive language/token,
translated messages, and the existing deferred login navigation. Existing
screens and controllers keep their imports and call sites. The mutable response
types live in `api_response.dart` and are re-exported by `api_helper.dart`.

Preserved contracts:

- GET/POST/PUT/PATCH/DELETE methods, URLs, query parameters, JSON and multipart
  bodies, upload/download callbacks, and caller header precedence.
- Language and token are read when each request is sent, including after logout.
- `hasToken: false` omits the stored bearer token; explicit headers still win.
- Only 200/201 map to `complete`; 401 maps to `unauthorized` and invokes the
  application's login handler. Other status codes keep their current error
  mapping and original response payload, including 204 and redirects.
- Redirect following remains disabled. No write retries or response caching are
  introduced, particularly for checkout/payment requests.
- Offline preflight skips Dio. Dio exceptions map to the translated generic
  error; raw socket exceptions retain their offline mapping.
- `onFinish` remains deferred and occurs once for each normalized result.

Changing status mappings, retry behavior, token storage, dependency versions,
payment rules, or UI layout is a separate behavior change.

## Web review

The pull request workflow compiles the same `lib/main.dart` entry point and
exports `fasakhansta-web-review` as a seven-day artifact for a separate review
host. PR events skip the existing live Firebase deployment and version cleanup.
Firebase preview deployment was verified to be blocked by missing
`serviceusage.services.get` permission; this change does not alter project IAM.

Web does not initialize Firebase/FCM in this application. Direct notification
sending and service-account token creation now exit before their native paths
on Web; release compilation eliminates the native-only signing material. A
post-build check rejects PEM private-key blocks in the emitted JavaScript.
Android/iOS behavior is preserved, but the existing native FCM service-account
credential must be moved out of the application, revoked/rotated, and replaced
by an authenticated server-side notification endpoint before a production
security release. Do not copy credentials into new services or test fixtures.

The review app uses existing API endpoints. UI review does not imply that test
orders or payments are sandboxed. Native push, Live Activities, platform sign-in
and payment browser behavior require device verification separately.

## Next slices

1. Move feature HTTP calls behind repositories, starting with cart/checkout.
   `CartController` currently combines request construction, payment-result
   routing, totals, quantity edits, notifications and UI loading. Characterize
   the server payloads and business outcomes before moving each responsibility.
2. Split the largest feature screens into widgets with explicit inputs:
   restaurant listing (1,062 lines at baseline), account (1,032), address entry
   (927), checkout/update-cart, and delegate request/map screens. Keep provider
   ownership and navigation behavior explicit and test the interactive flows.
3. Consolidate startup/provider ownership and audit async controller lifecycle,
   request races, and subscription disposal. Add targeted lifecycle tests before
   changing state management; keep Provider for this refactoring.
4. Resolve the separate Live Activity work in PR #8 and the older address
   selector PR #3 through their own reviews. This networking change does not
   merge or replace either branch.

Each slice needs regression coverage, analyzer checks on maintained files, a Web
review build, and relevant Android/iOS device checks before production rollout.
