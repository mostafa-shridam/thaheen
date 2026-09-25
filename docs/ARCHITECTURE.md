# ARCHITECTURE.md — Thaheen Mini Offline LMS

This document outlines the architecture, layer rules, and structural decisions for the Thaheen Mini Offline LMS Flutter application.

## 🏗️ Architectural Pattern: Feature-First, Two Layers

The app is **feature-first with two layers — `data/` and `presentation/`** — and Riverpod for state
management.

There is deliberately **no `domain/` layer**: no entities mirroring the models, no repository
interfaces with a single implementation, and no usecase classes. The task is a bundled-asset app
with no backend and no second data source, so an entity layer would be a rename of the model layer
and a usecase class would be a method with extra ceremony around it. The models own their own
rules; `presentation/` reads them through Riverpod providers.

```
lib/
├── main.dart               # Bootstrap: EasyLocalization + Hive + orientation, then runApp
├── app.dart                # Root MaterialApp.router: localisation, theme, responsive builder
│
├── generated/              # easy_localization output (LocaleKeys, CodegenLoader) — never hand-edited
│
├── core/
│   ├── error/              # FailureCode + AppFailure
│   ├── localization/       # Locale policy (AppLocales) + FailureCode -> copy mapping
│   ├── responsive/         # Breakpoints consumed by ResponsiveBreakpoints.builder
│   ├── router/             # GoRouter configuration & route constants
│   ├── settings/           # Hive-backed preferences (locale, theme, playback speed)
│   ├── storage/            # Hive lifecycle & box names — the only storage engine
│   ├── theme/              # Colors, typography, ThemeData (Arabic/RTL focused)
│   ├── utils/              # Extensions, formatters (duration, dates), JSON readers
│   └── widgets/            # Shared UI (AppErrorView, AppEmptyView, AppSkeletonBox, AppSnackBar)
│
└── features/
    └── lms/                # Single cohesive feature module for LMS
        ├── data/
        │   ├── datasources/   # CourseAssetDataSource (courses.json), Hive progress source
        │   └── models/        # CourseModel, SectionModel, LessonModel,
        │                      # LessonProgressModel, LessonStatus — and the business rules
        └── presentation/
            ├── providers/     # Riverpod @riverpod Notifiers / AsyncNotifiers
            ├── pages/         # CoursesPage, CourseDetailsPage, LessonPlayerPage —
            │                  # one screen each, no sub-widgets
            └── widgets/       # every piece those screens are built from
```

## 📐 Layer Rules & Guidelines

### Data Layer (`features/lms/data/`)

**Data sources** own I/O and nothing else.

- `CourseAssetDataSource` reads `assets/data/courses.json` through `rootBundle` and returns
  models. Its `AssetBundle` is injectable so tests feed fixtures instead of touching the real bundle.
- The Hive progress source reads and writes `LessonProgressModel` JSON blobs keyed by lesson id.
- There is no network layer, by design.

**Models** own their JSON shape *and* the business rules that operate on them. Parsing is
hand-written rather than generated, so each field can decide for itself whether a bad value fails
the record or falls back — which is what makes the "no red screens" requirement achievable. A
missing *identity* field (id, title, video) throws; a missing *descriptive* field falls back.

The three rules the task names live on the models, each in exactly one place:

| Rule | Where it lives |
| --- | --- |
| **90% Completion** — a lesson completes once `watchedSec / duration >= 0.9` | `LessonProgressModel.meetsCompletionThreshold` / `.afterPlayback` |
| **Sequential Unlock** — lesson N is open only when lesson N-1 is completed | `CourseModel.isLessonUnlockedAt` |
| **Progress %** — share of the course completed, counted in whole lessons | `CourseModel.progressRatio` / `.progressPercent` |

Models are plain Dart with no Flutter imports, so all three are unit-testable without a widget,
a provider or a binding — see `test/models/`.

