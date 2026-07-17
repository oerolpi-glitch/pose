import SwiftUI

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
                context.stroke(path, with: .color(Theme.Colors.primaryDark.opacity(0.35)),
                               style: StrokeStyle(lineWidth: 7, lineCap: .round))
                context.stroke(path, with: .color(Theme.Colors.onPrimary.opacity(0.95)),
                               style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}
