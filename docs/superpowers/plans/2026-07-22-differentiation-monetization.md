# Pose — Differentiation & Monetization Phased Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Pose from a structural Photogenik clone into a defensibly-different, conversion-optimized product by replacing the mode-first IA with intent-based pose collections, adding freemium gating, and rebuilding onboarding — then extend with couples posing and a personal-technique profile.

**Architecture:** A shared pose-JSON schema (read verbatim by both platforms) gains two fields — `collections` and `free`. A per-platform intent catalog maps collection ids to display metadata. Home becomes "what are you shooting today?" → collection grid → filtered pose grid. A small `PremiumGate` resolves lock state from `pose.free` + subscription; Superwall's dashboard campaign (placement = `pose_unlock`, set to Gated) decides whether the unlock closure runs. Onboarding stops hard-gating app entry and instead sells Pose+ while leaving free poses usable.

**Tech Stack:** Swift/SwiftUI (iOS 17+, MVVM), Kotlin/Jetpack Compose (minSdk 26), PoseKit (pure-Swift) + posekit (pure-JVM) shared logic, SuperwallKit, GitHub Actions CI (Swift build/test on macos runner; Android assembleDebug on ubuntu).

## Global Constraints

- **Design bar (binding):** first-party Apple polish. Noir Editorial palette — `#0E0E11` near-black, `#F6F4EF` warm white, `#C9A96A` champagne gold. Serif display + sans body. All new UI routes through `Theme` (iOS) / `Theme` (Android) tokens — never hardcode colors, spacing, radii, or type.
- **De-clone rule:** eliminate Photogenik-exact strings from user-facing copy — `pose me`, `guide me`, `shooting modes`, `choose a pose`, `describe your shot`. New IA leads with shooting intent, not camera mode.
- **Cross-platform parity:** every user-facing behavior lands on iOS **and** Android. A task is not done until both platforms carry it (or a follow-up parity task is queued in the same phase).
- **Windows-only dev:** no Mac in this environment. PoseKit (Swift) compiles and tests locally via the Swift toolchain. The iOS **app** (UIKit/SwiftUI) cannot be built locally — iOS app changes are verified by pushing to CI (`xcodebuild`), never claimed as runtime-verified. Android is verified locally on the emulator.
- **Superwall gating lives on the dashboard, not in code.** Placements register a closure that runs on unlock; whether it runs *only after subscribing* depends on the placement being set to **Gated** in the Superwall dashboard. Code must fail safe (never crash / never hard-lock the user out if the SDK is unconfigured). Public key `pk_uNYzMv3S_QisMA3aLYYhR` is already in `App/Config.swift` and is safe in source.
- **Shared JSON schema stays identical across platforms.** Android reads the iOS bundle verbatim (`App/Resources/Poses` is the Android `assets.srcDir`). Any schema change ships to both parsers in the same task.
- **PoseKit stays pure.** No Accelerate / Vision / ML Kit inside the shared libraries — they must keep compiling on Windows and the JVM.
- **Locked product decisions (do not re-litigate):**
  - Intent taxonomy (6): `dating` · `professional` · `mirror` · `fullbody` · `couple` · `candid`.
  - Free tier: `guide-me` coaching (full) + three starter poses — `classic-stand`, `mirror-selfie`, `hands-pockets`. Everything else is Pose+.
  - `couple` collection ships in Phase 1 as a visible "coming soon" collection with zero poses; couples poses arrive in Phase 2.

---

## Phase 1 — De-clone + Intent Collections + Freemium + Onboarding

Ships working software: a re-architected, monetized app on both platforms with the copycat structure removed.

### Phase 1 File Structure

**Shared schema/logic (touched once, both parsers):**
- `PoseKit/Sources/PoseKit/ReferencePose.swift` — add `collections`, `free`.
- `android/posekit/src/main/kotlin/com/oerol/posekit/ReferencePose.kt` — mirror.
- `App/Resources/Poses/*.json` (10 files) — add `collections` + `free` (shared by both apps via assets.srcDir).

**iOS app:**
- Create `App/Models/IntentCollection.swift` — catalog enum + metadata.
- Create `App/Services/PremiumGate.swift` — lock resolution.
- Modify `App/Services/PoseLibraryService.swift` — add `poses(in:)`, free/locked helpers.
- Rewrite `App/Views/Home/HomeView.swift` — intent grid.
- Create `App/Views/Library/CollectionView.swift` — filtered pose grid (replaces the "choose a pose" library as the primary browse surface).
- Modify `App/Views/Library/PoseLibraryView.swift` — repurpose to a searchable "all poses" surface reached from the collection grid; de-clone its copy.
- Modify `App/ViewModels/OnboardingViewModel.swift` + `App/Views/Onboarding/OnboardingSteps.swift` + `App/PoseApp.swift` — soft-gate onboarding.
- Modify `App/AppState.swift` — expose a `presentPaywall` helper used by both onboarding and pose unlock.

**Android app:**
- Create `android/app/src/main/kotlin/com/oerol/pose/data/IntentCollection.kt` — catalog.
- Create `android/app/src/main/kotlin/com/oerol/pose/data/PremiumGate.kt` — lock resolution.
- Modify `android/app/src/main/kotlin/com/oerol/pose/data/PoseRepository.kt` — `poses(in:)` + free helpers.
- Rewrite `android/app/src/main/kotlin/com/oerol/pose/ui/HomeScreen.kt` — intent grid.
- Create `android/app/src/main/kotlin/com/oerol/pose/ui/CollectionScreen.kt` — filtered pose grid.
- Modify `android/app/src/main/kotlin/com/oerol/pose/ui/LibraryScreen.kt` — de-clone copy.
- Modify `android/app/src/main/kotlin/com/oerol/pose/MainActivity.kt` — nav graph for collection route.

