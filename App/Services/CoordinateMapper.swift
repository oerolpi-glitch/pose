import CoreGraphics

/// Maps Vision-normalized points (bottom-left origin, y-up) into
/// (a) view coordinates for an aspect-fill portrait preview and
/// (b) PoseKit normalized y-down coordinates for scoring.
struct CoordinateMapper {
    let bufferSize: CGSize   // portrait-oriented buffer dimensions
    let viewSize: CGSize
    let isMirrored: Bool     // true for front camera

    func viewPoint(fromVisionPoint p: CGPoint) -> CGPoint {
        var x = p.x
        if isMirrored { x = 1 - x }
        let yDown = 1 - p.y

        let scale = max(viewSize.width / bufferSize.width,
                        viewSize.height / bufferSize.height)
        let scaled = CGSize(width: bufferSize.width * scale,
                            height: bufferSize.height * scale)
        let offsetX = (viewSize.width - scaled.width) / 2
        let offsetY = (viewSize.height - scaled.height) / 2

        return CGPoint(x: x * scaled.width + offsetX,
                       y: yDown * scaled.height + offsetY)
    }

    func poseKitPoint(fromVisionPoint p: CGPoint) -> SIMD2<Float> {
        let x = isMirrored ? 1 - p.x : p.x
        return SIMD2<Float>(Float(x), Float(1 - p.y))
    }
}
