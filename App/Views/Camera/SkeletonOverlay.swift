import SwiftUI

/// Live skeleton wireframe over the camera feed.
struct SkeletonOverlay: View {
    let segments: [(CGPoint, CGPoint)]

    var body: some View {
        Canvas { context, _ in
            for (a, b) in segments {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: .color(Theme.Colors.onPrimary.opacity(0.9)),
                               style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}
