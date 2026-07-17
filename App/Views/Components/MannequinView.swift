import SwiftUI
import PoseKit

/// Draws a 3D-mannequin-style figure from pose keypoints.
/// One renderer serves pose cards, the camera ghost overlay, and onboarding art.
struct MannequinView: View {
    let pose: PoseVector
    var lineColor: Color = Theme.Colors.primaryDark
    var fillHead: Bool = true

    var body: some View {
        Canvas { context, size in
            let pts = projected(into: size)

            func stroke(_ a: Joint, _ b: Joint, width: CGFloat) {
                guard let pa = pts[a], let pb = pts[b] else { return }
                var path = Path()
                path.move(to: pa)
                path.addLine(to: pb)
                context.stroke(path, with: .color(lineColor),
                               style: StrokeStyle(lineWidth: width, lineCap: .round))
            }

            let base = min(size.width, size.height) * 0.045
            for bone in Bone.allCases where bone != .neck {
                let (a, b) = bone.endpoints
                stroke(a, b, width: bone == .torso ? base * 1.5 : base)
            }
            stroke(.leftHip, .rightHip, width: base)
            stroke(.leftShoulder, .rightShoulder, width: base)

            // Head
            if let le = pts[.leftEar], let re = pts[.rightEar] {
                let center = CGPoint(x: (le.x + re.x) / 2, y: (le.y + re.y) / 2)
                let r = max(hypot(le.x - re.x, le.y - re.y) * 0.8, base)
                drawHead(context, center: center, radius: r)
            } else if let nose = pts[.nose] {
                drawHead(context, center: nose, radius: size.height * 0.08)
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }

    private func drawHead(_ context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        if fillHead {
            context.fill(Path(ellipseIn: rect), with: .color(lineColor))
        } else {
            context.stroke(Path(ellipseIn: rect), with: .color(lineColor), lineWidth: 3)
        }
    }

    /// Aspect-fit the normalized pose into the canvas with an 8% inset.
    private func projected(into size: CGSize) -> [Joint: CGPoint] {
        let xs = pose.points.values.map { CGFloat($0.x) }
        let ys = pose.points.values.map { CGFloat($0.y) }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max(),
              maxX > minX, maxY > minY else { return [:] }

        let inset: CGFloat = 0.08
        let avail = CGSize(width: size.width * (1 - 2 * inset), height: size.height * (1 - 2 * inset))
        let scale = min(avail.width / (maxX - minX), avail.height / (maxY - minY))
        let offsetX = (size.width - (maxX - minX) * scale) / 2
        let offsetY = (size.height - (maxY - minY) * scale) / 2

        var out: [Joint: CGPoint] = [:]
        for (j, p) in pose.points {
            out[j] = CGPoint(x: (CGFloat(p.x) - minX) * scale + offsetX,
                             y: (CGFloat(p.y) - minY) * scale + offsetY)
        }
        return out
    }
}
