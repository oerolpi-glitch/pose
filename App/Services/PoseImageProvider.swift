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

    static func image(for poseID: String) -> UIImage? {
        if let cached = cache[poseID] { return cached }
        guard let url = Bundle.main.url(forResource: poseID,
                                        withExtension: "jpg",
                                        subdirectory: "Poses/Photos"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache[poseID] = image
        return image
    }
}
