import SwiftUI
import PoseKit

/// A translucent, filled human silhouette the user aligns into — the camera's
/// pose guide. Filled warm-white body (limb capsules + torso + head) with a
/// soft shadow for depth, not a wireframe. Centered and aspect-fit; the score
/// is pose-invariant, so the user matches the shape from anywhere in frame.
struct GhostFigure: View {
    let pose: PoseVector

    var body: some View {
        Canvas { ctx, size in
            let pts = Self.projected(pose, into: size)
            guard !pts.isEmpty else { return }
            let parts = Self.bodyParts(pts, minDim: min(size.width, size.height))

            // One translucent layer: solid fills union by overpaint, then the
            // whole layer composites at low opacity — no seams, no winding holes.
            ctx.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.4), radius: 10))
                layer.opacity = 0.30
                let white = GraphicsContext.Shading.color(Theme.Colors.foreground)
                for part in parts { layer.fill(part, with: white) }
            }
        }
        .allowsHitTesting(false)
    }

    private static func bodyParts(_ p: [Joint: CGPoint], minDim: CGFloat) -> [Path] {
        var parts: [Path] = []
        let limbW = minDim * 0.06
        let slimW = minDim * 0.045

        if let ls = p[.leftShoulder], let rs = p[.rightShoulder],
           let lh = p[.leftHip], let rh = p[.rightHip] {
            var torso = Path()
            torso.move(to: ls); torso.addLine(to: rs)
            torso.addLine(to: rh); torso.addLine(to: lh); torso.closeSubpath()
            parts.append(torso)
        }

        func capsule(_ a: Joint, _ b: Joint, _ w: CGFloat) {
            guard let pa = p[a], let pb = p[b] else { return }
            parts.append(capsulePath(pa, pb, r: w / 2))
        }
        capsule(.leftShoulder, .leftElbow, limbW); capsule(.leftElbow, .leftWrist, slimW)
        capsule(.rightShoulder, .rightElbow, limbW); capsule(.rightElbow, .rightWrist, slimW)
        capsule(.leftHip, .leftKnee, limbW); capsule(.leftKnee, .leftAnkle, slimW)
        capsule(.rightHip, .rightKnee, limbW); capsule(.rightKnee, .rightAnkle, slimW)

        let head: CGPoint?
        let radius: CGFloat
        if let le = p[.leftEar], let re = p[.rightEar] {
            head = CGPoint(x: (le.x + re.x) / 2, y: (le.y + re.y) / 2)
            radius = max(hypot(le.x - re.x, le.y - re.y) * 0.85, minDim * 0.05)
        } else {
            head = p[.nose]
            radius = minDim * 0.06
        }
        if let c = head {
            parts.append(Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius,
                                                width: radius * 2, height: radius * 2)))
        }
        return parts
    }

    private static func capsulePath(_ a: CGPoint, _ b: CGPoint, r: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: a.x - r, y: a.y - r, width: r * 2, height: r * 2))
        path.addEllipse(in: CGRect(x: b.x - r, y: b.y - r, width: r * 2, height: r * 2))
        let dx = b.x - a.x, dy = b.y - a.y
        let len = hypot(dx, dy)
        if len >= 0.001 {
            let px = -dy / len * r, py = dx / len * r
            path.move(to: CGPoint(x: a.x + px, y: a.y + py))
            path.addLine(to: CGPoint(x: b.x + px, y: b.y + py))
            path.addLine(to: CGPoint(x: b.x - px, y: b.y - py))
            path.addLine(to: CGPoint(x: a.x - px, y: a.y - py))
            path.closeSubpath()
        }
        return path
    }

    /// Aspect-fit the normalized pose into the view with a padded inset.
    private static func projected(_ pose: PoseVector, into size: CGSize,
                                  inset: CGFloat = 0.16) -> [Joint: CGPoint] {
        let xs = pose.points.values.map { CGFloat($0.x) }
        let ys = pose.points.values.map { CGFloat($0.y) }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max(),
              maxX > minX, maxY > minY else { return [:] }
        let scale = min(size.width * (1 - 2 * inset) / (maxX - minX),
                        size.height * (1 - 2 * inset) / (maxY - minY))
        let ox = (size.width - (maxX - minX) * scale) / 2
        let oy = (size.height - (maxY - minY) * scale) / 2
        var out: [Joint: CGPoint] = [:]
        for (j, pp) in pose.points {
            out[j] = CGPoint(x: (CGFloat(pp.x) - minX) * scale + ox,
                             y: (CGFloat(pp.y) - minY) * scale + oy)
        }
        return out
    }
}
