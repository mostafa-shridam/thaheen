# ذهين — Mini Offline LMS

An Arabic-first learning app for health-sciences students. It runs **100% offline**: the courses,
the videos and the student's progress all live on the device. No backend, no API calls.

<!-- Screen recording / APK: see the "Deliverables" note at the end. -->

---

## 1. How to run

```bash
flutter pub get

# Code generation — needed once after a fresh clone
dart run build_runner build
dart run easy_localization:generate -S assets/translations -O lib/generated -o codegen_loader.g.dart
dart run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart

flutter run
```

Checks:

```bash
flutter analyze   # 0 issues
flutter test      # 85 tests, all passing
```

Built on **Flutter 3.47.0 / Dart 3.13.0** (stable).

---

## 2. Architecture and state management

### Structure — two layers, on purpose

```
lib/
├── main.dart, app.dart     # startup + root MaterialApp
├── generated/              # easy_localization output
├── core/                   # theme, router, storage, localization, shared widgets
└── features/lms/
    ├── data/               # datasources + models (models hold the business rules)
    └── presentation/       # pages + providers + widgets
```

**There is no `domain/` folder, and that was a deliberate choice.** I started with full Clean
Architecture — entities, repository interfaces, usecase classes — and removed it partway through.

Here's why. This app has one data source: a JSON file inside the app. There is no server and no
second source of data. In that situation:

- An *entity* would just be a copy of the model with the same fields.
- A `CheckLessonUnlocked` *usecase class* would just be a method with a class wrapped around it.
- A *repository* would just pass the call straight through to the data source.

So instead, **the models hold the rules**. The three rules the task asks for live in exactly one
place each:

| Rule | Where it lives |
| --- | --- |
| Lesson completes at 90% watched | `LessonProgressModel.afterPlayback` |
| Lesson N is locked until N-1 is done | `CourseModel.isLessonUnlockedAt` |
| Course progress % | `CourseModel.progressPercent` |

The important part: **the models are plain Dart with no Flutter imports**, so all three rules can be
unit-tested without a widget, a provider or a test binding. That is the real benefit people want
from a domain layer, and this gets it without the extra files.

### State management — Riverpod (with code generation)

Used consistently: `@riverpod` everywhere, no `setState` for shared state, no second state library.

Three decisions worth explaining:

1. **Course data is loaded once and kept.** The catalogue is a file inside the app — it cannot
   change while the app runs — so re-reading it on every screen would be wasted work.

2. **Progress is read synchronously from Hive.** Hive can read from an open box instantly, so the
   progress provider returns a plain `Map` instead of an `AsyncValue`. This means the lesson list
   never shows a loading spinner just to find out which lessons are finished.

3. **`.select()` is used so screens don't over-rebuild.** Each lesson row watches only *its own*
   status. When you finish a lesson, exactly two rows repaint — the one you finished and the one it
   just unlocked — instead of the whole course.

Small UI state (search text, whether the player controls are visible, fullscreen on/off) uses
`ValueNotifier` instead of providers, so typing in the search box doesn't rebuild the page.

### Storage — Hive

Chosen because:

- **vs. SharedPreferences** — this is a keyed collection of structured records, not a handful of
  loose settings.
- **vs. sqflite** — a relational database is overkill for what is essentially a map.
- **vs. Isar** — heavier, and brings its own build step.

Hive also reads synchronously, which is what makes the no-spinner lesson list above possible.

Two details:

- I use **`hive_ce`**, the maintained community fork, because the original `hive` package is marked
  discontinued on pub.dev. Same API.
- Progress is saved as **JSON text in a `Box<String>`**, not with generated `TypeAdapter`s. Adapters
  would mean managing type IDs and writing a migration for every field change. A JSON blob is easier
  to read and version, and old saved data still loads if a field is added later.
- **If Hive fails to open, the app still starts.** It just runs without saving progress, rather than
  crashing on launch.

### Why progress is tracked with *two* numbers

`LessonProgressModel` stores the playhead twice, because there are two different questions:

- `positionSec` — follows the playhead exactly, including when you rewind → **where do we resume?**
- `watchedSec` — only ever goes up, never down → **how much of the lesson has been reached?**

Completion is measured against `watchedSec`. This means rewinding to rewatch a difficult part
**cannot un-complete** a lesson you already finished.

All of this happens in one method, `afterPlayback`, so no screen can apply the rules differently.

### Navigation — go_router

Routes are nested to match the screens:
`/` → `/courses/:courseId` → `/courses/:courseId/lessons/:lessonId`

Each page declares its own route path, so a page and its URL stay together.

If someone deep-links into a locked lesson, the **page** shows the friendly "finish X first" message
rather than the router silently redirecting — an explanation is more useful than a bounce.

### Arabic and RTL

- Arabic is both the **startup language and the fallback**, so a phone set to any other language
  still opens in Arabic.
- **No hard-coded `Directionality`.** Flutter derives text direction from the active language —
  forcing RTL would have broken the Arabic/English switch. Two widget tests check the layout
  actually flips both ways.
- `EdgeInsetsDirectional` everywhere, never `left`/`right`.
- The **seek bar fills from the right** in Arabic, and the rewind/forward buttons mirror with it.
- Timecodes are separate widgets, never one `"00:42 / 04:00"` string — that string would flip apart
  in RTL.
- All text goes through `easy_localization` using **generated keys**, so a renamed key is a build
  error instead of a raw `courses.title` appearing on screen.
- Font is **Cairo**, bundled in the app (4 weights) so it never needs the network.

---

## 3. Trade-offs, known issues, and what I'd do with more time

### Known trade-offs

