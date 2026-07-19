import SwiftUI

/// The target pose projected onto the detected body — Procrustes alignment
/// puts the ghost where the user actually stands, at their size, so matching
/// it means moving limbs, not walking to the middle of the frame.
struct GhostOverlay: View {
    let segments: [(CGPoint, CGPoint)]

    var body: some View {
        Canvas { context, _ in
            for (a, b) in segments {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: .color(Color.black.opacity(0.30)),
                               style: StrokeStyle(lineWidth: 8, lineCap: .round))
                context.stroke(path, with: .color(Theme.Colors.accent.opacity(0.75)),
                               style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Live skeleton wireframe over the camera feed.
struct SkeletonOverlay: View {
    let segments: [(CGPoint, CGPoint)]

    var body: some View {
        Canvas { context, _ in
            // Two passes: a dark halo first, the light stroke on top. The light
            // wireframe alone vanishes over bright or cream-clothed subjects;
            // the halo carries its own contrast so the skeleton reads over any
            // background — this is the headline feature, it must stay legible.
            for (a, b) in segments {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: .color(Color.black.opacity(0.45)),
                               style: StrokeStyle(lineWidth: 7, lineCap: .round))
                context.stroke(path, with: .color(Theme.Colors.foreground.opacity(0.95)),
                               style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}