**Tests:**
- `PoseKit/Tests/PoseKitTests/ReferencePoseTests.swift` — schema decode.
- `android/posekit/src/test/kotlin/com/oerol/posekit/ReferencePoseTest.kt` — schema decode.

---

### Task 1: Extend the shared pose schema (`collections` + `free`)

**Files:**
- Modify: `PoseKit/Sources/PoseKit/ReferencePose.swift`
- Modify: `android/posekit/src/main/kotlin/com/oerol/posekit/ReferencePose.kt`
- Test: `PoseKit/Tests/PoseKitTests/ReferencePoseTests.swift` (create if absent)
- Test: `android/posekit/src/test/kotlin/com/oerol/posekit/ReferencePoseTest.kt` (create if absent)

**Interfaces:**
- Produces (Swift): `ReferencePose.collections: [String]`, `ReferencePose.free: Bool`; memberwise `init` gains `collections: [String] = [], free: Bool = false`.
- Produces (Kotlin): `ReferencePose.collections: List<String>`, `ReferencePose.free: Boolean`; `fromJson` parses both, defaulting to `emptyList()` / `false` when absent.

- [ ] **Step 1: Write the failing Swift test**

Create `PoseKit/Tests/PoseKitTests/ReferencePoseTests.swift`:

```swift
import XCTest
@testable import PoseKit

final class ReferencePoseTests: XCTestCase {
    func testDecodesCollectionsAndFree() throws {
        let json = """
        {"id":"x","title":"x","tags":["a"],"collections":["dating","fullbody"],
         "free":true,"joints":{"nose":[0.5,0.1]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.collections, ["dating", "fullbody"])
        XCTAssertTrue(pose.free)
    }

    func testLegacyJsonDefaultsCollectionsEmptyAndNotFree() throws {
        let json = """
        {"id":"x","title":"x","tags":["a"],"joints":{"nose":[0.5,0.1]}}
        """.data(using: .utf8)!
        let pose = try JSONDecoder().decode(ReferencePose.self, from: json)
        XCTAssertEqual(pose.collections, [])
        XCTAssertFalse(pose.free)
    }
}
```

- [ ] **Step 2: Run it, verify it fails**

Run: `swift test --package-path PoseKit --filter ReferencePoseTests`
Expected: FAIL — `ReferencePose` has no `collections` / `free`; legacy decode currently succeeds but the new-field test won't compile.

- [ ] **Step 3: Add the fields + a defaulting decoder to `ReferencePose.swift`**

Replace the struct body with:

```swift
public struct ReferencePose: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let tags: [String]
    /// Intent-collection ids this pose belongs to (e.g. "dating", "mirror").
    public let collections: [String]
    /// Free tier: usable without a Pose+ subscription.
    public let free: Bool
    public let joints: [String: [Float]]

    public init(id: String, title: String, tags: [String],
                collections: [String] = [], free: Bool = false,
                joints: [String: [Float]]) {
        self.id = id
        self.title = title
        self.tags = tags
        self.collections = collections
        self.free = free
        self.joints = joints
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, tags, collections, free, joints
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        tags = try c.decode([String].self, forKey: .tags)
        collections = try c.decodeIfPresent([String].self, forKey: .collections) ?? []
        free = try c.decodeIfPresent(Bool.self, forKey: .free) ?? false
        joints = try c.decode([String: [Float]].self, forKey: .joints)
    }

    public var poseVector: PoseVector {
        var pts: [Joint: SIMD2<Float>] = [:]
        for (key, arr) in joints {
            guard let joint = Joint(rawValue: key), arr.count == 2 else { continue }
            pts[joint] = SIMD2<Float>(arr[0], arr[1])
        }
        return PoseVector(points: pts)
    }
}
```

Keep the `#if canImport(Foundation)` import block at the top of the file unchanged.

- [ ] **Step 4: Run the Swift test, verify it passes**

Run: `swift test --package-path PoseKit --filter ReferencePoseTests`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the failing Kotlin test**

Create `android/posekit/src/test/kotlin/com/oerol/posekit/ReferencePoseTest.kt`:

```kotlin
package com.oerol.posekit

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReferencePoseTest {
    @Test fun parsesCollectionsAndFree() {
        val json = """
            {"id":"x","title":"x","tags":["a"],"collections":["dating","fullbody"],
             "free":true,"joints":{"nose":[0.5,0.1]}}
        """.trimIndent()
        val pose = ReferencePose.fromJson(json)
        assertEquals(listOf("dating", "fullbody"), pose.collections)
        assertTrue(pose.free)
    }

    @Test fun legacyJsonDefaults() {
        val json = """{"id":"x","title":"x","tags":["a"],"joints":{"nose":[0.5,0.1]}}"""
        val pose = ReferencePose.fromJson(json)
        assertEquals(emptyList<String>(), pose.collections)
        assertFalse(pose.free)
    }
}
```

- [ ] **Step 6: Run it, verify it fails**

Run: `./gradlew :posekit:test --tests "com.oerol.posekit.ReferencePoseTest"` (from `android/`, using the local Gradle in the scratchpad toolchain).
Expected: FAIL — compile error, `collections` / `free` unresolved.

- [ ] **Step 7: Add the fields to `ReferencePose.kt`**

Add to the data class properties (after `tags`):

