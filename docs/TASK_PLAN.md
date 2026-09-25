# TASK_PLAN.md — Implementation Roadmap

**Project:** Thaheen Mini Offline LMS
**Target Scope:** 4–6 Hours Work Box
**Deadline:** September 28, 2026

## ⏱️ Timeline & Breakdown

### Phase 1: Setup & Data Layer (~1 Hour) — ✅ done

- [x] Initialize Flutter project, assets structure (`assets/data/`, `assets/videos/`, `assets/images/`).
- [x] Create `courses.json` with 2 medical courses, 2 sections each, and 2-3 lessons per section.
- [x] Include 2 short local `.mp4` video assets (<10 MB each). — 6 bundled, 90–100 s and 2.4–3.6 MB each, cut from anatomy/physiology teaching films (Prelinger PD + Wellcome CC BY-NC) so each clip teaches its lesson's actual topic. Durations, the 50 s floor and the size cap are all test-enforced.
- [x] Setup dependencies: `flutter_riverpod` + `riverpod_annotation`, `go_router`, `hive_ce` / `hive_ce_flutter` (maintained Hive fork), `video_player`, `responsive_framework` (`^1.5.1`), `easy_localization`.
- [x] Build Data Models (`CourseModel`, `SectionModel`, `LessonModel`, `LessonProgressModel`) with hand-written JSON parsing (see README for why not `json_serializable`).

### Phase 2: Business Rules & Unit Testing (~1 Hour) — ✅ done

Rules live on the models — there is no usecase layer. See `docs/ARCHITECTURE.md`.

- [x] Implement `LessonProgressModel` with its persistence shape.
- [x] Implement the Hive progress datasource (boxes only, no adapters) — `Box<String>` of JSON, no TypeAdapters.
- [x] Write the rules as pure model methods:
  - [x] **Sequential Unlock**: `CourseModel.isLessonUnlockedAt` — lesson N locked until N-1 completed.
  - [x] **90% Completion**: `LessonProgressModel.afterPlayback` — auto-marks at 90% watched.
  - [x] **Course Progress %**: `CourseModel.progressPercent` — whole lessons, rounded down.
- [x] Write Unit Tests (3 minimum required) — 33 in `test/models/`:
  - [x] Test 90% auto-complete threshold (incl. boundary, rewind, unknown duration).
  - [x] Test lesson lock/unlock condition (incl. section boundary, unknown id).
  - [x] Test course progress percentage calculation (incl. empty course, rounding).

### Phase 3: Presentation & Core Features (~2.5 Hours) — ✅ done

- [x] **Courses Screen**: List courses, show progress bar, and "Continue Watching" banner.
- [x] **Course Details Screen**: Render sections & lessons with unlock/lock statuses (🔒 / ⏳ / ✅).
- [x] **Lesson Player Screen**:
  - [x] Video playback (`video_player` / `chewie`).
  - [x] Speed selector (1x / 1.25x / 1.5x / 2x).
  - [x] Auto-save last position & restore on reopen.
  - [x] "Next Lesson" button adhering to unlock rules.
  - [x] Landscape / Fullscreen toggle support.

### Phase 4: Arabic RTL, States & Refinement (~1 Hour) — ✅ done

- [x] Ensure proper RTL layout (Arabic typography, seekbar direction, paddings) — asserted by widget tests in both directions.
- [x] Wire `responsive_framework` at root (`ResponsiveBreakpoints.builder`) and verify the MOBILE/TABLET/DESKTOP breakpoints from `docs/DESIGN_SYSTEM.md`.
- [x] Add Loading, Empty, and Custom Error States (No red screens).
- [x] Local storage choice justification in README.

### Phase 5: Deliverables & Submission (~0.5 Hour)

- [ ] Record a 2–3 minute Loom / Screen recording demonstrating RTL, video playback, position persistence, and unlock rules.
- [x] Finalize `README.md` with setup steps, architecture explanations, and trade-offs.
- [ ] Push to GitHub & reply to the submission email.


---

## Delivered beyond the plan

- **Arabic/English switch** (`easy_localization`, generated keys) — bonus item.
- **Dark mode** — bonus item.
- **Course search** — bonus item.
- **Remembered playback speed** — bonus item.
- **Widget tests** (12) — bonus item.
- **65 tests total** against a required minimum of 3.

## Not done

- **Per-lesson notes** (bonus) — skipped deliberately; see the README.
- **Screen recording** — needs a human at a device.
- **Release-signed APK** — a debug-key release APK is built at
  `build/app/outputs/flutter-apk/app-release.apk`; proper signing needs a keystore.
- **Physical-device verification**, particularly fullscreen rotation.
