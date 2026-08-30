# Ngelamar Mobile — 4-Tier E2E Testing Infrastructure Specification

**Document Version**: 2.29.0+247  
**Date**: 2026-08-30  
**Target Application**: Ngelamar (Personal Career CRM & Job Application Tracker)  
**Author**: E2E Testing Track Orchestrator (sub_orch_e2e)  
**Workspace**: d:/Projek/app-mobile-loker  

---

## 1. Executive Summary & Architecture Overview

The Ngelamar E2E Testing Infrastructure is engineered to provide an unbreakable quality gate across all 32 Work Packages (WP-01 to WP-32) spanning 6 sequential product phases. 

To ensure deterministic reliability, zero flaky executions, and complete verification of the 6 Mandatory Design & Product Guardrails (GR-01 to GR-06), the testing architecture is structured into a four-tier pyramid:

`
+-----------------------------------------------------------------------------------------+
|                       TIER 4: REAL-WORLD APPLICATION SCENARIOS                          |
|         Complex multi-step user journeys, cold starts, lifecycles, backup/restore       |
|                  (test/e2e/tier4_real_world_scenarios_test.dart)                        |
+-----------------------------------------------------------------------------------------+
|                       TIER 3: CROSS-FEATURE INTEGRATION MATRIX                          |
|        Pairwise interactions between decoupled modules, services, and state changes     |
|                      (test/e2e/tier3_cross_feature_test.dart)                           |
+-----------------------------------------------------------------------------------------+
|                       TIER 2: BOUNDARY & CORNER CASE COVERAGE                           |
|        Extreme inputs, zero states, 320dp/200% scaling, massive strings, malformed data |
|                    (test/e2e/tier2_boundary_corner_test.dart)                           |
+-----------------------------------------------------------------------------------------+
|                       TIER 1: CORE FEATURE SPECIFICATION SUITE                          |
|             >= 5 deterministic, authentic tests per Work Package (WP-01 to WP-32)        |
|                    (test/e2e/tier1_feature_coverage_test.dart)                          |
+-----------------------------------------------------------------------------------------+
`

---

## 2. Test Harness & Mock Architecture

### 2.1 Deterministic Mock Infrastructure (	est/e2e/e2e_test_helpers.dart)
1. **In-Memory Storage (Hive & SharedPreferences)**:
   - Hive.init(tempDir.path) creates isolated temporary directories per test group to guarantee state hygiene.
   - SharedPreferences.setMockInitialValues(...) provides pre-seeded user profile, career interests, and theme preferences.
2. **Secure Key Storage (FlutterSecureStorage)**:
   - Mocked binary messenger for plugins.it_nomads.com/flutter_secure_storage returning AES-256 test encryption keys.
3. **Platform Method Channels**:
   - dexterous.com/flutter/local_notifications: Intercepts notification scheduling, cancellation, and permission checks.
   - home_widget: Intercepts widget dataset synchronization and Android RemoteViews update payloads.
   - plugins.flutter.io/url_launcher: Validates external portal URLs without launching system browser.
   - plugins.flutter.io/share_plus: Intercepts sharing intents and text export.
4. **State Management (Riverpod)**:
   - Test ProviderContainer and ProviderScope harnesses allowing direct state inspection (container.read(jobProvider)), mutation testing, and deterministic listener subscriptions.

---

## 3. Tier Breakdown & Detailed Work Package Matrix

### Tier 1: Feature Coverage Specification (>= 5 Tests per WP, WP-01 to WP-32)

