# Fasakhansta customer app

Flutter customer application for Fasakhansta. The package name is `faskhaninja`.

## Project structure

- `lib/main.dart`: application entry point.
- `lib/helpers/app/`: service initialization and root widget.
- `lib/helpers/networking/`: API access and endpoint definitions.
  `ApiClient` owns the shared HTTP pipeline; `ApiHelper` supplies application
  storage, translations, navigation, and the existing singleton entry point.
  `ApiResponse` and `ResponseState` remain available from `api_helper.dart`.
- `lib/helpers/notification_helper/`: push and local notification handling.
- `lib/helpers/utils/`: shared services, including location subscriptions.
- `lib/view/layout/`: feature screens, controllers, and models.
- `lib/view/custom_widgets/`: reusable widgets.
- `test/`: regression tests for wallet confirmations, location lifecycle, and
  address lookup freshness, plus request/header/error/callback contracts.
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

## Refactoring and Web review

See `docs/refactoring.md` for the current boundaries, preserved API contracts,
and the next feature slices. Changes are reviewed in small pull requests.

Same-repository pull requests build the actual Flutter application for Web and
export a downloadable Web artifact for seven days after the regression tests
pass. The tested artifact can be published to a separate review host. PR events
do not deploy to the live Firebase channel or publish mobile store builds.

Web review uses the application's existing API, so actions such as placing an
order still affect that API. Mobile Firebase initialization and direct FCM
sending are disabled on Web. Push notifications and native payment/sign-in
integrations still require Android/iOS verification. The Web build checks that
no PEM private-key block reaches its JavaScript output.

## Order status labels

| API status | Display label |
| --- | --- |
| `pending` | Preparing |
| `shipped` | On the Way |
| `completed` | Delivered |