```kotlin
    val collections: List<String>,
    val free: Boolean,
```

And in `fromJson`, before the `return`:

```kotlin
            val collectionsArr = obj.optJSONArray("collections")
            val collections = if (collectionsArr == null) emptyList()
                else (0 until collectionsArr.length()).map { collectionsArr.getString(it) }
            val free = obj.optBoolean("free", false)
```

Then extend the returned constructor:

```kotlin
            return ReferencePose(
                id = obj.getString("id"),
                title = obj.getString("title"),
                tags = tags,
                collections = collections,
                free = free,
                joints = joints,
            )
```

- [ ] **Step 8: Run the Kotlin test, verify it passes**

Run: `./gradlew :posekit:test --tests "com.oerol.posekit.ReferencePoseTest"`
Expected: PASS (2 tests).

- [ ] **Step 9: Commit**

```bash
git add PoseKit/Sources/PoseKit/ReferencePose.swift PoseKit/Tests/PoseKitTests/ReferencePoseTests.swift android/posekit/src/main/kotlin/com/oerol/posekit/ReferencePose.kt android/posekit/src/test/kotlin/com/oerol/posekit/ReferencePoseTest.kt
git commit -m "feat(posekit): add collections + free fields to ReferencePose schema"
```

---

### Task 2: Populate collection membership + free flags in pose JSON

**Files:**
- Modify: all 10 files in `App/Resources/Poses/*.json`

**Interfaces:**
- Consumes: schema from Task 1.
- Produces: every pose carries a `collections` array; three carry `free:true`.

Membership + free map (apply exactly):

| pose | collections | free |
|------|-------------|------|
| classic-stand | `["fullbody","dating"]` | **true** |
| mirror-selfie | `["mirror","fullbody"]` | **true** |
| hands-pockets | `["fullbody","professional","dating"]` | **true** |
| close-up-portrait | `["professional","dating"]` | false |
| crossed-arms | `["professional","fullbody"]` | false |
| power-pose | `["professional","dating"]` | false |
| lean-wall | `["candid","dating"]` | false |
| seated-casual | `["candid","dating"]` | false |
| peace-selfie | `["mirror","candid"]` | false |
| candid-walk | `["candid","fullbody"]` | false |

- [ ] **Step 1: Edit each JSON**

For each file add `"collections":[...]` and (for the three free poses) `"free":true` alongside the existing `"tags"` key. Example — `App/Resources/Poses/classic-stand.json` becomes:

```json
{"id":"classic-stand","title":"classic stand","tags":["full-body","casual"],
 "collections":["fullbody","dating"],"free":true,
 "joints":{"nose":[0.5,0.14],"leftEye":[0.53,0.12],"rightEye":[0.47,0.12],
 "leftEar":[0.555,0.135],"rightEar":[0.445,0.135],"neck":[0.5,0.22],
 "leftShoulder":[0.585,0.235],"rightShoulder":[0.415,0.235],
 "leftElbow":[0.615,0.36],"rightElbow":[0.36,0.34],
 "leftWrist":[0.63,0.475],"rightWrist":[0.44,0.46],
 "root":[0.5,0.5],"leftHip":[0.555,0.5],"rightHip":[0.445,0.5],
 "leftKnee":[0.55,0.68],"rightKnee":[0.45,0.68],
 "leftAnkle":[0.55,0.86],"rightAnkle":[0.45,0.86]}}
```

Non-free poses omit the `"free"` key (defaults to false). `couple` has no poses yet, so no JSON references it.

- [ ] **Step 2: Validate every file is still valid JSON**

Run: `for f in App/Resources/Poses/*.json; do python -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || echo "BAD: $f"; done`
Expected: no `BAD:` lines.

- [ ] **Step 3: Assert the free set is exactly three**

Run: `grep -l '"free":true' App/Resources/Poses/*.json | wc -l`
Expected: `3`

- [ ] **Step 4: Commit**

```bash
git add App/Resources/Poses/*.json
git commit -m "feat(poses): assign intent collections + free-tier flags"
```

---

### Task 3: iOS — intent catalog + library query helpers

**Files:**
- Create: `App/Models/IntentCollection.swift`
- Modify: `App/Services/PoseLibraryService.swift`

**Interfaces:**
- Produces: `enum IntentCollection: String, CaseIterable { case dating, professional, mirror, fullbody, couple, candid }` with `id`, `title`, `subtitle`, `systemImage`, `comingSoon`.
- Produces: `PoseLibraryProviding.poses(in collection: IntentCollection) -> [ReferencePose]`.

- [ ] **Step 1: Create the catalog**

`App/Models/IntentCollection.swift`:

```swift
import Foundation

/// A shooting-intent collection — the top-level way users browse poses.
/// This is the app's answer to "what are you shooting today?", and the primary
/// structural difference from a mode-first camera app.
enum IntentCollection: String, CaseIterable, Identifiable, Hashable {
    case dating, professional, mirror, fullbody, couple, candid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dating:       return "dating & profile"
        case .professional: return "professional"
        case .mirror:       return "mirror selfie"
        case .fullbody:     return "full body"
        case .couple:       return "couples"
        case .candid:       return "candid"
        }
    }

    var subtitle: String {
        switch self {
        case .dating:       return "shots that spark a swipe right"
        case .professional: return "headshots that mean business"
        case .mirror:       return "the effortless mirror moment"
        case .fullbody:     return "head-to-toe, framed right"
        case .couple:       return "two people, one great frame"
        case .candid:       return "caught-in-the-moment, on purpose"
        }
    }

    var systemImage: String {
        switch self {
        case .dating:       return "sparkles"
        case .professional: return "briefcase"
        case .mirror:       return "rectangle.portrait"
        case .fullbody:     return "figure.stand"
        case .couple:       return "figure.2"
        case .candid:       return "camera.viewfinder"
        }
    }

    /// No poses shipped yet — shown but not enterable. Couples poses arrive in Phase 2.
    var comingSoon: Bool { self == .couple }
}
```