| Work Package ID | Work Package Name | Verification Focus | Test Count |
|---|---|---|:---:|
| **WP-01** | Test Tooling Isolation & Integration Harness | Tool isolation in 	ool/, zero Base64 in test stdout, analyzer clean, deterministic fixtures, suite pass rate | 5 |
| **WP-02** | AppBackPolicy & Navigation Ownership | Root dock no back button, deterministic Tab 0 return, PopScope handling, filter retention, double-back debounce | 5 |
| **WP-03** | ProfileRepository & Safe Avatar | Centralized repository, cold restart persistence, image resize/compression, initials fallback, error boundary | 5 |
| **WP-04** | Android Home Widget Multi-Size Layouts | 2x2 compact, 4x2 standard, 4x3 expanded layouts, empty state fallback, error trapping, channel sync | 5 |
| **WP-05** | Design Token Consolidation | AppColorTokens resolution, AppSpacing scale (4-32dp), AppRadius tokens, 3 AppElevation tokens, theme propagation | 5 |
| **WP-06** | WCAG Contrast & Semantics Audit | 4.5:1 text contrast on strong card backgrounds, 3.0:1 on large text, 48dp minimum touch bounds, TalkBack semantic labels, live regions | 5 |
| **WP-07** | Bundled Manrope Typography System | Asset font bundling, zero runtime network requests, weight preservation, TextTheme mapping, invariant flight weights | 5 |
| **WP-08** | Anti-Overflow & Responsive Scaling | 320dp narrow layout, 200% font scale, dynamic text wrapping, chip Wrap containers, no RenderFlex overflow | 5 |
| **WP-09** | Safe Area & AppScaffoldInsets | Root inset consumption once, zero double top padding, gesture bar bottom padding, keyboard viewInsets handling, notch safety | 5 |
| **WP-10** | Adaptive Tablet & Large Screen Layouts | Compact <600dp, medium 600-839dp, expanded >=840dp dual-pane list-detail, calendar-agenda split, constrained form width | 5 |
| **WP-11** | AppMotion Token System & Reduced Motion | Micro/stateChange/pageRoute/heroFlight durations, easing curves, reduced-motion toggle, spatial directions, non-blocking UI | 5 |
| **WP-12** | Plus-to-CTA Morph Transition | Circle to pill tween, single FlightShuttleBuilder, no font weight jump, bidirectional flight, tap lock during flight | 5 |
| **WP-13** | Company Logo Hero Flight | Immutable jobId tag, logo mark only, source placeholder preservation, return flight stability, gradient backdrop termination | 5 |
| **WP-14** | Fast Startup Path & Offline Splash | Sub-900ms startup, offline state first frame, matching native/flutter background, async remote config, zero double splash | 5 |
| **WP-15** | 60fps Performance Budget & 500-Item Scale | 500 item list virtualization, bounded memory, selective context.select rebuilds, compute isolate offloading, RepaintBoundary isolation | 5 |
| **WP-16** | Build Size & Modular Screen Decomposition | AAB/split APK targets, incremental dependency safety, modular screen widgets, route contract preservation, analyzer metrics | 5 |
| **WP-17** | Progressive Disclosure Add/Edit Form | Nullable workMode/fields, FormSectionLabel Wajib/Opsional badges, Quick vs Full add separation, local draft saving, inline validation | 5 |
| **WP-18** | Unified JobCard & Collapsible Header | Light/Dark card color identity, 2-line headline Periksa Lamaranmu, scroll collapse/restore header, cream edge gradients, no solid blocking overlays | 5 |
| **WP-19** | Structured JobDetail Hierarchy | Summary -> Status/Next Action -> Update -> HR Contact -> Timeline -> Full Details, 45-60 char action subtitles, backdrop gradient, sticky CTA dock | 5 |
| **WP-20** | Functional 4-Event Calendar | Lamaran, Seleksi, Tindak Lanjut, Tenggat categories, dot color mapping, solid circle selected day, 7-day summary carousel, timezone normalization | 5 |
| **WP-21** | Standardized AppStateView & Errors | AppStateView loading/empty/error/offline contracts, AppInlineError, retry debounce, local cache first, single CTA | 5 |
| **WP-22** | Asset Governance & Adaptive Icons | Normalized portal logos, optical padding, Android adaptive icons foreground/background/monochrome, initial avatar hash, zero AI raster marks | 5 |
| **WP-23** | Vector Mascot State Matrix | MascotStateSpec per status, custom vector painters, celebration bottom-to-center trajectory, rejected state, no ground moon shadow | 5 |
| **WP-24** | Indonesian Microcopy & Salary Dataset | Canonical 7-status taxonomy, concise Indonesian copy, regional UMP/UMK dataset with year/source/timestamp metadata, legal disclaimers | 5 |
| **WP-25** | Contextual Career Prep Integration | CareerContext auto-fill role/company/status/dates from JobDetail/Calendar, relevant interview topics, HR email templates, practice notes, no Home clutter | 5 |
| **WP-26** | Android ACTION_SEND Share Target | Share sheet receiver, TextParserService regex URL/text extraction, quick import mode, confidence score, duplicate checking, confirmation gate | 5 |
| **WP-27** | Smart Post-Status Next Action Engine | Status transition rule triggers, duplicate reminder prevention, inline post-celebration prompt, one-tap accept, calendar/agenda sync | 5 |
| **WP-28** | Push & Widget Quick Actions | Idempotent ReminderCommand, Tandai Selesai, Tunda Besok +1 day, instant widget sync, deleted job fallback | 5 |
| **WP-29** | Non-Intrusive Bulk Management | Long-press multi-select mode, bulk archive/delete, Urungkan snackbar undo, single batch mutation, dock preservation | 5 |
| **WP-30** | Modular Profile & Settings IA | Profile identity overview, career journey stats, Pro banner, dedicated Riwayat route with PopScope, idkasolutions@gmail.com support email | 5 |
| **WP-31** | Official Job Portal Search Launcher & Tour | Portal query builder JobStreet/LinkedIn/Glints/Kalibrr, 3-7 step AppTourOverlay, ensureVisible scroll target, skip tour fallback | 5 |
| **WP-32** | Production Release Pipeline & 16-Point Gate | Automated clean build verification, synchronized versioning 2.29.0+247, store screenshot parity, 16-point gate checklist | 5 |

