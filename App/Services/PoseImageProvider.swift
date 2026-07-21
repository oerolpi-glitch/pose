import UIKit

/// Resolves the model photograph for a pose, if one is bundled.
///
/// Convention over configuration: a pose with id `classic-stand` gets its
/// photo from `App/Resources/Poses/Photos/classic-stand.jpg` (the `Poses`
/// folder ships as a folder reference, so the subdirectory survives into the
/// bundle). Drop a correctly named JPEG in that folder and the library card
/// upgrades from the rendered figure to the photograph — no code change.
///
/// See docs/POSE-PHOTOS.md for the image spec and generation pipeline.
enum PoseImageProvider {
    private static var cache: [String: UIImage] = [:]
    private static var ghostCache: [String: UIImage] = [:]

    static func image(for poseID: String) -> UIImage? {
        if let cached = cache[poseID] { return cached }
        guard let url = Bundle.main.url(forResource: poseID,
                                        withExtension: "jpg",
                                        subdirectory: "Poses/Photos"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache[poseID] = image
        return image
    }

    /// Ivory 3D-mannequin pose guide for the camera, or nil when none is
    /// bundled. Authored on a black background at `Poses/Ghosts/<id>.jpg`;
    /// brightness is keyed to alpha (gamma 2) so the black falls away and the
    /// figure glows softly over the live feed. See docs/POSE-PHOTOS.md.
    static func ghost(for poseID: String) -> UIImage? {
        if let cached = ghostCache[poseID] { return cached }
        guard let url = Bundle.main.url(forResource: poseID,
                                        withExtension: "jpg",
                                        subdirectory: "Poses/Ghosts"),
              let image = UIImage(contentsOfFile: url.path),
              let keyed = brightnessKeyed(image) else { return nil }
        ghostCache[poseID] = keyed
        return keyed
    }

    /// Rebuilds an image with per-pixel alpha = (luminance)² — bright ivory
    /// stays opaque, black becomes transparent, edges feather.
    private static func brightnessKeyed(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)
        guard let ctx = CGContext(data: &data, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var i = 0
        while i < data.count {
            let r = Float(data[i]), g = Float(data[i + 1]), b = Float(data[i + 2])
            let lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255
            let a = lum * lum
            data[i] = UInt8(r * a); data[i + 1] = UInt8(g * a); data[i + 2] = UInt8(b * a)
            data[i + 3] = UInt8(a * 255)
            i += 4
        }
        return ctx.makeImage().map { UIImage(cgImage: $0) }
    }
}
