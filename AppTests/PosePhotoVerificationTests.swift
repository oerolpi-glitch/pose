import XCTest
import Vision
import PoseKit
@testable import Pose

/// The app verifies its own imagery: every bundled model photo must contain a
/// detectable body whose pose scores against that pose's reference JSON. A
/// mismatched or unusable photo (wrong pose, flipped, no body) turns CI red
/// before it ever ships. See docs/POSE-PHOTOS.md.
final class PosePhotoVerificationTests: XCTestCase {

    // Loose floor: catches gross mismatches (wrong photo for the id, mirrored
    // pose, undetectable body) without failing on stylistic variation between
    // an authored reference and a photographed model.
    private let minimumOverallScore: Float = 0.5
    private let minimumConfidence: Float = 0.3

    private static let jointMap: [VNHumanBodyPoseObservation.JointName: PoseKit.Joint] = [
        .nose: .nose, .leftEye: .leftEye, .rightEye: .rightEye,
        .leftEar: .leftEar, .rightEar: .rightEar, .neck: .neck,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .root: .root, .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle
    ]

    func testEveryBundledPhotoMatchesItsReferencePose() throws {
        let photoURLs = Bundle.main.urls(forResourcesWithExtension: "jpg",
                                         subdirectory: "Poses/Photos") ?? []
        guard !photoURLs.isEmpty else {
            throw XCTSkip("No pose photos bundled yet")
        }

        let posesByID = Dictionary(uniqueKeysWithValues:
            PoseLibraryService().allPoses().map { ($0.id, $0) })

        for url in photoURLs {
            let poseID = url.deletingPathExtension().lastPathComponent
            guard let reference = posesByID[poseID] else {
                XCTFail("Photo \(url.lastPathComponent) has no matching pose JSON")
                continue
            }
            guard let detected = detectPose(at: url) else {
                XCTFail("\(poseID): no body detected in photo")
                continue
            }
            XCTAssertGreaterThanOrEqual(detected.points.count, 6,
                                        "\(poseID): too few joints detected")
            guard let score = PoseScorer.score(reference: reference.poseVector,
                                               live: detected) else {
                XCTFail("\(poseID): could not score detected pose against reference")
                continue
            }
            XCTAssertGreaterThanOrEqual(
                score.overall, minimumOverallScore,
                "\(poseID): photo/JSON mismatch — overall \(score.overall) " +
                "(procrustes \(score.procrustes), limbs \(score.limbMean))")
        }
    }

    /// Runs body-pose detection on an image file and returns the pose in
    /// PoseKit space — the same Vision→PoseKit transform CoordinateMapper
    /// applies to live frames (y flipped, no mirroring for bundled photos).
    private func detectPose(at url: URL) -> PoseVector? {
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              let recognized = try? observation.recognizedPoints(.all) else { return nil }

        var points: [PoseKit.Joint: SIMD2<Float>] = [:]
        for (vnJoint, joint) in Self.jointMap {
            guard let p = recognized[vnJoint], p.confidence >= minimumConfidence else { continue }
            points[joint] = SIMD2<Float>(Float(p.location.x), Float(1 - p.location.y))
        }
        return points.isEmpty ? nil : PoseVector(points: points)
    }
}
