# ثاهين — Mini Offline LMS

An Arabic-first, **fully offline** learning app for health-sciences students. Courses, videos and
progress all live on the device: there is no backend, no API call and no network permission in the
happy path.

Built as a Flutter screening task. Everything below is honest about what is built, what is
deliberately not, and why.

---

## Running it

```bash
flutter pub get

# Code generation (two generators, both required after a fresh clone)
dart run build_runner build
dart run easy_localization:generate -S assets/translations -O lib/generated -o codegen_loader.g.dart
dart run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart

flutter run
```

Quality gates — both must be clean before any commit:

```bash
flutter analyze   # zero issues, zero warnings
flutter test      # 85 tests
```

Built and verified against **Flutter 3.47.0 / Dart 3.13.0** (stable).

> `--delete-conflicting-outputs` was removed in `build_runner` 2.16 and is now ignored — it is no
> longer needed.

---

## What is implemented

| Requirement | Status |
| --- | --- |
| Courses list: thumbnail, title, instructor, lesson count, progress % | ✅ |
| "Continue watching" card | ✅ Points at the most recently touched unfinished lesson |
| Course details: sections, lessons, durations, statuses | ✅ |
| Sequential unlock + friendly locked message | ✅ Names the exact lesson that unlocks it |
| Player: play/pause, seek bar, current time, duration | ✅ |
| Playback speed 1× / 1.25× / 1.5× / 2× | ✅ |
| Fullscreen / landscape | ✅ |
| Resume from last position | ✅ |
| Auto-complete at 90% watched | ✅ |
| "Next lesson" respecting the unlock rule | ✅ Shown disabled with a reason, never hidden |
| Local persistence surviving restart | ✅ Hive |
| Arabic-first RTL | ✅ |
| Loading / empty / error states, no red screens | ✅ |
| Unit tests for progress logic | ✅ 33 model tests (3 were required) |

**Bonus items done:** Arabic/English switch · dark mode · course search · remembered playback
speed · widget tests (12).

**Bonus item skipped:** per-lesson notes. It needs a third Hive box, a text-entry surface and its
own empty state — real work for a feature nothing else depends on. The time went into the unlock
and completion rules instead, which everything else is built on.

---

## Architecture

**Feature-first, two layers.** `data/` and `presentation/`. That is the whole structure.

```
lib/
├── main.dart          # Bootstrap: localisation + Hive + orientation, then runApp
├── app.dart           # Root MaterialApp.router
├── generated/         # easy_localization output — never hand-edited
├── core/              # error · localization · responsive · router · settings · storage · theme · utils · widgets
└── features/lms/
    ├── data/
    │   ├── datasources/   # CourseAssetDataSource, ProgressLocalDataSource
    │   └── models/        # …and the business rules
    └── presentation/      # pages · providers · widgets
```

### Why there is no `domain/` layer

An earlier draft had `domain/` with entities, repository interfaces and usecase classes. It was
removed on purpose.

With one bundled data source and no backend, an entity layer is a rename of the model layer — the
same five fields, copied through a `toEntity()` that can never do anything interesting. A
`CheckLessonUnlocked` usecase class is a method with a constructor around it. And
`CourseRepositoryImpl.loadCourses()` was a one-line pass-through to a data source that already
takes an injectable `AssetBundle` for testing, so it had no job left either.

What replaced it: **the models own their rules.** Both course-level rules are questions only a
whole course can answer — "is lesson N unlocked?" needs lesson N-1, "how far along am I?" needs
every lesson — so they live on `CourseModel`, next to the data they interrogate.

The models are plain Dart with **zero Flutter imports**, so every rule is unit-testable with no
widget, provider or binding in sight. That was the actual goal of a domain layer; this reaches it
without the ceremony.

| Rule | Where |
| --- | --- |
| 90% completion | `LessonProgressModel.afterPlayback` / `.meetsCompletionThreshold` |
| Sequential unlock | `CourseModel.isLessonUnlockedAt` |
| Course progress % | `CourseModel.progressPercent` |

### State management: Riverpod 3 with code generation

`@riverpod` throughout, no `setState` for shared state, no other state library.

- **Catalogue providers** are `keepAlive` — a bundled asset cannot change while the app runs, so
  re-parsing it on every navigation would be waste.
- **`ProgressController` builds synchronously** from an already-open Hive box. Consumers get a plain
  `Map`, not an `AsyncValue`, so a lesson list never flashes a spinner just to learn which lessons
  are done.
- **`.select()` everywhere it pays.** `CourseProgressBar` watches
  `progressControllerProvider.select(course.progressPercent)`, so finishing a lesson in one course
  repaints a 6-pixel bar and leaves every other card alone. `LessonTile` selects its own status, so
  completing a lesson repaints two rows — the one that finished and the one it just unlocked.
- **Local UI state stays local.** Search text, controls visibility and the fullscreen flag are
  `ValueNotifier`s. Typing in the search box must not rebuild anything above the list, and toggling
  the player overlay must not touch the video surface.

