# Pose — Release & App Review Checklist

Everything that must be true before this app is submitted. Grouped by where the
work lives. Items marked **BLOCKER** will get the app rejected or make the
paywall give paid features away for free.

## 1. Secrets & config (`App/Config.swift`)

- [ ] **BLOCKER** Replace `superwallAPIKey = "pk_REPLACE_ME"` with the real
      Superwall **public** key (Superwall dashboard → Settings → Keys). With the
      placeholder, the `onboarding_complete` placement never resolves and the
      paywall cannot present.
- [ ] Point `termsURL` and `privacyURL` at real, hosted pages that actually
      load. Apple rejects dead legal links. These are surfaced in-app on the
      final onboarding screen (`CustomPlanStep.legalFooter`) and must also be on
      the Superwall paywall template (below).

## 2. Superwall dashboard (not in this repo — the paywall's behavior lives here)

The app calls `Superwall.shared.register(placement: "onboarding_complete") { completeOnboarding() }`.
Whether that closure runs **only after subscribing** is decided entirely by the
campaign config, not the code.

- [ ] **BLOCKER** Create a campaign with placement `onboarding_complete`.
- [ ] **BLOCKER** Set the placement's feature gating to **Gated**. If it is
      non-gated (or errors, or the SDK is unconfigured), the feature closure
      fires and onboarding completes **for free** — the hard paywall isn't hard.
- [ ] **BLOCKER** The paywall template must contain: a visible **Restore
      Purchases** button, a link to **Terms of Service (EULA)**, and a link to
      **Privacy Policy**. (App Store Review Guideline 3.1.2.)
- [ ] Attach products `pose_annual_trial` (annual, 3-day free trial, primary)
      and `pose_monthly` (monthly, anchor).
- [ ] No fake-urgency countdown timers on the paywall — real Review-rejection
      risk, and the plan forbids it.
- [ ] Verify **airplane-mode / SDK-error behavior on device**: with no network,
      tapping "unlock my plan" must NOT silently complete onboarding. If it does,
      revisit gating — a fail-open gate hands out the app.

## 3. App Store Connect

- [ ] Create the app, bundle id `com.oerol.pose`.
- [ ] Create auto-renewable subscriptions `pose_annual_trial` (with a 3-day
      free-trial introductory offer) and `pose_monthly`; attach both to the
      Superwall dashboard paywall.
- [ ] Privacy nutrition label: **Data Not Collected** — all pose processing is
      on-device, no analytics in v1. Keep this honest; if analytics are added,
      update the label.
- [ ] App description: emphasize on-device privacy and real-time coaching. Do
      not overclaim the AI — describe skeletal tracking, not diagnosis.
- [ ] Screenshots (6.7" + 6.1"): camera with live skeleton + score, the pose
      library grid, home, and an auto-capture moment.

## 4. Release-build integrity

- [ ] **BLOCKER** Confirm the `#if DEBUG` "skip (debug only)" button in
      `CustomPlanStep` is absent from a Release build — build with
      `-configuration Release` and confirm onboarding cannot be bypassed. This is
      the only non-paying way past the gate and must not ship.
- [ ] Set the signing team in Xcode (`CODE_SIGN_STYLE` is Automatic).

## 5. On-device QA (see the Task 16 checklist in the plan)

The whole camera experience has only ever compiled — nothing has run on real
hardware. The full device checklist is in
`docs/superpowers/plans/2026-07-16-pose-app.md` (Task 16). The single
highest-risk item, to check first:

- [ ] **Front-camera mirroring.** Raise your LEFT hand on the front camera → the
      skeleton's raised hand must appear on the same side of the screen as yours,
      and a limb hint must name the correct side. Then confirm the **saved
      photo** matches the mirrored preview you framed against (not flipped).
      Rationale and the exact code path are in `CameraService.configureConnections`.
- [ ] Sustained ≥30 FPS for 3+ minutes (Xcode FPS gauge); watch thermal state
      drop inference to every 2nd frame under load without the UI stalling.

## 6. Design polish pass (on-device — deferred from the blind polish pass)

These are judgment calls on values that can't be tuned without seeing them on a
real screen. The certain-safe polish is already in; these are the finish.

- [ ] Camera HUD on `.ultraThinMaterial` instead of the flat `hudChip` fill —
      floats and blurs the scene like Apple's Camera app. Tune the warm tint so
      it doesn't read cold/grey.
- [ ] Dynamic Type: map the `Theme.Typography` roles to `relativeTo:` text
      styles so type scales with the user's setting. Then verify the largest
      accessibility sizes don't overflow the `ModeCard` fixed `minHeight` or the
      feature-row icon columns.
- [ ] Serif display tracking: large titles (`screenTitle`, `stepTitle`) likely
      want slight negative tracking + tightened leading at 30–36pt.
- [ ] Shutter button: the classic two-ring Apple shutter (outer ring + gap +
      inner disc that dips on press), concentric with the auto-capture ring.
- [ ] Captured-photo preview: give save vs retake a real hierarchy on the dark
      scrim (a light-context button treatment — the current secondary variant is
      built for light backgrounds and was pulled).
- [ ] Spacing rhythm: tighten section-header-to-content gaps and widen
      inter-group gaps on Home and Library for a more composed rhythm.

## TestFlight from CI (no Mac needed)

`.github/workflows/release.yml` archives, signs, and uploads to TestFlight
entirely on GitHub's macOS runners. Signing is cloud-managed — the App Store
Connect API key lets xcodebuild create the distribution certificate and
provisioning profile itself (`-allowProvisioningUpdates`); nothing is exported
from a keychain and no certificate lives in repo secrets.

One-time setup, all doable from a browser:

1. **Enroll** in the Apple Developer Program (developer.apple.com, $99/yr).
2. **App record**: App Store Connect → Apps → **+** → New App, platform iOS,
   bundle ID `com.oerol.pose` (register the bundle ID when prompted), any SKU.
   The upload fails without an existing app record.
3. **API key**: App Store Connect → Users and Access → Integrations →
   App Store Connect API → Team Keys → **+**. Role: **App Manager**. Download
   the `.p8` once (it cannot be re-downloaded) and note the Key ID and the
   Issuer ID shown at the top of the page.
4. **GitHub secrets** (repo → Settings → Secrets and variables → Actions):
   - `ASC_KEY_ID` — the key's ID
   - `ASC_ISSUER_ID` — the issuer ID
   - `ASC_PRIVATE_KEY` — full contents of the `.p8` file
   - `APPLE_TEAM_ID` — 10-char Team ID (developer.apple.com → Membership)
5. **Run**: repo → Actions → TestFlight → Run workflow. `CFBundleVersion` is
   the run number, so every run is a new TestFlight build; bump the
   `marketing_version` input when the user-facing version changes.
6. **Install**: App Store Connect → TestFlight → add yourself as an internal
   tester, then install via the TestFlight app on the iPhone.

## Build

```bash
# On the Mac, from the repo root:
brew install xcodegen        # once
xcodegen                     # regenerates Pose.xcodeproj (git-ignored)
open Pose.xcodeproj
```

CI (`.github/workflows/ci.yml`) runs `swift test` on PoseKit and
`xcodebuild test` on the app for every push. The app job uses
`set -o pipefail` — a compile or test failure fails the job (it did not always:
an earlier `| tail` without pipefail masked app-target failures as green).
