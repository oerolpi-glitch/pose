# Pose — App Store listing

Copy-paste source for App Store Connect. Written for conversion: lead with the
outcome (never freeze in photos), prove the mechanism (live AI coaching),
close with privacy (on-device) — the one claim competitors can't match.

## Name (30 chars max)

> Pose: AI Photo Coach

## Subtitle (30 chars max)

> Live posing, perfect shots

## Promotional text (170 chars, editable without review)

> Your personal posing coach, live in the camera. Real-time guidance,
> a curated pose library, and auto-capture the moment you nail it.

## Description

> **Never freeze in front of a camera again.**
>
> Pose is a real-time posing coach that lives inside your camera. Pick a pose,
> and the live overlay guides your body into it — your match score climbs as
> you adjust, and the shutter fires itself the moment you nail it.
>
> **POSE ME** — Choose from a curated library of editorial poses, each
> photographed with a professional model. A live overlay and a real-time match
> score coach you into the exact stance.
>
> **GUIDE ME** — No target pose, just better photos: live coaching that levels
> your shoulders, straightens your head, and fixes your framing before you
> shoot.
>
> **AUTO-CAPTURE** — Hold the pose and Pose takes the shot hands-free when
> your match score peaks. What you framed is exactly what you get.
>
> **A LIBRARY THAT LOOKS LIKE A MAGAZINE** — Every pose is photographed in a
> consistent editorial set, searchable by shot type: mirror, close-up, selfie,
> full-body, candid.
>
> **PRIVATE BY DESIGN** — All pose detection runs entirely on your iPhone
> using Apple's Vision framework. Your camera feed never leaves your device.
> No account, no uploads, no ads.
>
> Pose requires a subscription. Payment is charged to your Apple account;
> subscriptions renew automatically unless cancelled at least 24 hours before
> the period ends. Terms: https://oerolpi-glitch.github.io/pose-legal/terms.html
> Privacy: https://oerolpi-glitch.github.io/pose-legal/privacy.html

## Keywords (100 chars, comma-separated, no spaces)

> pose,posing,photo,coach,selfie,camera,portrait,model,photoshoot,body,angles,instagram

## Category

- Primary: Photo & Video
- Secondary: Lifestyle

## Age rating

4+ (no objectionable content).

## Privacy nutrition label

App itself collects nothing (on-device processing, no accounts, no analytics).
One caveat to review honestly at submission: the Superwall SDK processes an
anonymous device identifier and subscription events for paywall delivery. In
App Store Connect's privacy questionnaire this likely maps to **Identifiers →
Device ID** and **Purchases → Purchase History**, "used for App Functionality,
not linked to identity, not used for tracking". Check Superwall's current
disclosure guidance (superwall.com → docs → App Privacy) before answering —
do NOT blindly claim "Data Not Collected" with the SDK integrated.

## Screenshots (6.7" required, 6.1" required)

Order tells the story: outcome → mechanism → library → privacy.

1. Camera with live skeleton + 96% score chip — caption "your personal
   posing coach"
2. Pose-me with ghost overlay mid-adjustment — caption "match the pose,
   watch your score climb"
3. Auto-capture moment (gold ring full) — caption "hands-free the moment
   you nail it"
4. Library grid of model photos — caption "a pose library that looks like
   a magazine"
5. Home editorial cover ("pose of the day") — caption "a new pose every day"
6. Dark slide with copy only — caption "100% on-device. your camera never
   leaves your phone."

## Review notes (App Review box)

> All pose detection is on-device (Vision framework); no server component.
> The app is fully functional without network except the paywall, which is
> served by Superwall. A demo subscription is not required: the paywall is the
> standard StoreKit flow with a 3-day trial on the annual product.
