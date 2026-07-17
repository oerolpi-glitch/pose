# Pose

Real-time AI photo coaching for iOS. Pick a pose, and the camera guides you into
it with a live skeleton overlay, scores how close you are, and captures the shot
the moment you nail it. Plus a "guide me" mode with live posture coaching and a
browsable pose library. All pose processing runs on-device.

Native Swift / SwiftUI, MVVM, iOS 17+. Warm editorial aesthetic — cream and dark
brown, serif headers.

## Architecture

```
PoseKit/            Pure-Swift math package (no Apple frameworks) — compiles and
                    tests anywhere, including Windows CI.
  ProcrustesAnalyzer   scale/rotation/translation-invariant pose similarity
  LimbSimilarity       per-bone cosine similarity → which limb to fix
  PoseScorer           combined 0–1 score + coaching hint
  PostureHeuristics    standalone "guide me" coaching (no target pose)
  ReferencePose        the bundled pose library's data model

App/
  Theme/            The single source of truth for all styling. No color, font,
                    spacing, radius, icon size, or animation lives anywhere else.
  Services/         CameraService (AVCaptureSession), PoseDetectionService
                    (Vision, frame-drop backpressure), CoordinateMapper
                    (Vision↔view↔PoseKit spaces), PoseLibraryService, FavoritesStore
  ViewModels/       one ObservableObject per screen
  Views/            Home, Library, Camera, Onboarding, and reusable Components
  Resources/Poses/  10 authored reference poses (JSON keypoints)
```

Views are dumb, ViewModels own state, Services own side effects behind protocols.
The camera pipeline emits Vision-normalized poses; `CoordinateMapper` is the one
place the front-camera mirror flip happens, so the skeleton, the score, and the
preview always agree.

## Develop

**The pose math (Windows, Mac, or Linux):**

```bash
swift test --package-path PoseKit
```

On Windows, put the toolchain on PATH first:

```bash
export PATH="$LOCALAPPDATA/Programs/Swift/Toolchains/6.3.3+Asserts/usr/bin:$LOCALAPPDATA/Programs/Swift/Runtimes/6.3.3/usr/bin:$PATH"
export SDKROOT="$LOCALAPPDATA/Programs/Swift/Platforms/6.3.3/Windows.platform/Developer/SDKs/Windows.sdk"
```

**The full app (Mac + Xcode):**

```bash
brew install xcodegen        # once
xcodegen                     # regenerates Pose.xcodeproj (git-ignored)
open Pose.xcodeproj
```

`Pose.xcodeproj` is generated, never committed — always regenerate with
`xcodegen` after pulling.

## CI

`.github/workflows/ci.yml` runs on every push:

- **posekit** — `swift test` on the pose math (33 tests)
- **app** — `xcodegen` + `xcodebuild test` on an iPhone simulator

## Shipping

See [`docs/RELEASE.md`](docs/RELEASE.md) for the full App Review checklist —
Superwall keys and campaign gating, subscription products, legal links, the
Release-build gate check, and the on-device QA pass. Several items there are
hard blockers.