**Two progress numbers, on purpose.** `positionSec` follows the playhead exactly and answers
*where do we resume?*; `watchedSec` is a high-water mark that never decreases and answers *how much
has been reached?*. Completion is evaluated against `watchedSec`, so rewinding to rewatch something
cannot un-complete a finished lesson. `afterPlayback` is the single place progress advances, which
is what keeps the rules impossible to apply inconsistently.

### Presentation Layer (`features/lms/presentation/`)

- Widgets consume state via Riverpod (`ConsumerWidget` / `Consumer`).
- Use `.select()` on providers to prevent unnecessary UI rebuilds (especially above the video
  player surface).
- No direct data parsing or storage manipulation inside UI widgets — that is what the data sources
  are for.
- Sizing comes from `responsive_framework` (installed once in `core/responsive/`), per
  `docs/DESIGN_SYSTEM.md`. Widgets read breakpoints; they do not compute screen math.
- Loading, empty and error are handled explicitly at every `AsyncValue`, never left to an
  unguarded `.value`.
- **A page file holds its screen and nothing else.** A page resolves providers, owns navigation,
  and picks which widget renders each state — every one of those widgets lives in its own file
  under `widgets/`, public and named. This keeps each screen under ~100 lines and makes its parts
  findable and reusable. The one class a page may still declare is its own `State`.
- **No function widgets.** A `Widget _buildX()` helper returns a subtree that has no element of
  its own, so it cannot be `const`, rebuilds with its whole parent, and is invisible in the widget
  inspector. Write a widget class instead.
- A widget file may keep a *private* leaf widget (for example `_FooterNote` inside
  `lesson_footer.dart`) when it is a detail of that one component and has no meaning outside it.

### Core (`core/`)

Cross-cutting concerns only: error types, localisation policy, theming, routing, Hive lifecycle,
shared state widgets. Nothing in `core/` knows about courses or lessons.

## 🌍 Localization Layer (`core/localization/`)

Translation is handled by **`easy_localization`**, with the JSON bundles living in
`assets/translations/` (`ar.json`, `en.json`).

- **Arabic-first**: `ar` is both `startLocale` and `fallbackLocale`. A device set to an
  unsupported language lands on Arabic, never English. `AppLocales` owns this policy.
- **Generated keys and loader**: `LocaleKeys` and `CodegenLoader` in `lib/generated/` are produced
  by `easy_localization:generate` from the JSON bundles. Presentation code writes
  `LocaleKeys.courses_title.tr()`, never a raw dot-path, so a renamed key is a compile error rather
  than a literal key rendered on screen. `CodegenLoader` compiles the translations into the binary,
  so a cold start never depends on reading an asset file.
- **Regenerate after every bundle edit** — see the codegen commands in `CLAUDE.md`. The files in
  `lib/generated/` are build output and are never hand-edited.
- **Errors become words in exactly one place**: `failure_translations.dart` maps a `FailureCode` to
  its message and hint keys. The data layer stays copy-free.
- **`saveLocale: false`**: `easy_localization` persists the chosen locale via `shared_preferences`,
  which this project forbids. The feature is therefore switched off and the selected language is
  stored in Hive alongside all other app state, then fed back in as `startLocale` at boot. One
  storage engine, one migration path.
- **Drift guard**: `test/localization/translation_keys_test.dart` asserts that every generated key
  still resolves in every bundled locale — catching a JSON edit made without regenerating — and
  that `en.json` covers every `ar.json` leaf.

## 🔄 State Management Strategy (Riverpod)

- **Code Generation**: `@riverpod` annotations with `build_runner`.
- **Rebuild Optimization**: UI parts that change frequently (e.g. video player seek position) are
  isolated inside local `ValueNotifier` or scoped `Consumer` widgets with `.select()`.
- **Persistence Sync**: Progress updates in storage trigger provider state refreshes smoothly
  without blocking UI playback.
- **Composition root**: providers are where data sources are constructed and wired. Tests override
  a provider rather than reaching for `rootBundle` or a real Hive box.
