# Fasakhansta customer app

Flutter customer application for Fasakhansta. The package name is `faskhaninja`.

## Project structure

- `lib/main.dart`: application entry point.
- `lib/helpers/app/`: service initialization and root widget.
- `lib/helpers/networking/`: API access and endpoint definitions.
- `lib/helpers/notification_helper/`: push and local notification handling.
- `lib/helpers/utils/`: shared services, including location subscriptions.
- `lib/view/layout/`: feature screens, controllers, and models.
- `lib/view/custom_widgets/`: reusable widgets.
- `test/`: regression tests for wallet confirmations, location lifecycle, and
  address lookup freshness.
- `tool/check_places_web_callbacks.dart`: JavaScript callback smoke check using
  a local fake Maps service.

## Local checks

Use the Flutter version pinned in `.github/workflows/code-quality.yml` and keep
`pubspec.lock` committed for reproducible dependency resolution.

```sh
flutter pub get
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Format changed Dart files with `dart format <paths>` before submitting a change.
The pull request quality workflow checks the maintained location files, runs all
regression tests and the JavaScript callback check, and blocks analyzer errors in
the maintained helpers. Existing
warnings and informational lints remain visible without blocking that workflow.

Keep application behavior changes separate from broad formatting changes. Close
HTTP clients in `finally` blocks and cancel stream subscriptions when their owner
is disposed. Avoid logging credentials, authentication headers, notification
tokens, or message bodies. HTTPS uses the platform's certificate validation.

Address screens share active reverse-geocoding requests only when their
coordinates match exactly. Entries are removed after success or failure, so later
lookups always fetch again. The regression test compares eight simultaneous
identical lookups: eight geocoder calls before sharing and one while the shared
request is active. Other tests verify retries, fresh subsequent lookups, and
independent requests for different coordinates.

## Customer home

The general customer home uses the same six-second seafood film as the website,
bundled as `assets/splash_video/home_hero.mp4`, with a poster fallback. Playback is
silent and looping, and stops when the app or route is no longer visible.
Foreground controls and the home navigation overlay the video; other tabs keep
their existing navigation. Wallet balances, nearby branch logos and the contest
image come from their existing controllers/API responses, including live updates.
The delivery address is the only location selector on the home page.

The Hosting workflow deploys the built website through the official Firebase
Hosting REST API using the existing Hosting service account. It preserves the
cache headers and SPA rewrite from `firebase.json` and only releases a version
after every required content upload succeeds. Run the deployment helper with
`--dry-run` to validate the configuration and file manifest without credentials
or network writes.

## Order status labels

| API status | Display label |
| --- | --- |
| `pending` | Preparing |
| `shipped` | On the Way |
| `completed` | Delivered |

## Embedded checkout

Card and Vodafone Cash checkout stay in the embedded Paymob screen. Native bank
verification windows share the same in-app checkout; web builds include the
InAppWebView bridge and keep the hosted form in an iframe. No card data or
checkout URLs are logged by the payment screen.

For restaurant purchases the app reads the authenticated order every three
seconds while checkout is visible. Legacy online orders start with a null status;
the deployed backend's RestaurantOrderPayment activates them only after verifying
the gateway transaction. Explicit payment-status fields, when provided, take
precedence. Closing checkout or losing connectivity never implies success.
After confirmation, checkout is removed before tracking opens for that order,
so a repeated page event cannot pop tracking or submit another order.

The payment changes do not alter settlement, wallet balances, webhook verification
or the staff-controlled order lifecycle. Unit and widget tests use synthetic
checkout pages and responses and do not charge a live payment method.
