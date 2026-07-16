# Pose — Real-Time AI Photo Coaching App: Design Spec

**Date:** 2026-07-16
**Status:** Approved by user
**Platform:** Native iOS (Swift / SwiftUI), iOS 17+, Apple-first

## Decisions (locked)

| Question | Decision |
|---|---|
| Build setup | User has iPhone now; Mac arrives in days. Code authored on Windows. Interim: PoseKit tested locally via Swift-for-Windows toolchain; app compile-checked on GitHub Actions macOS runner. Mac arrival → full local Xcode + on-device loop. |
| Scaffolding | XcodeGen (`project.yml`). On Mac: `brew install xcodegen && xcodegen && open Pose.xcodeproj`. |
| Paywall stack | Superwall SDK (SPM). Hard, unskippable paywall after onboarding. |
| Pose content | Keypoints-as-source-of-truth: poses authored as JSON keypoint files (19 joints). Mannequin graphic rendered from the same keypoints via SwiftUI Canvas. No external art assets. |
| Backend | None for v1. On-device only (UserDefaults). Superwall handles remote paywall config; StoreKit handles receipts. |
| Architecture | MVVM, strict OOP. Views dumb; ViewModels own state; Services own side effects, injected via protocols. |

## 1. Architecture & Project Layout

```
Pose/
├── project.yml                    # XcodeGen manifest (iOS 17+, Superwall SPM dep)
├── PoseKit/                       # Local Swift Package — pure math, zero UI deps
│   ├── Package.swift
│   ├── Sources/PoseKit/
│   │   ├── PoseVector.swift       # 19-joint pose model, Codable
│   │   ├── ProcrustesAnalyzer.swift  # GPA via Accelerate (center → scale → SVD rotation)
│   │   ├── LimbSimilarity.swift   # per-limb cosine similarity → coaching hints
│   │   └── PoseScorer.swift       # combines both → 0–1 score + per-limb feedback
│   └── Tests/PoseKitTests/        # runs via `swift test` on Mac, no simulator needed
├── App/
│   ├── PoseApp.swift              # @main, AppState injection
│   ├── Theme/Theme.swift          # single source: colors, fonts, spacing, radii, shadows
│   ├── Models/                    # Pose, PoseCategory, UserGoals
│   ├── Resources/Poses/*.json     # reference keypoints, bundled
│   ├── Services/
│   │   ├── CameraService.swift    # AVCaptureSession owner
│   │   ├── PoseDetectionService.swift  # Vision pipeline
│   │   ├── PoseLibraryService.swift    # loads JSON, search, tags
│   │   └── FavoritesStore.swift   # UserDefaults-backed
│   ├── ViewModels/                # one per screen, ObservableObject
│   └── Views/
│       ├── Home/  Library/  Camera/  Onboarding/  Components/
└── docs/superpowers/specs/
```

- `AppState` (ObservableObject, injected as `@EnvironmentObject`): onboarding progress + subscription status.
- PoseKit knows nothing about Vision/SwiftUI — takes `[SIMD2<Float>]`/`[CGPoint]`, returns scores. Discrete, reusable, unit-testable standalone.
- `MannequinView` (SwiftUI Canvas) draws a capsule-limb figure from keypoint JSON. Used by pose cards, ghost overlay, onboarding animation — one renderer, one data source.

## 2. Theme & Core Views

**Theme.swift** — single centralized file; no hardcoded styles anywhere else:
- `Theme.Colors`: cream `#F5EFE6` background, dark brown `#3E2F25` primary, muted taupe subtitles.
- `Theme.Typography`: New York serif (Apple built-in, `.fontDesign(.serif)`) for headers; SF Pro for body/subtitles.
- `Theme.Spacing`, `Theme.Radius` (pill = capsule), `Theme.Shadow`.
- Base components: `PillButton`, `ModeCard`, `WideCard`, `TagChip`, `PoseCard`, `SearchField`.

**HomeView:** serif header "shoot your shot" → large dark-brown pill "open camera" → "shooting modes" 2-square grid ('pose me (posing guidance)' / 'guide me (live coaching)') → wide 'pose library (browse poses)' card.

**PoseLibraryView:** serif header "choose a pose" → "describe your shot" search field → horizontal scroll of pill tags (mirror, close-up, selfie + categories from JSON) → 2-column LazyVGrid of PoseCards (mannequin graphic + title). Search filters name+tags locally.

**Shooting modes** — same camera screen, two modes:
- *pose me*: user picks target pose first; ghost overlay + live similarity score; auto-capture when score ≥ 85% held for 1s.
- *guide me*: no target pose; live coaching hints from standalone posture heuristics computed directly on the 19 keypoints (shoulder-line tilt, head tilt, body symmetry, arms-glued-to-torso detection) plus framing suggestions (subject centering, headroom). Implemented as `PostureHeuristics` in PoseKit — separate from target-based `PoseScorer`.

