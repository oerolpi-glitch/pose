import AVFoundation
import Vision
import PoseKit
import os

/// Intercepts video frames, runs body-pose detection, emits PoseKit poses.
/// Backpressure: if Vision is still processing, the incoming frame is dropped
/// (never queued) so the preview never lags behind real time.
final class PoseDetectionService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Called on the detection queue with Vision-normalized pose (or nil when
    /// no body detected) and the portrait buffer size.
    var onFrame: ((PoseVector?, CGSize) -> Void)?

    /// Thermal fallback: process only every Nth frame (1 = every frame).
    var processEveryNthFrame = 1

    private let sequenceHandler = VNSequenceRequestHandler()
    private let isProcessing = OSAllocatedUnfairLock(initialState: false)
    private var frameCounter = 0
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

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter += 1
        guard frameCounter % processEveryNthFrame == 0 else { return }

        let shouldProcess = isProcessing.withLock { busy -> Bool in
            if busy { return false }
            busy = true
            return true
        }
        guard shouldProcess else { return } // drop frame, Vision busy

        defer { isProcessing.withLock { $0 = false } }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let bufferSize = CGSize(width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)))

        let request = VNDetectHumanBodyPoseRequest()
        do {
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .up)
        } catch {
            onFrame?(nil, bufferSize)
            return
        }

        guard let observation = request.results?.first,
              let recognized = try? observation.recognizedPoints(.all) else {
            onFrame?(nil, bufferSize)
            return
        }

        var points: [PoseKit.Joint: SIMD2<Float>] = [:]
        for (vnJoint, joint) in Self.jointMap {
            guard let p = recognized[vnJoint], p.confidence >= minimumConfidence else { continue }
            points[joint] = SIMD2<Float>(Float(p.location.x), Float(p.location.y))
        }
        onFrame?(points.isEmpty ? nil : PoseVector(points: points), bufferSize)
    }
}