**Tier 1 Total Test Target**: 160 Tests (32 Work Packages × 5 Tests).

---

### Tier 2: Boundary & Corner Case Coverage (>= 5 Tests per WP)

Tier 2 probes system limits, anomalous inputs, and fault tolerance:
1. **Nullability & Missing Fields**: Missing HR contacts, empty notes, null interview timestamps, unselected work modes.
2. **Extreme Data Volumes & Memory Constraints**: 500+ job applications, 20MB profile images, massive descriptions (>10,000 chars), multi-token query floods.
3. **Viewport & Typography Extremes**: 320dp narrow screens, 200% font scaling (	extScaler = 2.0), tablet landscape ratios.
4. **Network & Offline Partitioning**: Supabase unverified sessions, cloud sync offline cutoffs, Remote Config timeouts, corrupt ZIP backup bytes.
5. **Temporal & Timezone Edge Cases**: Month rollover across timezones (UTC vs Asia/Jakarta WIB), leap years, overdue follow-up calculations.
6. **Concurrency & Race Conditions**: Rapid hardware back taps, simultaneous multi-item updates, double-tap morph locks.

**Tier 2 Total Test Target**: 160 Tests (32 Work Packages × 5 Tests).

---

### Tier 3: Cross-Feature Combinations (Pairwise WP Coverage)