## 3. Camera & Vision Pipeline

- `CameraService`: `AVCaptureSession` on dedicated serial queue, `.hd1280x720` preset (sufficient for pose, saves thermal), front + rear cameras, `alwaysDiscardsLateVideoFrames = true`. Preview: `AVCaptureVideoPreviewLayer` in `UIViewControllerRepresentable`. Still capture: separate `AVCapturePhotoOutput` at full resolution.
- `PoseDetectionService`: `AVCaptureVideoDataOutputSampleBufferDelegate` on background queue. Backpressure: atomic `isProcessing` flag — frame dropped if Vision busy, never queued. `VNSequenceRequestHandler` + `VNDetectHumanBodyPoseRequest`. 19 joints extracted, confidence < 0.3 dropped, mapped via `VNImagePointForNormalizedPoint` + preview-layer conversion to screen space.
- Scoring runs on the detection queue (Accelerate, microseconds); only score + points published to main thread. Skeleton/overlay drawn in SwiftUI `Canvas` — no per-frame view diffing.
- Thermal: session stops on background/paywall; `ProcessInfo.thermalState` observed → inference drops to every 2nd frame at `.serious`.
- Target: ≥ 30 FPS sustained.

## 4. PoseKit Math

- `ProcrustesAnalyzer`: input two `[SIMD2<Float>]` (19 each). Centroid-subtract → divide by centroid size (√Σ‖p−c‖²) → optimal rotation via **closed-form 2D solution** (for 2D point sets the optimal rotation angle is `atan2(Σ(x×z), Σ(x·z))` — algebraically equivalent to the 2×2 SVD/Kabsch result, no LAPACK needed) → Procrustes distance d² = Σ‖x − z‖². Score = `1 − d²/2` clamped 0…1 (d² bounded [0,2] for unit-normalized shapes). Missing joints: comparison over intersection of confident joints; minimum 8 required, else `nil` score.
- **No Accelerate dependency.** Pure Swift + `simd`-style value math → PoseKit compiles and tests on the Swift-for-Windows toolchain (Accelerate is Apple-platform-only; closed-form beats LAPACK for 19-point 2D anyway). Deviation from original prompt's "use Accelerate" noted and accepted: requirement behind it was 60 FPS, which closed-form exceeds by orders of magnitude.
- `LimbSimilarity`: 10 bone vectors (upper arm ×2, forearm ×2, thigh ×2, shin ×2, torso, neck). Cosine similarity per bone; worst-offender bone drives coaching hint text.
- `PoseScorer`: final = 0.7 × Procrustes + 0.3 × mean cosine. Pure functions, preallocated buffers, no allocation in hot path. 60 FPS capable.
- Unit tests: identity = 1.0; translated = 1.0; scaled = 1.0; rotated = 1.0; mirrored/opposite low; known-distance fixtures.

## 5. Onboarding & Paywall

Single `NavigationStack`; `OnboardingViewModel` as `@EnvironmentObject`; step enum drives navigation. Steps:
1. Value-prop intro (mannequin animation loop, serif headline)
2. Goal questionnaire ("what do you struggle with in photos?")
3. Analyzing animation (circular progress, rotating status text, ~3.5s)
4. Social proof (curated review cards)
5. Feature reveal
6. Custom plan presentation (dashboard built from questionnaire answers)
7. Hard paywall

Paywall: Superwall SDK, `Superwall.shared.register(placement: "onboarding_complete")`. Annual + 3-day free trial primary; monthly as price anchor. Unskippable. Must include Restore Purchases button + ToS/Privacy links (App Review requirement). `AppState.hasCompletedOnboarding` persisted in UserDefaults; subscription status from Superwall entitlements.

Config placeholders (user supplies): Superwall API key; App Store Connect products `pose_annual_trial`, `pose_monthly`. `#if DEBUG` skip button for testing without purchase.

## 6. Testing & Verification

- PoseKit: full unit test suite via `swift test` — runs on Windows (local, immediate) and macOS CI.
- ViewModels: unit tests with mock services (protocol injection) — run on macOS (import SwiftUI/Combine).
- CI: GitHub Actions macOS runner — `xcodegen` + `xcodebuild build` on every push; catches compile errors against real iOS SDK before Mac arrives. PoseKit `swift test` job runs too.
- Camera/Vision: manual on-device checklist once Mac arrives — 30 FPS (Xcode gauges), thermal behavior, front/rear switching.
- Workflow phase 1 (pre-Mac): author everything, PoseKit green on Windows, app compile green in CI. Phase 2 (Mac): `xcodegen`, build, on-device tuning.

## Out of Scope (v1)

- Android / cross-platform
- Backend (Firebase), accounts, cloud sync
- Face-scan "best angles" feature
- Photo editing/post-processing
- Scene-aware pose recommendation (Pose Genius-style environment scanning)
