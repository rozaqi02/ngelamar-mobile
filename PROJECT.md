# Project: Ngelamar Flutter Application — 2026 Release Readiness

## 1. Architecture Overview

Ngelamar is an offline-first job application tracker and contextual career preparation assistant for Indonesian jobseekers.
The architecture is structured around:
- **Presentation**: Flutter UI with custom Design Tokens (`AppColorTokens`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppMotion`), Responsive Safe Area Insets (`AppScaffoldInsets`), Riverpod state consumers, and modular atomic widgets.
- **State Management**: Reactive state management via Flutter Riverpod (`jobProvider`, `settingsProvider`, etc.).
- **Domain & Services**: Business logic isolated in standalone services (`TextParserService`, `SalaryEvaluatorService`, `FollowupService`, `AndroidHomeWidgetService`, `BackupService`, `NotificationService`, `SupabaseService`).
- **Data Persistence**: Encrypted Hive local database (`job_applications`, `profile_box`, `settings_box`) with cold restart & web refresh resilience.
- **Platform Integrations**: Android AppWidgetProvider (multi-size 2x2, 4x2, 4x3 layouts), `ACTION_SEND` share target intent receiver, local notifications, and Android 13+ themed icons.

## 2. Mandatory Design & Product Guardrails
1. **GR-01: Icon-Only Phone Dock Navbar**: Never add permanent text labels to the mobile navbar. Accessibility is provided via `Semantics(label: ...)`.
2. **GR-02: Card Color Identity**: Preserve vibrant, strong card background colors in Light Mode; use softer refined tones in Dark Mode. Foreground text is dynamically computed (`onCardStrong` / `onCardSoft`) to ensure WCAG 4.5:1 contrast.
3. **GR-03: Home Viewport Simplicity**: Home remains a focused daily summary. Never add permanent AI chatbots, heavy charts, community feeds, or secondary clutter. Headline remains "Periksa Lamaranmu" (max 2 lines).
4. **GR-04: Hero Transition Scope**: Hero transition is strictly reserved for the company logo mark using immutable `job.id` tags. Never include company names or titles in Hero flights.
5. **GR-05: No Unwanted Fade**: Morph '+' button and critical page transitions use pure geometric slide and shape morphing without opacity cross-fade.
6. **GR-06: Code-Native Vector Mascot**: Mascot and celebration illustrations remain 100% vector/code-native (`CustomPainter`). No raster AI-generated logos.

## 3. Feature Inventory

| # | Work Package | Feature Description | Milestone | Source |
|---|---|---|---|---|
| 1 | WP-01 | Test Tooling Isolation, Integration Test Harness, Golden Baseline | M1 (Baseline Quality Gate) | Survey / Spec §4.1 |
| 2 | WP-02 | AppBackPolicy, PopScope Contract & Deterministic Tab/Filter Restoration | M2 (Core Stability) | Survey / Spec §4.2 |
| 3 | WP-03 | Centralized ProfileRepository & Cold/Refresh Persistent Avatar | M2 (Core Stability) | Survey / Spec §4.2 |
| 4 | WP-04 | Android Home Widget Error-Trapping & Multi-Size (2x2, 4x2, 4x3) Layouts | M2 (Core Stability) | Survey / Spec §4.2 |
| 5 | WP-09 | Centralized AppScaffoldInsets & Safe Area Metrics | M2 (Core Stability) | Survey / Spec §4.2 |
| 6 | WP-14 | Fast Startup Path (<900ms), Offline State & Zero Double Splash | M2 (Core Stability) | Survey / Spec §4.2 |
| 7 | WP-05 | Design Token System Consolidation (Color, Spacing, Radius, Elevation) | M3 (Tokens & A11y) | Survey / Spec §4.3 |
| 8 | WP-06 | 4.5:1 Card Text Contrast, 48dp Touch Targets & Semantics Labels | M3 (Tokens & A11y) | Survey / Spec §4.3 |
| 9 | WP-07 | Local Manrope Font Asset Bundling & GoogleFonts Network Removal | M3 (Tokens & A11y) | Survey / Spec §4.3 |
| 10 | WP-08 | Anti-Overflow Protections (320dp Width & 200% Font Scaling) | M3 (Tokens & A11y) | Survey / Spec §4.3 |
| 11 | WP-10 | Adaptive Tablet & Large Screen Viewport Layouts | M3 (Tokens & A11y) | Survey / Spec §4.3 |
| 12 | WP-11 | AppMotion Token System & Reduced-Motion Mode | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 13 | WP-12 | Morph '+' Button to CTA Single Geometry Tween (No Font Weight Jump) | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 14 | WP-13 | Logo-Only Hero Flight with Immutable JobId Tag | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 15 | WP-15 | 60fps Performance Budget & 500-Item Scalable Data Handling | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 16 | WP-16 | Screen Monolith Decomposition & Dependency Governance | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 17 | WP-17 | Add/Edit Form Refactor (Nullable Defaults, Progressive Disclosure) | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 18 | WP-18 | Home & JobList Screen Unification & Collapsible Tracker Header | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 19 | WP-19 | JobDetail Screen Structured Information Hierarchy | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 20 | WP-20 | Functional 4-Event Calendar (Lamaran, Seleksi, Tindak Lanjut, Tenggat) | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 21 | WP-21 | Standardized AppStateView, AppInlineError & Section Fallbacks | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 22 | WP-22 | App Icon, Portal Logo Governance & Android Adaptive Icons | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 23 | WP-23 | Code-Native Vector Mascot State Matrix (MascotStateSpec) | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 24 | WP-24 | Indonesian Microcopy Guide, Canonical Status Taxonomy & Salary Data | M4 (Motion & Screens) | Survey / Spec §4.4 |
| 25 | WP-25 | Contextual Career Prep Integration (JobDetail/Calendar to Prep) | M5 (Product Leverage) | Survey / Spec §4.5 |
| 26 | WP-26 | Android ACTION_SEND Share Target Intent Integration | M5 (Product Leverage) | Survey / Spec §4.5 |
| 27 | WP-27 | Smart Post-Status Next Action Automation Rules | M5 (Product Leverage) | Survey / Spec §4.5 |
| 28 | WP-28 | Push Notification & Home Widget Quick Actions | M5 (Product Leverage) | Survey / Spec §4.5 |
| 29 | WP-29 | Non-Intrusive Bulk Management Mode on JobList | M5 (Product Leverage) | Survey / Spec §4.5 |
| 30 | WP-30 | Profile & Settings IA Cleanup (Support: idkasolutions@gmail.com) | M5 (Product Leverage) | Survey / Spec §4.5 |
| 31 | WP-31 | Official Job Portal Search Launcher & Highlight Tour | M5 (Product Leverage) | Survey / Spec §4.5 |
| 32 | WP-32 | Production Release Pipeline (AAB/APKs) & 16-Point Release Gate | M6 (Release Gate) | Survey / Spec §4.6 |

## 4. Milestones Registry

| # | Name | Scope | Dependencies | Status |
|---|---|---|---|---|
| **M1** | Baseline Quality Gate & Test Harness | WP-01 (Tooling isolation to `tool/`, `integration_test/app_flow_test.dart`, golden test baselines) | none | **DONE** |
| **M2** | Core Stability & System Foundations | WP-02, WP-03, WP-04, WP-09, WP-14 (AppBackPolicy, ProfileRepository, Multi-size widgets, AppScaffoldInsets, Fast Splash) | M1 | **IN_PROGRESS** |
| **M3** | Visual Tokens, Typography & Accessibility | WP-05, WP-06, WP-07, WP-08, WP-10 (Design Tokens, WCAG contrast, local Manrope TTF bundling, anti-overflow, tablet layouts) | M2 | PLANNED |
| **M4** | Signature Motion & Screen Consolidation | WP-11, WP-12, WP-13, WP-15, WP-16, WP-17, WP-18, WP-19, WP-20, WP-21, WP-22, WP-23, WP-24 (AppMotion, Hero Logo, + Morph, Monolith decomposition, Add/Edit, Home/List, JobDetail, 4-Event Calendar, Mascot Matrix, Salary Data) | M3 | PLANNED |
| **M5** | Product Leverage & System Integrations | WP-25, WP-26, WP-27, WP-28, WP-29, WP-30, WP-31 (Career Prep, ACTION_SEND, Smart Next Actions, Bulk Operations, Settings IA, Portal Tour) | M4 | PLANNED |
| **M6** | Release Gate & Distribution Pipeline | WP-32 (Production AAB/APK build, 16-point release gate verification, zero regression checklist) | M5, E2E Track | PLANNED |
| **E2E** | E2E Testing Track | Independent 4-Tier Test Suite (Tiers 1-4) covering all 32 WPs, publish `TEST_READY.md` | none (Parallel) | IN_PROGRESS |

## 5. Interface Contracts

### Navigation & Back Policy (`AppBackPolicy`)
- Root shell tabs (`MainNavigationScreen`) intercept system back events via `PopScope(canPop: false, onPopInvokedWithResult: ...)`
- Root tab selection does not show back buttons; back button inside root tab deterministically switches to Tab 0 (Home).
- Child routes pop gracefully without resetting state or losing list scroll position.

### Design Tokens (`AppColorTokens` & `AppMotion`)
- `AppColorTokens`: light/dark card background colors, computed foreground contrast (`onCardStrong`, `onCardSoft`), border radius (`AppRadius`), and spacing constants (`AppSpacing`).
- `AppMotion`: standard duration tokens (`micro`, `stateChange`, `pageRoute`, `heroFlight`) and curves (`Curves.easeOutCubic`, `Curves.easeInOutCubic`).

### Profile & Persistence (`ProfileRepository`)
- Centralized `ProfileRepository` managing avatar image bytes, local file caching, compressed thumbnails, and Hive storage.
- `SafeAvatarImage`: widget rendering avatar with graceful fallback to company/user initials on decode errors.

### Android Home Widget Contract (`AndroidHomeWidgetService`)
- Native widget layouts: `ngelamar_reminder_widget_2x2.xml`, `ngelamar_reminder_widget_4x2.xml`, `ngelamar_reminder_widget_4x3.xml`.
- Method channel passes JSON payload with active counts, urgent reminders, and deep link targets.

### Calendar Event Adapter (`CalendarEventAdapter`)
- Aggregates jobs into 4 canonical event types: `Lamaran`, `Seleksi`, `Tindak Lanjut`, `Tenggat`.
- Returns event dots list (max 3 per date cell) with high-contrast indicator.

## 6. Code Layout & Write Boundaries
- `lib/theme/`: `app_theme.dart`, `app_color_tokens.dart`, `app_spacing.dart`, `app_radius.dart`, `app_motion.dart`
- `lib/models/`: `job_application.dart`, `mascot_state_spec.dart`, `calendar_event.dart`, `user_profile.dart`
- `lib/repositories/`: `profile_repository.dart`, `job_repository.dart`
- `lib/services/`: `text_parser_service.dart`, `salary_evaluator_service.dart`, `followup_service.dart`, `android_home_widget_service.dart`, `backup_service.dart`
- `lib/views/`:
  - `main_navigation.dart`
  - `dashboard/`: `dashboard_screen.dart`, `widgets/`
  - `jobs/`: `job_list_screen.dart`, `job_detail_screen.dart`, `add_edit_job_screen.dart`, `widgets/`
  - `calendar/`: `calendar_screen.dart`, `widgets/`
  - `prep/`: `fresh_grad_prep_screen.dart`, `widgets/`
  - `settings/`: `settings_screen.dart`, `widgets/`
- `android/`: `app/src/main/res/layout/`, `app/src/main/kotlin/com/ngelamar/app/ngelamar/`
- `assets/fonts/`: Bundled Manrope TTF files
- `test/`: Unit & widget tests (`test/widget_test.dart`, `test/golden/`, `test/e2e/`)
- `integration_test/`: `app_flow_test.dart`
- `tool/`: Asset & screenshot generator scripts (`tool/generators/`)
