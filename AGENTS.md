# Repository Guidelines

## Project Structure & Module Organization

This workspace currently has no source files, package manifest, tests, or Git metadata. Its path suggests a Flutter project; the layout below is recommended once a Flutter scaffold is added.

- `lib/`: Dart application code; group related screens, widgets, and models by feature.
- `test/`: automated tests, mirroring the relevant `lib/` structure.
- `assets/`: images, track illustrations, and other static resources; register them in `pubspec.yaml`.
- Platform directories such as `android/`, `ios/`, and `web/`: platform configuration when those targets are enabled.

## Build, Test, and Development Commands

After a Flutter scaffold and `pubspec.yaml` exist, run commands from the repository root:

- `flutter pub get`: install declared dependencies.
- `flutter run`: launch the app on an available device or emulator.
- `flutter analyze`: check Dart code for static analysis issues.
- `dart format lib test`: format source code and tests.
- `flutter test`: run automated tests.
- `flutter build apk`: build an Android release package when Android support is configured.

## Coding Style & Naming Conventions

Use Dart formatting with two-space indentation. Name files and directories in `snake_case`, types in `UpperCamelCase`, and variables and methods in `lowerCamelCase`. Keep widgets focused and extract reusable UI components. Follow the rules in `analysis_options.yaml` when that file is introduced.

## Testing Guidelines

For the proposed Flutter setup, use `flutter_test` for unit and widget tests. Name files `*_test.dart`. Cover changed behavior and important edge cases; no coverage threshold is currently defined.

## Commit & Pull Request Guidelines

No Git history exists to establish commit conventions. Use concise, imperative subjects, such as `Add track detail screen`. Keep changes focused. Pull requests should describe behavior changes, list validation performed, link relevant issues, and include screenshots for visible UI changes.

## Security & Configuration

Keep credentials and signing keys out of version control. Document required configuration without including secret values. Exclude generated build output and local tooling caches when adding repository ignore rules.