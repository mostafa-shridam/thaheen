# CLAUDE.md — Thaheen Mini Offline LMS Guidelines

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📚 Required Reading — the `docs/` Directory (Always Applies)

Before answering **any** prompt or writing **any** code in this repository, read every Markdown file under `docs/` and treat their contents as binding rules, at the same level of authority as this file.

| File | Scope it governs |
| --- | --- |
| `docs/ARCHITECTURE.md` | Layer boundaries, folder structure, state management strategy |
| `docs/TASK_PLAN.md` | Implementation roadmap, phases, scope, deliverables |
| `docs/DESIGN_SYSTEM.md` | Colors, typography, responsive rules, components, UI states |

Rules for this directory:

- **Glob, do not hardcode**: the table above is a snapshot, not the contract. Always load `docs/**/*.md`. Any file added to `docs/` later is automatically in scope with no edit to `CLAUDE.md` required.
- **All docs apply to every prompt**, even when the prompt mentions only one of them, or none. A UI prompt still obeys `ARCHITECTURE.md`; a refactor prompt still obeys `DESIGN_SYSTEM.md`.
- **Precedence on conflict**: explicit instruction in the current prompt > `CLAUDE.md` > `docs/*.md`. Never silently pick a side — state the conflict, then follow this order.
- **Keep docs true**: if a change makes a document wrong (new dependency, renamed folder, changed rule, completed task), update that document in the same task.

## Project Overview

**Thaheen Mini Offline LMS** — Arabic-first offline learning mobile app for health-sciences students.

- Tech Stack: Dart `^3.12.0`, Flutter `>=3.24.0`, Riverpod 3 CodeGen (`riverpod_annotation` + `riverpod_generator`), GoRouter, Hive, `video_player`, `responsive_framework` `^1.5.1`, `easy_localization` `^3.0.8`.
  - The Dart floor is `^3.12.0`, not `^3.5.0`: Riverpod 3 / `riverpod_generator` 4 require it. The toolchain in use is Dart 3.13.0 / Flutter 3.47.0.
- Constraints: **100% Offline**. **Hive only** for local persistence — never add `shared_preferences` or any other local storage package. No backend / No API calls. All data bundled in `assets/data/courses.json` and `assets/videos/`.
  - The Hive packages are `hive_ce` / `hive_ce_flutter` — the maintained community edition of Hive, API-compatible with the discontinued `hive` 2.2.3. It is still "Hive only".

## Essential Commands

```bash
# Run App
flutter run

# Riverpod codegen (Run manually or notify user — NEVER run concurrently)
# NOTE: --delete-conflicting-outputs was removed in build_runner 2.16 and is now ignored.
dart run build_runner build

# Localization codegen — re-run after ANY edit to assets/translations/*.json
dart run easy_localization:generate -S assets/translations -O lib/generated -o codegen_loader.g.dart
dart run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart

# Analyze & Test (Zero-warnings policy)
flutter analyze
flutter test
```

## Architecture & Code Guidelines

### 1. Structure & Riverpod Rules

- **Feature-First, two layers**: `lib/core/` for cross-cutting concerns, `lib/features/lms/` split
  into `data/` and `presentation/` only.
- **No `domain/` layer**: no entities mirroring models, no repository interfaces with one
  implementation, no usecase classes. Models own their JSON shape *and* their business rules.
  Adding any of those back is over-engineering for a bundled-asset app with no backend.
- **Riverpod Only**: Use `@riverpod` CodeGen syntax. No BLoC, GetX, or raw `setState`.
- **Rebuild Control**: Always use `.select()` when listening to provider state changes inside widgets to prevent unnecessary frame drops.
- **Local Widget State**: Use `ValueNotifier` + `ValueListenableBuilder` for local UI states (like video player control overlays).

### 2. Business Rules (Strict)

The three rules live on the models, each in exactly one place. Never re-implement one at a call site.

- **90% Completion** (`LessonProgressModel.meetsCompletionThreshold` / `.afterPlayback`): a lesson is
  marked completed when `watchedSec / duration >= 0.9`. Measured against `watchedSec` — a high-water
  mark that never decreases — not the live playhead, so rewinding never un-completes a lesson.
  `afterPlayback` is the only place progress advances.
- **Sequential Unlock** (`CourseModel.isLessonUnlockedAt`): lesson index `i` is locked unless lesson
  `i-1` is completed. Lesson 0 is always open; an unknown id is locked, never an exception.
- **Progress %** (`CourseModel.progressPercent`): counted in whole completed lessons and rounded
  down, so 100% never appears while a lesson is outstanding.
- **Persistence**: Save video position periodically (debounced) and on pause/leave. All progress and
  position state lives in Hive boxes — no `shared_preferences`.
- Models are plain Dart with no Flutter imports, so every rule is unit-testable with no widget,
  provider or binding. Tests live in `test/models/`.

### 3. RTL, Arabic & Responsive UX Rules

- App is Arabic-First (RTL). Ensure `Directionality` is RTL at root.
- Icons, Sliders/Seekbars, and `Row` order must make sense in RTL mode.
- Never hardcode display strings in presentation widgets. All copy goes through `easy_localization`
  using the **generated** `LocaleKeys` in `lib/generated/locale_keys.g.dart`, with bundles in
  `assets/translations/{ar,en}.json`. Arabic (`ar`) is both the start locale and the fallback.
- `lib/generated/` is build output — never hand-edit it; re-run the localization codegen instead.
- `easy_localization` pulls `shared_preferences` in transitively. It is configured with
  `saveLocale: false` so no app state flows through it; the chosen locale is persisted in Hive.
- **Responsive package**: sizing is handled by `responsive_framework`. Wrap `MaterialApp.builder` with `ResponsiveBreakpoints.builder` once, at root, using the breakpoints defined in `docs/DESIGN_SYSTEM.md`.
- Never scatter raw `MediaQuery.of(context).size` math through widgets, and never hardcode pixel dimensions for layout. Use `ResponsiveValue` / `ResponsiveBreakpoints.of(context)`, or `LayoutBuilder` for a genuinely local constraint.
- `responsive_framework` must not fight RTL: keep `EdgeInsetsDirectional` and `Directionality`-aware widgets inside its scaled subtree.

### 4. Error Handling & States

- **No Red Screens**: Always handle video errors or corrupted assets gracefully with `AppErrorWidget`.
- Handle empty courses or missing video assets cleanly with user-friendly Arabic messages.

### 5. Code Style & Formatting

- Never run `dart format`. Match existing file style.
- `prefer_single_quotes`, `prefer_const_constructors`, `prefer_final_locals`.
- One public widget class per file. Extract private helper widgets into separate files if reusable.
- **Never hand-roll a shape that `lib/core/widgets/` already owns.** Before writing a
  `Container(decoration: ...)`, a `ClipRRect` + `LinearProgressIndicator`, a pill badge, a list
  `Row`, a `showModalBottomSheet` or a `ScaffoldMessenger.showSnackBar`, use `AppContainer`,
  `AppProgressBar`, `AppChip`, `AppTile`, `AppSheet` or `AppSnackBar`. See the component table in `docs/DESIGN_SYSTEM.md` for the full list and the two
  documented exceptions.