- [ ] **Step 2: Add the query helper to `PoseLibraryService.swift`**

Add to the `PoseLibraryProviding` protocol:

```swift
    func poses(in collection: IntentCollection) -> [ReferencePose]
```

And implement in `PoseLibraryService`:

```swift
    func poses(in collection: IntentCollection) -> [ReferencePose] {
        cache.filter { $0.collections.contains(collection.rawValue) }
    }
```

- [ ] **Step 3: Compile-check via CI (no local iOS build on Windows)**

This is an iOS app change. Verify by pushing at the end of the iOS batch (Task 8) and reading the `app` CI job. Do not claim runtime verification.

- [ ] **Step 4: Commit**

```bash
git add App/Models/IntentCollection.swift App/Services/PoseLibraryService.swift
git commit -m "feat(ios): intent-collection catalog + library query"
```

---

### Task 4: iOS — freemium gate

**Files:**
- Create: `App/Services/PremiumGate.swift`
- Modify: `App/AppState.swift`

**Interfaces:**
- Produces: `enum PremiumGate { static func isLocked(_ pose: ReferencePose, subscribed: Bool) -> Bool }` returning `!pose.free && !subscribed`.
- Produces: `AppState.unlock(placement:onGranted:)` wrapping `Superwall.shared.register`, and `AppState.isSubscribed` already exists.

- [ ] **Step 1: Create the gate (pure, unit-testable)**

`App/Services/PremiumGate.swift`:

```swift
import PoseKit

/// Resolves whether a pose is behind the Pose+ paywall. Pure so it can be
/// reasoned about without Superwall — the SDK only decides what happens when a
/// locked pose is tapped, not what counts as locked.
enum PremiumGate {
    static func isLocked(_ pose: ReferencePose, subscribed: Bool) -> Bool {
        !pose.free && !subscribed
    }
}
```

- [ ] **Step 2: Add the unlock helper to `AppState.swift`**

Add:

```swift
    /// Presents the Pose+ paywall for `placement`; `onGranted` runs when the
    /// user is entitled. Whether it runs ONLY after subscribing depends on the
    /// placement being set to Gated on the Superwall dashboard (see RELEASE.md).
    func unlock(placement: String, onGranted: @escaping () -> Void) {
        Superwall.shared.register(placement: placement, feature: onGranted)
    }
```

(Import `SuperwallKit` is already present in `AppState.swift`.)

- [ ] **Step 3: Compile-check via CI**

Verified in the Task 8 push.

- [ ] **Step 4: Commit**

```bash
git add App/Services/PremiumGate.swift App/AppState.swift
git commit -m "feat(ios): premium gate + paywall unlock helper"
```

---

### Task 5: iOS — Home as intent grid + collection detail

**Files:**
- Rewrite: `App/Views/Home/HomeView.swift`
- Create: `App/Views/Library/CollectionView.swift`
- Modify: `App/Views/Library/PoseLibraryView.swift` (de-clone copy only)

**Interfaces:**
- Consumes: `IntentCollection` (Task 3), `PoseLibraryService.poses(in:)`, `PremiumGate` (Task 4), `AppState.unlock` + `isSubscribed`.
- Produces: `HomeRoute` gains `.collection(IntentCollection)`; `CollectionView(collection:onSelect:)`.

- [ ] **Step 1: Rewrite `HomeView.swift`**

Replace the body's menu (the "shooting modes" row, the two `ModeCard`s, and the "pose library" `WideCard`) with an intent grid. Keep `DailyPoseCard` and the daily-pose logic. Key copy changes: eyebrow stays `pose`; title becomes `what are you shooting today?`; the daily card eyebrow stays `pose of the day`; the free coaching entry becomes a `WideCard` titled `live coaching` / subtitle `real-time posture feedback` (replaces `open camera` + `guide me`). New grid:

```swift
                    Text("what are you shooting today?")
                        .font(Theme.Typography.screenTitle)
                        .themedDisplay()
                        .foregroundStyle(Theme.Colors.foreground)
                        .padding(.top, Theme.Spacing.xs)

                    // daily cover retained here (unchanged DailyPoseCard block)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m),
                                        GridItem(.flexible(), spacing: Theme.Spacing.m)],
                              spacing: Theme.Spacing.m) {
                        ForEach(IntentCollection.allCases) { collection in
                            CollectionCard(collection: collection) {
                                guard !collection.comingSoon else { return }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                path.append(HomeRoute.collection(collection))
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.l)

                    WideCard(title: "live coaching",
                             subtitle: "real-time posture feedback",
                             systemImage: "waveform.badge.mic") {
                        path.append(HomeRoute.camera(.guideMe))
                    }
                    .padding(.top, Theme.Spacing.m)
```

Update `HomeRoute`:

```swift
    enum HomeRoute: Hashable {
        case collection(IntentCollection)
        case allPoses
        case camera(ShootingMode)
        case poseCamera(String)
    }
```

Update `navigationDestination`:

