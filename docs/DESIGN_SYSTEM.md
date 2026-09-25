# DESIGN_SYSTEM.md — UI, Colors & Typography Rules

Guidelines for UI components, Arabic RTL layout, responsive scaling, and color palette for Thaheen LMS.

## 🎨 Color Palette (Health-Sciences & Medical Theme)

Design is clean, neutral, and professional for medical/health-sciences students.

| Category | Color Code (Hex) | Usage |
| --- | --- | --- |
| Primary Brand | `#006699` / Teal-Blue | Main buttons, active indicators, app bar titles |
| Secondary Accent | `#00A88F` / Emerald Green | Success states, completed lesson checks (✅) |
| Background Light | `#F8FAFC` / Soft Gray | App background surface |
| Card Surface | `#FFFFFF` / Pure White | Course cards, lesson list tiles, sheets |
| Text Primary | `#0F172A` / Dark Slate | Primary titles and course headings |
| Text Secondary | `#64748B` / Muted Gray | Instructors, lesson duration, metadata |
| Locked State | `#CBD5E1` / Disabled Gray | Locked lesson icon (🔒) and disabled tiles |
| Error / Warning | `#E11D48` / Soft Red | Error state messages and video retry buttons |

## 🔤 Typography & Arabic Support

- **Primary Font**: Cairo (Bundled in `assets/fonts/`).
- **Direction**: Mandatory RTL (Right-to-Left) layout.
- **Text Styles**:
  - Heading 1 (Course Titles): Cairo, Bold, 20sp, Color: Text Primary
  - Heading 2 (Section Titles): Cairo, SemiBold, 16sp, Color: Text Primary
  - Body / Lesson Title: Cairo, Medium, 14sp, Color: Text Primary
  - Caption / Meta: Cairo, Regular, 12sp, Color: Text Secondary

## 📱 Responsive Layout & RTL Rules

### Responsive Approach — `responsive_framework` (Required Package)

Responsiveness is handled by one package, not by ad-hoc `MediaQuery` math.

```yaml
# pubspec.yaml
dependencies:
  responsive_framework: ^1.5.1
```

Install it once at the root of the app, above `Directionality`/theme concerns:

```dart
MaterialApp(
  builder: (context, child) => ResponsiveBreakpoints.builder(
    child: child!,
    breakpoints: const [
      Breakpoint(start: 0, end: 450, name: MOBILE),
      Breakpoint(start: 451, end: 800, name: TABLET),
      Breakpoint(start: 801, end: 1920, name: DESKTOP),
    ],
  ),
  // ...
);
```

**Breakpoints**

| Name | Range (dp) | Target |
| --- | --- | --- |
| `MOBILE` | 0 – 450 | Phones (primary target) |
| `TABLET` | 451 – 800 | Small tablets, large foldables |
| `DESKTOP` | 801 – 1920 | Tablet landscape / desktop shells |

**Rules**

- Design baseline: 390dp width (standard mobile viewport). Everything else scales from it.
- Read the active breakpoint with `ResponsiveBreakpoints.of(context).isMobile` / `.largerThan(MOBILE)`; pick per-breakpoint values with `ResponsiveValue<T>`.
- Use `LayoutBuilder` / `Flexible` / `Expanded` only for local constraints inside an already-responsive subtree — never as a replacement for the package.
- No hardcoded pixel dimensions for layout, and no `MediaQuery.of(context).size` arithmetic inside feature widgets.
- The video player surface keeps its own aspect-ratio handling; breakpoints control the surrounding chrome (controls, side padding, next-lesson rail), not the video frame itself.
- The package wrapper must sit outside `Directionality` overrides so RTL and scaling never conflict.

### RTL Considerations (Arabic First)

- Seekbar / Slider in Video Player must fill from Right to Left or respect `Directionality.rtl`.
- Back arrows must point Right (`Icons.arrow_back_ios` / `Icons.arrow_forward`).
- Padding/Margin: Use `EdgeInsetsDirectional.only(start: ..., end: ...)` instead of `.left` / `.right`.

## 🧱 Component Rules

Shared primitives live in `lib/core/widgets/`. **Never hand-roll one of these shapes inline** — if a
screen needs a surface, a bar, a chip, a row or a sheet, it uses the widget below. A second
implementation is how a design system drifts, so each of these exists exactly once.

| Widget | Replaces | Notes |
| --- | --- | --- |
| `AppContainer` | every `Container(decoration: BoxDecoration(...))` | Three shapes only: `rounded` (cards, `BorderRadius.circular(12)`), `pill`, `circle`. Clips its own ink when given `onTap`, so a ripple can never spill past a corner. Colours default to the theme. |
| `AppProgressBar` | every `ClipRRect` + `LinearProgressIndicator` | Pill ends, clamped value. `color`/`trackColor` only for non-standard surfaces. |
| `AppChip` | inline pill badges | Optional icon + short label. Not Material's `Chip`. |
| `AppTile` | inline list `Row`s | Optional leading / subtitle / trailing. `surface: false` inside a sheet that already provides one. |
| `AppSheet` + `AppSheetSection` | every `showModalBottomSheet` call | Owns the drag handle, safe area, directional padding and title. `AppSheet.show<T>()` keeps the presentation options identical everywhere. |
| `AppSnackBar` | every `ScaffoldMessenger` / `showSnackBar` call | A **top** overlay, not a Material `SnackBar`. `AppSnackBar.show(context, message:, kind:)` — `info` / `success` / `error` pick the colour and icon; `icon:` overrides the glyph. One message at a time: showing dismisses whatever is up. |
| `AppSkeletonBox` | shimmer placeholders | Hand-rolled pulse; no shimmer package. |
| `AppErrorView` / `AppEmptyView` | error and empty states | Empty is styled calm, not as a failure. |

Feature-level shared widgets (e.g. `InstructorLine`, `CourseProgressBar`) follow the same rule
inside `features/lms/presentation/widgets/`.

### Transient messages

Messages arrive from the **top**, never the bottom. The player anchors its transport controls along
the bottom of the video, and in fullscreen a bottom message lands squarely on top of them; coming
down from the status bar keeps a message clear of the controls it is usually describing.

`AppSnackBar` is an overlay entry on the root overlay, so it needs no `Scaffold` in scope, survives a
route push underneath it, and sits above a fullscreen video. It slides down with a fade, holds for
three seconds by default, and can be flicked up to dismiss early. Only one is ever on screen.

Deliberate exceptions, because they are genuinely not the same shape:

- `CourseCard` uses Material `Card` — its shape, border and elevation already come from `cardTheme`,
  and the thumbnail must clip to the top corners.
- The player controls scrim uses a raw `BoxDecoration`, because it is a `LinearGradient` and
  `AppContainer` deals in flat fills.

- **Buttons**: Styled centrally through `filledButtonTheme` / `outlinedButtonTheme` in
  `AppTheme`, so screens use plain `FilledButton` / `OutlinedButton` rather than a wrapper.
- **States**:
  - Loading: `AppSkeletonBox` composed into a skeleton that mirrors the real layout.
  - Empty: `AppEmptyView` — icon plus a short description (e.g. "لا توجد دروس في هذا القسم بعد").
  - Error: `AppErrorView` — user-friendly card with a retry option.
  - Transient message: `AppSnackBar` — see **Transient messages** below.
