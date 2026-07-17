# Pose Photos — the model-photography pipeline

The library is photo-first (decision: Photogenik-tier imagery). `PoseCard`
checks `PoseImageProvider` for a bundled photograph per pose and falls back to
the rendered figure until one exists. Dropping correctly named files in one
folder upgrades the whole library — no code changes.

## Where files go

```
App/Resources/Poses/Photos/<pose-id>.jpg
```

One JPEG per pose, named exactly by pose id:

| pose id            | file                      |
|--------------------|---------------------------|
| classic-stand      | classic-stand.jpg         |
| mirror-selfie      | mirror-selfie.jpg         |
| power-pose         | power-pose.jpg            |
| crossed-arms       | crossed-arms.jpg          |
| candid-walk        | candid-walk.jpg           |
| peace-selfie       | peace-selfie.jpg          |
| lean-wall          | lean-wall.jpg             |
| hands-pockets      | hands-pockets.jpg         |
| seated-casual      | seated-casual.jpg         |
| close-up-portrait  | close-up-portrait.jpg     |

The `Poses` folder ships as a folder reference (see `project.yml`), so the
`Photos/` subdirectory arrives in the bundle as-is. After adding files, run
`xcodegen` and rebuild.

## Image spec

- **Aspect:** 3:4 portrait. **Size:** 1200×1600 px (cards render @ ~350×466pt max).
- **Format:** JPEG, quality ~80. Keep each under ~400 KB — 10 photos should add
  under 4 MB to the app.
- **Look (must match the Noir Editorial UI):** studio or editorial setting,
  moody/warm lighting, dark or neutral backdrop that sits well on `#0E0E11`.
  One model per image, full pose visible, no brand logos, no busy backgrounds.
  Consistent model + wardrobe across the set reads far more premium than ten
  mismatched stock photos.
- **The pose in the photo must match the pose JSON** (the ghost overlay and
  scoring come from the keypoints, not the photo — a mismatch confuses users).
  Open the app's library, look at the rendered figure, and match it.

## Generating with AI (fastest route)

Any current image model works (Midjourney, DALL·E, Imagen, Flux). Template:

> Full-body editorial fashion photograph of a model, [POSE DESCRIPTION],
> shot on medium format, moody warm studio lighting, dark charcoal backdrop,
> muted tones, subtle film grain, 3:4 portrait crop, no text, no watermark

Pose descriptions per id:

- `classic-stand` — standing relaxed, one hand resting on hip, weight on one leg
- `mirror-selfie` — standing, phone raised at chest height as if shooting a mirror selfie
- `power-pose` — feet wide, both hands on hips, chin level, confident
- `crossed-arms` — standing, arms crossed at chest, slight lean back
- `candid-walk` — mid-stride walking, arms in natural swing, looking ahead
- `peace-selfie` — one hand raised near face in a peace sign, playful
- `lean-wall` — leaning a shoulder against a wall, ankles crossed, hands relaxed
- `hands-pockets` — standing square, both hands in pockets, relaxed shoulders
- `seated-casual` — seated on a stool, elbows on knees, leaning slightly forward
- `close-up-portrait` — chest-up portrait, hands framing near the collar, direct gaze

**Rights:** AI-generated output you create is generally yours to use, but check
the generator's license for commercial use. If sourcing real photography
instead, you need explicit commercial licensing (model + photographer) for
every image — stock "editorial use only" licenses are NOT sufficient for an
app UI.

## Checklist to ship the photo set

- [ ] 10 JPEGs named by pose id in `App/Resources/Poses/Photos/`
- [ ] Each matches its pose JSON stance (compare against the rendered figure)
- [ ] Consistent model/lighting/backdrop across the set
- [ ] Total added size < 5 MB
- [ ] `xcodegen` + rebuild; verify each card shows its photo, favorites heart
      still legible over imagery
- [ ] License/rights confirmed for commercial App Store use