Tier 3 validates the interaction dynamics between decoupled features:
- **Matrix 1**: Form Add/Edit (WP-17) + Android Share Target (WP-26) + Smart Text Parser (WP-24).
- **Matrix 2**: Status Progression (WP-23/24) + Mascot Celebration (WP-23) + Smart Next Action (WP-27) + Calendar Aggregator (WP-20).
- **Matrix 3**: 4-Event Calendar (WP-20) + Android Home Widget (WP-04) + Push Quick Actions (WP-28) + Notification Service.
- **Matrix 4**: Job Detail Hierarchy (WP-19) + Company Logo Hero (WP-13) + Contextual Career Prep (WP-25) + AppBackPolicy (WP-02).
- **Matrix 5**: Non-Intrusive Bulk Operations (WP-29) + Collapsible Tracker Header (WP-18) + AppInlineError / Toast (WP-21) + Performance Budget (WP-15).
- **Matrix 6**: Profile Photo Storage (WP-03) + Modular Settings IA (WP-30) + Dark Mode Theme Tokens (WP-05) + AppScaffoldInsets (WP-09).
- **Matrix 7**: Job Portal Search Launcher (WP-31) + AppTourOverlay (WP-31) + Salary Evaluator (WP-24) + Microcopy Taxonomy (WP-24).
- **Matrix 8**: AES-256 Encrypted Backup (WP-16) + SafeAvatarImage (WP-03) + Attachment Path Sanitization + Cloud Sync State.

---

### Tier 4: Real-World Application Scenarios (Complex User Flows)

1. **Scenario 1: Fresh Graduate Jobseeker Onboarding to First Application**
   - First launch -> Dismissable welcome tour -> Browse JobStreet via Portal Launcher -> Share job link to Ngelamar -> Quick Add auto-parsing -> Progressive disclosure full add -> Verified presence on Home and List.
2. **Scenario 2: Multi-Stage Recruitment Pipeline to Job Offer Acceptance**
   - Create application in Tersimpan -> Advance to Dikirim -> Advance to Interview HR -> Trigger Mascot Celebration -> Accept suggested Next Action -> Launch Contextual Career Prep interview guide -> Advance to Offering -> Finalize Diterima.
3. **Scenario 3: Complete Offline CRM Cycle & Encrypted Backup/Restore**
   - 10+ applications created offline -> Add document attachments -> Trigger AES-256 Encrypted ZIP Backup -> Wipe local database -> Verify empty state fallback -> Restore from encrypted backup -> Validate attachment file paths and timestamps.
4. **Scenario 4: High-Volume CRM Search, Multi-Filter, and Bulk Operations**
   - Seed 100+ applications across 8 cities and 5 work modes -> Execute multi-token search (Jakarta Hybrid Flutter) -> Select 15 items via multi-select mode -> Bulk Archive -> Verify instant Urungkan (Undo) SnackBar -> Restore archived items to original positions.
5. **Scenario 5: External Widget Synchronization & Notification Quick Actions**
   - Schedule interview deadline -> Synchronize with Android Home Widget (2x2/4x2/4x3 RemoteViews) -> Simulate push notification action Tunda Besok (+1 day) -> Verify widget refresh -> Simulate Tandai Selesai -> Verify completed state in Calendar agenda.

---

## 4. Test Execution & Quality Gate Commands

`ash
# 1. Run Complete Unit & E2E Test Suite (Tiers 1 - 4)
flutter test test/e2e/test_suite_runner.dart

# 2. Run Individual Tiers
flutter test test/e2e/tier1_feature_coverage_test.dart
flutter test test/e2e/tier2_boundary_corner_test.dart
flutter test test/e2e/tier3_cross_feature_test.dart
flutter test test/e2e/tier4_real_world_scenarios_test.dart

# 3. Run Static Analysis Quality Gate (Zero Warnings / Errors)
dart analyze

# 4. Verify Release Gate Pipeline
flutter build appbundle --release
`

---

## 5. Verification Proof & Quality Gate Sign-Off

- **Deterministic Execution**: 100% pass rate with zero dependency on network availability.
- **Zero Flakiness**: No arbitrary sleep or unbounded timers; all async state transitions use deterministic pumps and completers.
- **Tooling Isolation**: All screenshot, icon, and QR generators strictly isolated in 	ool/generators/.
- **Integrity Compliance**: All assertions test authentic data models, genuine calculations, and real component lifecycles.