### Persistence: Hive, and only Hive

Chosen over `shared_preferences` (no good fit for a keyed collection of structured records),
`sqflite` (a relational engine for what is a key-value map) and Isar (heavier, and its own build
step). Hive reads synchronously from an open box, which is what makes the spinner-free lesson list
above possible.

Specifically **`hive_ce` / `hive_ce_flutter`** — the maintained community fork. The original `hive`
2.2.3 is discontinued on pub.dev. Same API; still "Hive only".

**Stored as JSON strings in a `Box<String>`, not via generated `TypeAdapter`s.** Adapters buy a
little speed and cost a `typeId` registry plus a bespoke migration path for every field change. At
this size a self-describing JSON blob is easier to read, version and test — and `fromJson` tolerates
unknown or missing keys, so a payload written by an older build still loads instead of throwing on
startup.

**Storage failure is not fatal.** `HiveBoxes.init()` never throws; a device where Hive cannot open
still launches and runs with session-only progress. Every read and write is null-safe against a
closed box.

### Two progress numbers, on purpose

`LessonProgressModel` tracks the playhead twice, because there are two different questions:

- **`positionSec`** follows the playhead exactly, backwards seeks included → *where do we resume?*
- **`watchedSec`** is a high-water mark that never decreases → *how much has been reached?*

Completion is evaluated against `watchedSec`. Rewinding to rewatch a tricky explanation therefore
cannot un-complete a lesson the student already finished.

`afterPlayback` is the **single place progress advances**, folding one tick through every rule at
once: resume point follows the playhead, watched mark only rises, a real player duration overrides a
stale catalogue one, completion latches on at 90% and never latches off. No call site can apply the
rules inconsistently because no call site applies them at all.

### Navigation

`go_router`, nested so locations mirror the hierarchy:
`/` → `/courses/:courseId` → `/courses/:courseId/lessons/:lessonId`.

Each page declares its own `routeName` / `routePath`; the router only assembles them, so a page and
the location that reaches it move together.

Deep-link safety lives in the **pages**, not in a router `redirect`. A link into a locked lesson
opens the player route and is met with the same explanation the lesson list gives, instead of a
silent bounce the student cannot read.

---

## Arabic, RTL and localisation

`easy_localization`, with `ar.json` / `en.json` in `assets/translations/` and **generated**
`LocaleKeys` + `CodegenLoader` in `lib/generated/`.

- **Arabic-first in the strong sense.** `ar` is both `startLocale` *and* `fallbackLocale`, so a
  device set to any unsupported language lands on Arabic, never English.
- **No hand-placed `Directionality`.** `WidgetsApp` derives text direction from the active locale.
  Forcing RTL at the root would have broken the Arabic/English switch. Two widget tests assert the
  flip actually happens in both directions.
- **`EdgeInsetsDirectional` throughout**, never `.left` / `.right`.
- **The seek bar respects `Directionality`** and fills from the right in Arabic. The transport
  controls are a plain `Row`, so rewind mirrors to the right alongside it.
- **Timecodes are never concatenated.** `00:42` and `04:00` are separate `Text` widgets in a `Row`;
  a single `'00:42 / 04:00'` string would flip apart in RTL.
- **Digits stay Western (`0-9`)**, which is what Gulf learning apps overwhelmingly use for
  timecodes, and keeps a timestamp legible next to a seek bar in either language.
- **`saveLocale: false`.** `easy_localization` persists the locale through `shared_preferences`,
  which this project deliberately avoids. It is switched off and the chosen language is stored in
  Hive with everything else — one storage engine, one migration path.
- **Drift guard.** A test asserts every generated key still resolves in every bundle, catching a
  JSON edit made without re-running the generator.

Typography is **Cairo**, bundled at four weights (400/500/600/700) so the app never touches the
network for a font, with a 1.55 line-height because Cairo's Arabic glyphs crowd at the default.

---

## Testing

**85 tests.** The task asked for 3.

| Area | Count | What it covers |
| --- | --- | --- |
| `test/models/` | 33 | The three rules and their edges |
| `test/data/` | 23 | Catalogue parsing, Hive persistence, asset truthfulness |
| `test/providers/` | 10 | Live state vs. debounced writes |
| `test/localization/` | 11 | Generated keys vs. bundles, ar/en parity, locale policy |
| `test/widget/` | 12 | Four UI states, RTL/LTR flip, unlock UX |

Edge cases worth calling out, because each one is a real bug that would otherwise ship:

- **Completion cannot happen on an unknown duration.** Guessing off a zero duration would mark
  lesson one complete the instant a corrupt video failed to report its length — cascading the
  unlock rule through the entire course.
- **The player's duration beats a wrong catalogue one.** Catalogue says 100 s, real file is 200 s →
  95 s watched is 47%, not complete.