**Dragging the seek bar forward counts as "watched".** Because `watchedSec` only goes up, pulling
the slider to 95% marks the lesson complete. Doing this properly means tracking which *ranges* of
the video were actually watched — a different data structure and a migration. I chose the simpler
version because the rewind-safety it buys matters more in daily use.

**Course progress counts whole lessons only.** A lesson watched to 89% adds nothing to the course
percentage. This matches what the number promises the student ("4 of 5 lessons done") and stops the
bar and the label from ever disagreeing, but a half-watched lesson looks invisible.

**Progress is written to storage every 5 seconds, not instantly.** Writing on every frame would
hammer the disk. The *screen* still updates immediately — only the save is delayed. Pausing, leaving
the lesson or backgrounding the app saves right away, and completion is always saved immediately
because it unlocks the next lesson. Worst case you lose 5 seconds of position.

**10 lessons share 6 videos.** Each lesson is paired with a video that genuinely matches its topic,
but there aren't 10 distinct clips.

### Known issues

- **I could not test on a real phone.** `flutter analyze`, all 85 tests and `flutter build apk
  --release` pass, but no automated check proves the app actually launches. Fullscreen rotation
  especially deserves a real-device pass.
- **The player screen has no widget test.** `video_player` needs a real platform channel; testing it
  against a fake would only test the fake. Its logic lives in the model methods, which are tested
  thoroughly.
- **The APK is signed with the debug key**, since a release keystore isn't in the repo.
- **`easy_localization` pulls in `shared_preferences`** as a dependency of its own. Nothing in this
  app uses it — `saveLocale: false` keeps it switched off and the language is stored in Hive like
  everything else — but it is in the dependency tree.

### With more time

1. Track watched *ranges* instead of a high-water mark, closing the scrub-to-complete gap.
2. Per-lesson notes — the one bonus feature I skipped.
3. A real-device pass, especially fullscreen and rotation.
4. An integration test for the full journey: watch to 90% → lesson completes → next unlocks →
   restart the app → progress is still there.
5. Golden tests for the Arabic layout, so an RTL regression fails CI instead of being noticed by eye.

---

## 4. Time spent

**About 3 hours.**

Measured from file timestamps, roughly 2 hours of that was actively writing code; the rest was
running builds, the test suite, and sourcing and cutting the video assets.

---

## What's included

**Features:** all required ones. Courses list with progress, continue-watching card, sections and
lessons with status, sequential unlock with a friendly message, player with play/pause, seek,
speed (1× / 1.25× / 1.5× / 2×), fullscreen, resume, auto-complete at 90%, and a next-lesson button
that respects the unlock rule.

**Bonus done:** Arabic/English switch · dark mode · course search · remembers playback speed ·
widget tests.

**Bonus skipped:** per-lesson notes. It needs a third Hive box, a text input and its own empty
state — real work for a feature nothing else depends on. That time went into the unlock and
completion rules instead, which everything else is built on.

### Tests — 85 total (the task asked for 3)

| Area | Count | Covers |
| --- | --- | --- |
| `test/models/` | 33 | The three rules and their edge cases |
| `test/data/` | 23 | JSON parsing, Hive saving/loading |
| `test/providers/` | 10 | Live progress updates vs. delayed saving |
| `test/localization/` | 11 | Translation keys, Arabic/English parity |
| `test/widget/` | 12 | Loading/empty/error states, RTL flip, unlock UX |

A few edge cases worth mentioning, because each is a bug that would otherwise ship:

- A lesson **can't be marked complete if the video's duration is unknown** — otherwise one corrupt
  file would complete lesson 1 instantly and unlock the whole course.
- If the catalogue says 100s but the real file is 200s, **the real file wins**.
- **Rewinding never un-completes** a lesson.
- Progress **rounds down**, so 100% can't show while a lesson is still unfinished.
- **One corrupt saved row is skipped, not fatal** — it must not wipe out every other lesson.
- Saving is tested **across a real close-and-reopen** of the database.
- A test **reads each video file's real duration** and fails if the catalogue disagrees.

### Data and videos

`assets/data/courses.json` — 2 courses × 2 sections × 2–3 lessons (10 lessons). The only change
from the suggested shape is a top-level `"schemaVersion": 1`, so a future format change has
somewhere to branch.

Six video clips, 90–100 seconds each, 2.4–3.6 MB. **Each clip actually teaches its lesson's topic** —
they're cut from real anatomy and physiology teaching films, and the lesson titles were written to
match what each clip genuinely shows:

| Clip | What it shows |
| --- | --- |
| `skeletal_system` | skeletons compared; ribs and skull protecting organs |
| `bone_structure` | periosteum, where blood vessels enter bone, bony layers |
| `muscle_fibers` | muscle sheath, striations under the microscope, tendons |
| `muscle_contraction` | nerve and electrical stimulation moving a muscle lever |
| `cardiac_cycle` | animated heart chambers, valves and blood flow |
| `respiration` | rib-cage overlay, labelled diaphragm, breathing muscles |

Sources: *Heart and Circulation* (1937, public domain) and the Wellcome Collection's *Body
framework* and *Muscles* (CC BY-NC 3.0). I picked the segments by extracting frames from each film
and looking at them, not by guessing timestamps — which is also how I caught that one candidate film
(*Posture*) contains footage of unclothed children and rejected it.

---

## Deliverables

- **Repository:** this repo, public on GitHub.
- **Screen recording:** a 2–3 minute walkthrough is linked in the submission email.
- **APK:** not committed — `/build/` is git-ignored. Build it in one step:

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk  (~73 MB, debug-key signed)
```
