# Original User Request

## 2026-08-30T10:56:26Z

Execute the 2026 Release Readiness Implementation Plan for the Flutter application "Ngelamar" across 6 sequential phases (WP-01 to WP-32), ensuring zero regression, strict design guardrails, automated test verification, and full release gate readiness.

Working directory: d:/Projek/app-mobile-loker
Integrity mode: development

## Reference Specification
- Master Specification Document: Ngelamar_Implementation_Plan_Antigravity_2026-08-30.pdf (47 pages, 32 Work Packages, Lampiran A-F)

## Requirements

### R1. Baseline Test Harness & Quality Gate (WP-01)
- Isolate test generators/tooling out of the default flutter test suite.
- Establish deterministic integration test harness (integration_test/app_flow_test.dart) covering full user journeys (quick add, full add, edit, delete, status transitions, back navigation, search, filter).
- Create automated golden test baselines for Home, JobList, JobDetail, Calendar, and Profile on light/dark themes and 360dp/412dp viewports.

### R2. Core Stability & System Foundations (WP-02 s.d. WP-04, WP-09, WP-14)
- Navigation & Back Policy (WP-02): Implement AppBackPolicy and PopScope contract across root shell and all child routes. Root dock tabs never display back buttons; back gestures deterministically restore parent tab, list scroll offset, and filter state.
- Profile Persistence (WP-03): Establish centralized ProfileRepository with image compression and safe avatar rendering (SafeAvatarImage) that survives cold restart and web refresh.
- Android Home Widget (WP-04): Robust RemoteViews error-trapping and multi-size adaptive layouts (2x2, 4x2, 4x3) without text clipping or crash states.
- Safe Area & Insets (WP-09): Centralize AppLayoutMetrics / AppScaffoldInsets so system insets are consumed once by root without double-padding on Android or web.
- Fast Startup & Splash (WP-14): Optimize startup path to 700-900ms with offline-first local state and zero double splash.

### R3. Visual Tokens, Typography & Accessibility (WP-05 s.d. WP-08)
- Design Tokens (WP-05): Consolidate raw Color(0x...) and BoxShadow literals into AppColorTokens, AppSpacing, AppRadius, and AppElevation.
- Contrast & Semantics (WP-06): Ensure minimum 4.5:1 text contrast on strong card backgrounds, 48dp minimum touch targets, and full TalkBack/VoiceOver semantic descriptions.
- Local Font Bundling (WP-07): Bundle Manrope font assets locally in pubspec.yaml and remove runtime GoogleFonts network requests.
- Anti-Overflow & Responsive Scaling (WP-08): Support 320dp narrow viewports and 200% font scaling with Wrap and LayoutBuilder without overflow bars.

### R4. Signature Motion & Screen Consolidation (WP-11 s.d. WP-13, WP-15 s.d. WP-24)
- Motion Language (WP-11, WP-12, WP-13): Enforce strict AppMotion tokens; single geometry tween for + button morph to CTA; immutable Hero tag on company logo without fade transitions.
- Core Screens Refactor (WP-17 s.d. WP-21):
  - Form add/edit with progressive disclosure and null defaults for unselected fields.
  - Unified JobCard model between Home and JobList with smooth collapsible header.
  - JobDetail structured hierarchy (status, next action, HR contact, timeline, details).
  - Functional Calendar with 4 distinct event categories (Lamaran, Seleksi, Tindak Lanjut, Tenggat) and 7-day summary.
  - Standardized AppStateView and AppInlineError states.
- Mascot & Content System (WP-22 s.d. WP-24): Vector-only MascotStateSpec per status event, unified canonical status taxonomy, updated salary datasets with timestamp metadata.

### R5. Product Leverage & Store Release Pipeline (WP-25 s.d. WP-32)
- Connect contextual career prep from JobDetail/Calendar (WP-25).
- Enable Android ACTION_SEND share target into quick add (WP-26).
- Smart post-status next action suggestions (WP-27) and quick actions from notifications/widgets (WP-28).
- Implement non-intrusive bulk management mode on JobList (WP-29).
- Clean Settings IA with support contact idkasolutions@gmail.com (WP-30).
- Focused job portal launcher & robust 3-7 step highlight tour (WP-31).
- Reproducible release pipeline producing production AAB, split APKs, and validated release gate checklist (WP-32).

## Design & Product Guardrails (Mandatory)
1. Icon-only phone dock navbar: Do not add permanent text labels to the mobile navbar.
2. Card Color Identity: Preserve vibrant, strong card background colors in light mode, and softer refined tones in dark mode.
3. Home Viewport Simplicity: Home remains a focused daily summary; do not add permanent AI chatbots, heavy graphs, or complex social feeds.
4. Hero Transition: Hero animation is strictly reserved for the company logo mark.
5. No unwanted fade: Morph plus and critical page transitions use pure geometric slide/morph without opacity cross-fade.
6. Code-native vector mascot: Mascot and celebration illustrations remain vector/code-native; no raster AI-generated logos.

## Acceptance Criteria
- [ ] flutter analyze passes with 0 errors and 0 warnings.
- [ ] Automated regression suite (flutter test) passes 100% without running screenshot generators.
- [ ] End-to-end user flows in integration_test/ pass deterministically.
- [ ] Zero blank screens, lost routes, or unexpected back navigation.
- [ ] Profile photo survives cold start and web refresh without page errors.
- [ ] Android Home Widget functions smoothly across 2x2, 4x2, 4x3 sizes.
- [ ] All 5 main screens scale gracefully down to 320dp and up to 200% font scale without RenderFlex overflow errors.
- [ ] Morph button (+ to CTA) transitions smoothly in both forward and reverse directions without font weight jumping.
- [ ] Calendar accurately displays dots, legend, and agenda from real job events.
- [ ] Release build generates a verified, clean Android App Bundle (.aab) and optimized release APK.

## Follow-up — 2026-08-30T11:55:14Z

Please resume execution from the current milestone. Continue orchestrating through the remaining Work Packages (Milestone 3 through Milestone 6) and report progress.