- **Rewinding never un-completes** (the high-water mark).
- **Progress rounds down**, so 100% cannot appear while a lesson is outstanding.
- **One corrupt Hive row is skipped, not fatal** — it must not cost the student every other lesson.
- **Persistence is tested across a real close-and-reopen**, not against a fake.
- **The catalogue cannot lie about durations** — the declared seconds are checked against each
  MP4's actual `mvhd` atom.

The player page itself is **not** widget-tested: `video_player` needs a platform channel that a
widget test has no real implementation for, and asserting against a mocked channel would test the
mock. Its logic lives in the model methods, which are covered thoroughly.

---

## Data

`assets/data/courses.json` — 2 courses × 2 sections × 2–3 lessons (10 lessons).

One change from the suggested shape: a top-level **`"schemaVersion": 1`**. It costs one line and
gives any future format change somewhere to branch on. Everything else matches the brief.

Six bundled clips, **67–101 seconds each, 2.6–3.8 MB** (~19 MB total), assigned round-robin so every
clip is used and no lesson shares a duration with its neighbour by accident.

`durationSec` is **truthful, and a test enforces it**: `test/data/` parses each file's `mvhd` atom
and fails if the catalogue's declared duration drifts more than a second from the real file. Two
sibling tests pin the other properties that matter — every lesson is at least 50 s (long enough to
actually exercise the 90% rule and a resume), and every file is under the 10 MB budget the task sets.
The app prefers the player's reported duration at runtime regardless, and falls back to the declared
number only before a video has initialised.

Videos come from the **NASA Image and Video Library** — public domain, no attribution required, and
thematically close to health sciences (human health in microgravity, respiration, cardiac hardware,
cell biology). Thumbnails were generated in the design-system palette.

---

## Trade-offs and known issues

**Scrubbing forward counts as watched.** `watchedSec` is a high-water mark, so dragging the seek bar
to 95% marks a lesson complete without watching it. Fixing it properly means tracking *cumulative
watched intervals* — a list of ranges merged per tick — which is a genuinely different data
structure and a migration. The high-water mark buys the rewind-safety that matters far more day to
day, and I took that trade knowingly.

**Progress is counted in whole lessons.** A lesson 89% watched contributes nothing to course
progress. This matches the student-facing promise ("4 of 5 lessons done") and keeps the bar and the
percentage label incapable of disagreeing, but a part-watched lesson can feel invisible.

**Saves are debounced to 5 seconds — but state is not.** These are separate concerns, and an early
build conflated them in effect: the player only called `record` on a five-second timer that was
itself skipped once playback stopped, so a lesson watched to the end showed no progress until you
left the player and came back. The player now records once per second, every one of those updates is
visible immediately, and only the *write* is coalesced. Completion is written through at once,
because it unlocks the next lesson and must survive a force-kill. Pause, leaving and backgrounding
all flush. Worst case is losing 5 seconds of position.

**No `redirect` guard on the router.** A locked lesson is refused by the page, not the route. That
is a deliberate UX call — an explanation beats a silent bounce — but it does mean the route itself
is reachable.

**`easy_localization` pulls in `shared_preferences` transitively.** Unavoidable at the package
level, but nothing in this app ever reaches it: `saveLocale: false` keeps its store closed, and
`EasyLocalization.ensureInitialized()` — the only other caller — is deliberately not invoked.

That skip has a **load-bearing invariant**. `ensureInitialized()` populates two statics: the saved
locale, and `_deviceLocale`, a `late` field that `easy_localization` reads only when no `startLocale`
is supplied. Passing a non-null `startLocale` keeps that branch unreachable; a null one would throw
a `LateInitializationError` on launch. `SettingsStore.readLocale()` returns a non-nullable `Locale`
that falls back to Arabic, and `test/localization/app_locales_test.dart` pins that down so the
invariant cannot quietly rot.

**Not tested on physical hardware.** Verified via `flutter analyze`, the full test suite, and
`flutter build bundle` / `flutter build apk --release` (builds clean; the bundled videos and
multi-ABI native libraries dominate its size). Fullscreen orientation handling in particular
deserves a real-device pass, and no automated check can prove the app *launches*.

**APK:** `build/app/outputs/flutter-apk/app-release.apk`, signed with the default debug key. A
release-signed build needs a keystore that is not in this repo.

---

## What I would do with more time

1. **Cumulative watched-interval tracking**, replacing the high-water mark — closes the
   scrub-to-complete gap.
2. **Per-lesson notes**, the one bonus item skipped.
3. **A real-device pass on fullscreen**, including rotation while playing and returning from the
   background mid-lesson.
4. **Integration test** driving the full journey: watch to 90% → lesson completes → next unlocks →
   restart the app → progress is still there.
5. **Golden tests** for the Arabic layout, so an RTL regression fails CI instead of being spotted by
   eye.
6. **A lesson-level progress ring on the course card**, so a part-watched lesson is visible rather
   than rounded away.

---

## Time spent

Roughly **6 hours**, including a mid-build architecture change: an initial Clean Architecture layout
with `domain/` was flattened to two layers once it was clear the entity and usecase layers were
pure ceremony for this scope. Rewriting the docs to match is part of that number.