```swift
                case .collection(let collection):
                    CollectionView(collection: collection) { pose in
                        path.append(HomeRoute.poseCamera(pose.id))
                    }
                case .allPoses:
                    PoseLibraryView { pose in
                        path.append(HomeRoute.poseCamera(pose.id))
                    }
                case .camera(let mode):
                    CameraScreen(mode: mode, initialPose: nil)
                case .poseCamera(let id):
                    CameraScreen(mode: .poseMe,
                                 initialPose: PoseLibraryService().allPoses().first { $0.id == id })
```

Add a `CollectionCard` view in the same file (mirror `ModeCard`'s styling, with a `comingSoon` treatment):

```swift
private struct CollectionCard: View {
    let collection: IntentCollection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Image(systemName: collection.systemImage)
                    .font(Theme.Icon.feature())
                    .foregroundStyle(Theme.Colors.accent)
                Spacer(minLength: Theme.Spacing.l)
                Text(collection.title)
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.foreground)
                Text(collection.comingSoon ? "coming soon" : collection.subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Colors.hairline, lineWidth: 1))
            .opacity(collection.comingSoon ? 0.55 : 1)
        }
        .buttonStyle(.pressable)
        .disabled(collection.comingSoon)
    }
}
```

Delete the now-unused `ModeCard`/`WideCard` calls' old wording but keep the `WideCard` component if it lives elsewhere; if `ModeCard` is now unreferenced, remove its usage (leave the component definition if shared).

- [ ] **Step 2: Create `CollectionView.swift`**

`App/Views/Library/CollectionView.swift` — a filtered pose grid reusing `PoseCard`, with lock badges and paywall routing:

```swift
import SwiftUI
import PoseKit
import UIKit

struct CollectionView: View {
    let collection: IntentCollection
    var onSelect: (ReferencePose) -> Void

    @EnvironmentObject private var appState: AppState
    @StateObject private var favorites = FavoritesStore()

    private var poses: [ReferencePose] { PoseLibraryService().poses(in: collection) }
    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.m),
                           GridItem(.flexible(), spacing: Theme.Spacing.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(collection.title)
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(.top, Theme.Spacing.xl)
                Text(collection.subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondary)
                    .padding(.top, Theme.Spacing.xs)

                LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
                    ForEach(poses) { pose in
                        PoseCard(pose: pose,
                                 isLocked: PremiumGate.isLocked(pose, subscribed: appState.isSubscribed),
                                 isFavorite: favorites.isFavorite(pose.id),
                                 onFavorite: { favorites.toggle(pose.id) },
                                 onSelect: { select(pose) })
                    }
                }
                .padding(.top, Theme.Spacing.l)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .toolbarBackground(Theme.Colors.background, for: .navigationBar)
    }

    private func select(_ pose: ReferencePose) {
        if PremiumGate.isLocked(pose, subscribed: appState.isSubscribed) {
            appState.unlock(placement: "pose_unlock") { onSelect(pose) }
        } else {
            onSelect(pose)
        }
    }
}
```

- [ ] **Step 3: Add `isLocked` to `PoseCard` (in `PoseLibraryView.swift`)**

Add a `let isLocked: Bool` stored property (default it at call sites), and render a lock chip in the top-leading corner when locked:

```swift
            .overlay(alignment: .topLeading) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(Theme.Icon.inline())
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(Theme.Spacing.s)
                        .themedHUD(Circle())
                        .padding(Theme.Spacing.xs)
                }
            }
```

Update `PoseLibraryView`'s own `PoseCard(...)` call to pass `isLocked: PremiumGate.isLocked(pose, subscribed: appState.isSubscribed)` and add `@EnvironmentObject private var appState: AppState`. Also de-clone `PoseLibraryView` copy: title `choose a pose` → `all poses`; search placeholder `describe your shot` → `search poses`.

- [ ] **Step 4: Route lock taps in `PoseLibraryView` too**

Wrap its `onSelect?(pose)` in the same gate as `CollectionView.select` so the "all poses" surface honors locking. Factor the gate into a small private helper or duplicate the four-line check.

- [ ] **Step 5: Push + verify on CI**

```bash
git add App/Views/Home/HomeView.swift App/Views/Library/CollectionView.swift App/Views/Library/PoseLibraryView.swift
git commit -m "feat(ios): intent-grid home + collection detail + lock badges"
git push
```
Then read the `app` job of the latest run: `gh run list --limit 1` then `gh run view <id> --log-failed`. Expected: `app` job compiles green. If red, fix and re-push before proceeding.

---

### Task 6: iOS — soft-gate onboarding + de-clone its copy

**Files:**
- Modify: `App/PoseApp.swift`
- Modify: `App/Views/Onboarding/OnboardingSteps.swift`
- Modify: `App/ViewModels/OnboardingViewModel.swift`

**Interfaces:**
- Consumes: `AppState.completeOnboarding`, `AppState.unlock`.
- Produces: onboarding always completes into `HomeView`; the paywall is offered, not required.

- [ ] **Step 1: Make the final step complete regardless of purchase**

In `CustomPlanStep` (`OnboardingSteps.swift`), change the CTA so it always lands the user in the app, presenting the paywall as an offer:

```swift
                PillButton(title: "start posing free") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    appState.completeOnboarding()
                    appState.unlock(placement: "onboarding_complete") { }
                }
```

Add below it a secondary line:

```swift
                Button("see everything in Pose+") {
                    appState.unlock(placement: "onboarding_complete") { }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
                .buttonStyle(.pressable)
```

Rationale: onboarding no longer hard-locks entry (kills the "subscribe or leave" wall). The free poses are usable immediately; Pose+ is sold in-flow and re-offered at every locked pose via `pose_unlock`.

- [ ] **Step 2: De-clone the feature-reveal copy**

In `FeatureRevealStep`, replace the `features` array (which literally lists "pose me" / "guide me" / "pose library") with intent-framed value:

```swift
    private let features: [(String, String, String)] = [
        ("sparkles", "collections for every shot", "dating, professional, mirror, candid — curated for the moment"),
        ("waveform.badge.mic", "live coaching", "real-time feedback fixes your posture as you move"),
        ("figure.stand", "match the guide", "line up with the on-screen guide and nail it")
    ]
```

- [ ] **Step 3: Keep the debug skip; confirm `PoseApp.swift` unchanged behavior**

`PoseApp.swift` already routes on `hasCompletedOnboarding`. No structural change needed — the soft-gate lives in the step. Leave the `#if DEBUG` skip button.

- [ ] **Step 4: Push + verify on CI**

```bash
git add App/Views/Onboarding/OnboardingSteps.swift App/ViewModels/OnboardingViewModel.swift App/PoseApp.swift
git commit -m "feat(ios): soft-gate onboarding, de-clone reveal copy"
git push
```
Verify `app` job green as in Task 5 Step 5.

---

### Task 7: Android — catalog + gate + repository query

**Files:**
- Create: `android/app/src/main/kotlin/com/oerol/pose/data/IntentCollection.kt`
- Create: `android/app/src/main/kotlin/com/oerol/pose/data/PremiumGate.kt`
- Modify: `android/app/src/main/kotlin/com/oerol/pose/data/PoseRepository.kt`

**Interfaces:**
- Produces: `enum class IntentCollection` mirroring iOS (id, title, subtitle, icon, comingSoon).
- Produces: `object PremiumGate { fun isLocked(pose, subscribed): Boolean }`.
- Produces: `PoseRepository.poses(collection: IntentCollection): List<ReferencePose>`.

- [ ] **Step 1: Create `IntentCollection.kt`**

```kotlin
package com.oerol.pose.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.CropPortrait
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.WorkOutline
import androidx.compose.ui.graphics.vector.ImageVector

enum class IntentCollection(
    val id: String,
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val comingSoon: Boolean = false,
) {
    DATING("dating", "dating & profile", "shots that spark a swipe right", Icons.Outlined.AutoAwesome),
    PROFESSIONAL("professional", "professional", "headshots that mean business", Icons.Outlined.WorkOutline),
    MIRROR("mirror", "mirror selfie", "the effortless mirror moment", Icons.Outlined.CropPortrait),
    FULLBODY("fullbody", "full body", "head-to-toe, framed right", Icons.Outlined.PersonOutline),
    COUPLE("couple", "couples", "two people, one great frame", Icons.Outlined.Groups, comingSoon = true),
    CANDID("candid", "candid", "caught-in-the-moment, on purpose", Icons.Outlined.CameraAlt),
}
```

(If any icon name is unavailable in the bundled `material-icons-extended`, substitute the closest existing outlined icon — verify against the dependency before finalizing.)

- [ ] **Step 2: Create `PremiumGate.kt`**

```kotlin
package com.oerol.pose.data

import com.oerol.posekit.ReferencePose

object PremiumGate {
    fun isLocked(pose: ReferencePose, subscribed: Boolean): Boolean = !pose.free && !subscribed
}
```

- [ ] **Step 3: Add the query to `PoseRepository.kt`**

```kotlin
    fun poses(collection: IntentCollection): List<ReferencePose> =
        poses.filter { collection.id in it.collections }
```

- [ ] **Step 4: Build**

Run (from `android/`): `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/com/oerol/pose/data/IntentCollection.kt android/app/src/main/kotlin/com/oerol/pose/data/PremiumGate.kt android/app/src/main/kotlin/com/oerol/pose/data/PoseRepository.kt
git commit -m "feat(android): intent catalog + premium gate + collection query"
```

---

### Task 8: Android — Home intent grid + collection screen + nav

**Files:**
- Rewrite: `android/app/src/main/kotlin/com/oerol/pose/ui/HomeScreen.kt`
- Create: `android/app/src/main/kotlin/com/oerol/pose/ui/CollectionScreen.kt`
- Modify: `android/app/src/main/kotlin/com/oerol/pose/ui/LibraryScreen.kt`
- Modify: `android/app/src/main/kotlin/com/oerol/pose/MainActivity.kt`

**Interfaces:**
- Consumes: Task 7 catalog/gate/query, existing `PoseRepository.photo`, `PillButton`.
- Produces: nav routes `collection/{id}` and `library`; `CollectionScreen(collectionId, onSelect)`.

- [ ] **Step 1: Rewrite `HomeScreen.kt` body**

Replace the "shooting modes" `Text` + `Row` of two `ModeCard`s + the "pose library" `WideCard` with:
- Title `shoot your shot` → `what are you shooting today?`.
- Keep the daily cover `Box` unchanged.
- Replace `PillButton("open camera")` with a `WideCard("live coaching", "real-time posture feedback", Icons.Outlined.GraphicEq, onOpenCamera)`.
- Add a 2-column collection grid. Since the screen already uses `verticalScroll`, lay the grid out as `Column` of `Row`s (chunked pairs) to avoid nested-scroll conflicts:

```kotlin
        Text(
            "what are you shooting today?",
            style = Theme.Typography.screenTitle,
            color = Theme.Colors.foreground,
            modifier = Modifier.padding(top = Theme.Spacing.xs),
        )

        // daily cover Box retained here, unchanged

        Spacer(Modifier.height(Theme.Spacing.l))
        IntentCollection.entries.toList().chunked(2).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(bottom = Theme.Spacing.m),
                horizontalArrangement = Arrangement.spacedBy(Theme.Spacing.m),
            ) {
                row.forEach { collection ->
                    CollectionCard(
                        collection = collection,
                        modifier = Modifier.weight(1f),
                        onClick = { if (!collection.comingSoon) onOpenCollection(collection) },
                    )
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
```

Change `HomeScreen`'s signature to add `onOpenCollection: (IntentCollection) -> Unit` (replacing `onOpenLibrary` for the grid; keep `onOpenCamera` and `onOpenPose`). Add a `CollectionCard` composable mirroring `ModeCard` styling with a `comingSoon` dimming + "coming soon" subtitle and `alpha 0.55`.

- [ ] **Step 2: Create `CollectionScreen.kt`**

A filtered grid reusing the existing `PoseCard` composable from `LibraryScreen.kt` (extract `PoseCard` to file-level visibility if it is currently private, so `CollectionScreen` can use it). Pass a `locked` flag and render a lock badge; route locked taps to the paywall (Task 9 wires the actual Superwall call — here, call an `onLockedSelect` lambda). Signature:

```kotlin
@Composable
fun CollectionScreen(
    collectionId: String,
    onSelect: (ReferencePose) -> Unit,
) {
    val context = LocalContext.current
    val repo = remember { PoseRepository(context) }
    val collection = IntentCollection.entries.first { it.id == collectionId }
    val poses = remember(collectionId) { repo.poses(collection) }
    // header (collection.title / subtitle) + LazyVerticalGrid of PoseCard, mirrors LibraryScreen
}
```

- [ ] **Step 3: De-clone `LibraryScreen.kt` copy**

`choose a pose` → `all poses`; search placeholder `describe your shot` → `search poses` (grep the file for both strings and replace).

- [ ] **Step 4: Wire nav in `MainActivity.kt`**

```kotlin
        composable("home") {
            HomeScreen(
                onOpenCollection = { c -> nav.navigate("collection/${c.id}") },
                onOpenCamera = { nav.navigate("camera") },
                onOpenPose = { pose -> nav.navigate("camera?pose=${pose.id}") },
            )
        }
        composable("collection/{id}") { entry ->
            val id = entry.arguments?.getString("id").orEmpty()
            CollectionScreen(collectionId = id,
                onSelect = { pose -> nav.navigate("camera?pose=${pose.id}") })
        }
```

Keep the existing `library` and `camera?pose={pose}` composables.

- [ ] **Step 5: Build**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 6: Verify on the emulator**

Install and launch; screenshot Home. Expected: "what are you shooting today?" + 6 collection cards (couples dimmed "coming soon") + "live coaching" wide card + daily cover. Tap `dating` → collection grid of the mapped poses. Confirm no "shooting modes" / "pose me" / "choose a pose" strings remain on screen.

- [ ] **Step 7: Commit**

```bash
git add android/app/src/main/kotlin/com/oerol/pose/ui/HomeScreen.kt android/app/src/main/kotlin/com/oerol/pose/ui/CollectionScreen.kt android/app/src/main/kotlin/com/oerol/pose/ui/LibraryScreen.kt android/app/src/main/kotlin/com/oerol/pose/MainActivity.kt
git commit -m "feat(android): intent-grid home + collection screen + de-clone copy"
```

---

### Task 9: Android — freemium gating + paywall bridge

**Files:**
- Modify: `android/app/build.gradle` (or `.kts`) — add Superwall Android SDK (verify current version via the Superwall docs before pinning).
- Create: `android/app/src/main/kotlin/com/oerol/pose/billing/Paywall.kt` — thin wrapper around `Superwall.instance.register(placement) { onGranted() }`, plus a subscription-status holder.
- Modify: `CollectionScreen.kt` + `LibraryScreen.kt` — lock badges + route locked taps through `Paywall`.
- Modify: `android/app/src/main/kotlin/com/oerol/pose/PoseApplication.kt` (create if absent; register in `AndroidManifest.xml`) — `Superwall.configure(this, Config.SUPERWALL_KEY)`.

**Interfaces:**
- Consumes: `PremiumGate.isLocked`, `IntentCollection`.
- Produces: `Paywall.unlock(placement: String, onGranted: () -> Unit)`; `Paywall.isSubscribed: State<Boolean>`.

> **Decision gate:** confirm the Superwall Android SDK is desired for parity now vs. deferring Android monetization. If deferred, ship Android with all poses free (skip lock UI) and queue this task for the Android monetization pass. Default: implement, matching iOS.

- [ ] **Step 1: Add the SDK + configure**

Add the dependency (confirm coordinates/version against Superwall's current Android docs), create `PoseApplication` calling `Superwall.configure(this, "pk_uNYzMv3S_QisMA3aLYYhR")`, register it as `android:name` in the manifest.

- [ ] **Step 2: Wrapper + status**

`Paywall.kt` exposes `unlock(placement, onGranted)` and a `mutableStateOf(false)` `isSubscribed` updated from Superwall's subscription-status flow.

- [ ] **Step 3: Gate the grids**

In `CollectionScreen`/`LibraryScreen`, compute `val locked = PremiumGate.isLocked(pose, Paywall.isSubscribed.value)`, show the lock badge, and on tap: `if (locked) Paywall.unlock("pose_unlock") { onSelect(pose) } else onSelect(pose)`.

- [ ] **Step 4: Build + emulator smoke**

`./gradlew :app:assembleDebug`; launch; confirm locked poses show a lock badge and tapping a locked pose triggers the paywall placement (or, unconfigured, falls through to the pose — never crashes).

- [ ] **Step 5: Commit**

```bash
git add android/app/build.gradle android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/oerol/pose/billing/Paywall.kt android/app/src/main/kotlin/com/oerol/pose/PoseApplication.kt android/app/src/main/kotlin/com/oerol/pose/ui/CollectionScreen.kt android/app/src/main/kotlin/com/oerol/pose/ui/LibraryScreen.kt
git commit -m "feat(android): Superwall paywall + freemium pose gating"
```

---

### Task 10: Phase 1 documentation + dashboard checklist

**Files:**
- Modify: `docs/RELEASE.md` — add the two placements (`pose_unlock`, `onboarding_complete`) and their Gated setting; note free-tier poses.
- Modify: `docs/STORE-LISTING.md` — reflect intent collections + freemium in copy.

- [ ] **Step 1: Document the Superwall dashboard config**

State that both placements must exist and `pose_unlock` must be **Gated** for locking to hold; if non-gated, the app degrades to all-free (fail-open by design).

- [ ] **Step 2: Commit**

```bash
git add docs/RELEASE.md docs/STORE-LISTING.md
git commit -m "docs: freemium placements + intent-collection store copy"
```

---

### Phase 1 Self-Review (run before declaring Phase 1 done)

1. **De-clone coverage:** grep both apps for `pose me`, `guide me`, `shooting modes`, `choose a pose`, `describe your shot` in user-facing strings. Zero on-screen occurrences. (`ShootingMode.poseMe`/`.guideMe` may remain as internal enum cases — they are not user copy.)
2. **Parity:** Home intent grid, collection detail, lock badges, and paywall routing exist on both iOS and Android.
3. **Free tier:** exactly 3 poses free; `guide-me`/live-coaching reachable without paywall; onboarding completes without purchase.
4. **Fail-safe:** unconfigured Superwall never hard-locks the user out of free poses or app entry.
5. **CI:** latest run green on `posekit`, `posekit-kotlin`, and `app` jobs.

---

## Phase 2 — Couples Posing + Personal Technique Profile

Differentiators #3 (multi-person) and the "better than Photogenik's face scan" personalization. Depends on Phase 1's collection + gating scaffolding. **Not broken into bite-sized steps here** — it needs new pose assets and a design pass first; these are the scoped work items with acceptance criteria.

### 2A. Couples / multi-person posing
- **Scope:** author couple reference poses (two skeletons per pose — extend the JSON schema with an optional `second` joint set, or ship paired pose ids). Detect and score two bodies: iOS Vision returns multiple `VNHumanBodyPoseObservation`s; ML Kit needs the multi-pose path. Score each person against their target; the ghost shows two figures.
- **Files (anticipated):** schema in `ReferencePose` (both), `PoseDetectionService`/`PoseAnalyzer` multi-body handling, `CameraViewModel`/`CameraScreen` two-score HUD, `couple` collection populated, new `Ghosts/*` art for pairs.
- **Acceptance:** the `couple` collection loses "coming soon" and lists ≥3 couple poses; camera tracks and scores two people; ghost renders both; works on both platforms.
- **Risk:** two-body detection cost on mid-tier Android — gate frame rate; couples poses are Pose+ (already gated by `free:false`).

### 2B. Personal technique profile (the anti-"your angles")
- **Scope:** an on-device, technique-framed profile — NOT an attractiveness/face score. Aggregate the user's live coaching signals (which limbs they consistently miss, best-scoring angle, posture tendencies) into a private local profile that personalizes hints and collection ordering. Framed as "your posing tendencies", never a rating of the person.
- **Files (anticipated):** a `TechniqueProfile` store (on-device only, both platforms), hooks in `CameraViewModel`/`CameraViewModel.kt` to record per-session limb-miss stats, profile surface in Home.
- **Acceptance:** after a few sessions, Home shows a private "your tendencies" card with actionable technique notes; nothing leaves the device; copy never rates appearance.
- **Guardrail:** privacy-first (no upload), and explicitly not a beauty score — this is the ethical + differentiating line vs. Photogenik's face scan.

---

## Phase 3 — Capture-Time Craft + Retention

Editing-app patterns that raise perceived quality and retention. Held items from prior scope live here. Scoped, not step-level.

### 3A. Composition grid + capture-time framing
- Rule-of-thirds / horizon overlay in the camera; optional. Files: `CameraScreen` (both). Acceptance: toggleable grid, off by default, themed.

### 3B. Favorites → "recipes"
- Promote `FavoritesStore` into saved shot setups (pose + collection + coaching notes) the user can reopen. Files: `FavoritesStore` (both), a "saved" surface. Acceptance: a saved shot reopens straight into `poseMe` with that pose.

### 3C. Streaks / progress
- Lightweight daily-shot streak to drive return visits, on-device. Files: a `Streak` store (both), a Home badge. Acceptance: shooting on consecutive days increments a visible streak; purely local.

### 3D. Held parity polish (only after de-clone has shipped and settled)
- Movable/resizable ghost + closer-to-full-screen selfie framing. Deferred deliberately to avoid deepening the Photogenik resemblance before the de-clone is established. Revisit once Phase 1 differentiation is live and the copycat risk is retired.

---

## Execution Handoff

Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session with checkpoints for review.

Phase 1 is fully specified and executable now. Phases 2–3 are scoped roadmap — expand the chosen phase into bite-sized tasks (re-run writing-plans) when Phase 1 has shipped and its assets/decisions are settled.
