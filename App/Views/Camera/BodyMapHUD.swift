import SwiftUI
import PoseKit

/// A six-zone stick figure that lights up the body regions currently off the
/// target pose. Marks only what is wrong — an unmarked figure means every
/// tracked limb matched, so silence is the "correct" signal. Marking all six
/// would read as a debug overlay; marking the one arm that is off reads as
/// intelligence.
///
/// Deliberately **not** drawn on the user's live body: marks on a real person
/// read as "*you* are wrong" at the moment they are most self-conscious. This
/// is a diagram of the pose, off to the side, at instrument scale.
struct BodyMapHUD: View {
    let offRegions: Set<BodyRegion>
    /// True when the preview is mirrored (front camera). A mirrored preview is
    /// egocentric — the user's left limb appears on the left of the screen — so
    /// the map matches it. Unmirrored (rear camera), the user faces the lens and
    /// their left appears on the right, so the figure flips.
    let isMirrored: Bool

    private static let size = CGSize(width: 44, height: 72)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }

            let base = min(w, h) * 0.075
            let lit = min(w, h) * 0.105

            for region in BodyRegion.allCases {
                let on = offRegions.contains(region)
                // Weight and brightness carry the state, never hue alone: this
                // reads identically in greyscale, and gold stays reserved for
                // `hold` on the readiness chip so the two never fight.
                let shading = GraphicsContext.Shading.color(
                    on ? Theme.Colors.foreground : Theme.Colors.secondary.opacity(0.45)
                )
                let style = StrokeStyle(lineWidth: on ? lit : base,
                                        lineCap: .round, lineJoin: .round)
                ctx.stroke(Self.path(for: region, p: p), with: shading, style: style)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .scaleEffect(x: isMirrored ? 1 : -1, y: 1)
        .padding(Theme.Spacing.m)
        .themedHUD(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .animation(Theme.Motion.spring, value: offRegions)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var accessibilityText: String {
        guard !offRegions.isEmpty else { return "pose guide, every limb matched" }
        let names = BodyRegion.allCases
            .filter(offRegions.contains)
            .map(\.label)
            .joined(separator: ", ")
        return "pose guide, adjust \(names)"
    }

    /// Figure drawn anatomical-left on the left, which is what a mirrored front
    /// camera shows; `isMirrored` flips it for the rear camera.
    private static func path(for region: BodyRegion,
                             p: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        switch region {
        case .head:
            let c = p(0.5, 0.10)
            let r = p(0.585, 0.10).x - c.x
            path.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        case .torso:
            path.move(to: p(0.34, 0.24)); path.addLine(to: p(0.66, 0.24))
            path.move(to: p(0.50, 0.20)); path.addLine(to: p(0.50, 0.55))
            path.move(to: p(0.40, 0.55)); path.addLine(to: p(0.60, 0.55))
        case .leftArm:
            path.move(to: p(0.34, 0.24))
            path.addLine(to: p(0.20, 0.38)); path.addLine(to: p(0.15, 0.53))
        case .rightArm:
            path.move(to: p(0.66, 0.24))
            path.addLine(to: p(0.80, 0.38)); path.addLine(to: p(0.85, 0.53))
        case .leftLeg:
            path.move(to: p(0.40, 0.55))
            path.addLine(to: p(0.36, 0.76)); path.addLine(to: p(0.33, 0.96))
        case .rightLeg:
            path.move(to: p(0.60, 0.55))
            path.addLine(to: p(0.64, 0.76)); path.addLine(to: p(0.67, 0.96))
        }
        return path
    }
}
