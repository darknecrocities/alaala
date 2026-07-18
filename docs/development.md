# Development guide

## Requirements

- Flutter SDK `3.11` or later, as declared in [`pubspec.yaml`](../pubspec.yaml)
- A configured iOS Simulator, Android emulator, or physical device

## Local workflow

```bash
flutter pub get
flutter run
```

Useful verification commands:

```bash
flutter analyze
flutter test
```

## Conventions

- Keep models immutable and add fields through `copyWith` where appropriate.
- Keep presentation components in `lib/widgets/` and application behaviour in screens or services.
- Use the existing warm palette and high-legibility patterns unless a deliberate accessibility improvement calls for a change.
- Do not add real keys to the repository. Copy `.env.example` to `.env` only for a future, explicitly implemented integration.
- Update the relevant document in [`docs/`](README.md) whenever functionality, data handling, or setup changes.

## Test status

`flutter analyze` passes for the current source.

The current widget test in [`test/widget_test.dart`](../test/widget_test.dart) has an expectation mismatch: it expects the text `Sino ang kasama ko?` immediately after pumping `AlaAlaApp`, but the default selected tab is **Tahanan**, while that text belongs to MemoryLens. Update the test to navigate to MemoryLens, or remove that expectation from the home-screen test, before treating `flutter test` as a passing gate.

## Before merging a change

1. Run `flutter analyze`.
2. Run the relevant widget or integration tests.
3. Check the visual flow on a target device size.
4. Update this documentation if the app’s observable behaviour, privacy posture, or setup path changed.
