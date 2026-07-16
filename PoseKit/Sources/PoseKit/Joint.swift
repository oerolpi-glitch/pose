/// The 19 body joints tracked by Apple Vision's VNDetectHumanBodyPoseRequest.
/// Raw values are the JSON keys used in bundled reference pose files.
public enum Joint: String, CaseIterable, Codable, Sendable, Hashable {
    case nose, leftEye, rightEye, leftEar, rightEar
    case neck, leftShoulder, rightShoulder
    case leftElbow, rightElbow, leftWrist, rightWrist
    case root, leftHip, rightHip
    case leftKnee, rightKnee, leftAnkle, rightAnkle
}
