import SwiftUI
import UIKit
import Combine
import AVFoundation
import PoseKit

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    @Published var liveSegments: [(CGPoint, CGPoint)] = []
    @Published var score: Float?
    @Published var hintText: String?
    @Published var bodyDetected = true
    @Published var autoCaptureProgress: Double = 0
    @Published var permissionDenied = false
    @Published var capturedImage: UIImage?
    @Published var isFront = false

    let mode: ShootingMode
    let targetPose: ReferencePose?

    private let camera: CameraServicing
    private let detector = PoseDetectionService()
    private let detectionQueue = DispatchQueue(label: "pose.detection", qos: .userInitiated)
    private var viewSize: CGSize = .zero
    private var holdStart: Date?
    private var thermalObserver: NSObjectProtocol?
    private var previewDismissTask: Task<Void, Never>?

    static let autoCaptureThreshold: Float = 0.85
    static let autoCaptureHoldSeconds: TimeInterval = 1.0
    static let previewDismissSeconds: TimeInterval = 3.0

    var session: AVCaptureSession { camera.session }

    init(mode: ShootingMode, targetPose: ReferencePose?,
         camera: CameraServicing = CameraService()) {
        self.mode = mode
        self.targetPose = targetPose
        self.camera = camera
        super.init()
    }

    func start(viewSize: CGSize) async {
        self.viewSize = viewSize
        guard await camera.configure() else {
            permissionDenied = true
            return
        }
        isFront = camera.isFront
        detector.onFrame = { [weak self] pose, bufferSize in
            self?.processFrame(pose: pose, bufferSize: bufferSize)
        }
        camera.setVideoOutputDelegate(detector, queue: detectionQueue)
        observeThermalState()
        camera.start()
    }

    func stop() {
        camera.stop()
        if let o = thermalObserver { NotificationCenter.default.removeObserver(o) }
        previewDismissTask?.cancel()
    }

    func updateViewSize(_ size: CGSize) { viewSize = size }

    func switchCamera() {
        camera.switchCamera()
        // CameraService flips isFront asynchronously on its session queue, so
        // reading it back here would race and see the stale value. Optimistic
        // toggle matches the fire-and-forget request we just made.
        isFront.toggle()
    }

    func capture() {
        guard capturedImage == nil else { return }
        camera.capturePhoto(delegate: self)
    }

    func dismissCapturedPreview() {
        previewDismissTask?.cancel()
        withAnimation(Theme.Motion.spring) {
            capturedImage = nil
        }
    }

    // MARK: - Frame processing (called on detection queue)

    nonisolated private func processFrame(pose: PoseVector?, bufferSize: CGSize) {
        guard let pose else {
            Task { @MainActor in
                self.liveSegments = []
                self.score = nil
                self.bodyDetected = false
                self.updateHold(score: nil)
            }
            return
        }

        Task { @MainActor in
            self.bodyDetected = true

            let mapper = CoordinateMapper(bufferSize: bufferSize,
                                          viewSize: self.viewSize,
                                          isMirrored: self.camera.isFront)
            // PoseKit-space pose for scoring
            var kitPoints: [Joint: SIMD2<Float>] = [:]
            for (j, p) in pose.points {
                kitPoints[j] = mapper.poseKitPoint(fromVisionPoint: CGPoint(x: CGFloat(p.x),
                                                                            y: CGFloat(p.y)))
            }
            let kitPose = PoseVector(points: kitPoints)

            // Skeleton segments in view space
            var segments: [(CGPoint, CGPoint)] = []
            for bone in Bone.allCases {
                let (a, b) = bone.endpoints
                guard let pa = pose.points[a], let pb = pose.points[b] else { continue }
                segments.append((
                    mapper.viewPoint(fromVisionPoint: CGPoint(x: CGFloat(pa.x), y: CGFloat(pa.y))),
                    mapper.viewPoint(fromVisionPoint: CGPoint(x: CGFloat(pb.x), y: CGFloat(pb.y)))
                ))
            }
            self.liveSegments = segments

            switch self.mode {
            case .poseMe:
                if let target = self.targetPose,
                   let result = PoseScorer.score(reference: target.poseVector, live: kitPose) {
                    self.score = result.overall
                    self.hintText = result.hint
                    self.updateHold(score: result.overall)
                } else {
                    self.score = nil
                    self.hintText = nil
                    self.updateHold(score: nil)
                }
            case .guideMe:
                self.score = nil
                self.hintText = PostureHeuristics.hints(for: kitPose).first?.message
            }
        }
    }

    private func updateHold(score: Float?) {
        guard mode == .poseMe else { return }
        guard capturedImage == nil else {
            holdStart = nil
            autoCaptureProgress = 0
            return
        }
        if let s = score, s >= Self.autoCaptureThreshold {
            if holdStart == nil { holdStart = Date() }
            let held = Date().timeIntervalSince(holdStart!)
            autoCaptureProgress = min(held / Self.autoCaptureHoldSeconds, 1)
            if held >= Self.autoCaptureHoldSeconds {
                holdStart = nil
                autoCaptureProgress = 0
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                capture()
            }
        } else {
            holdStart = nil
            autoCaptureProgress = 0
        }
    }

    private func observeThermalState() {
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            let serious = ProcessInfo.processInfo.thermalState.rawValue
                >= ProcessInfo.ThermalState.serious.rawValue
            self?.detector.processEveryNthFrame = serious ? 2 : 1
        }
    }

    private func schedulePreviewDismiss() {
        previewDismissTask?.cancel()
        previewDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.previewDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.dismissCapturedPreview()
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor in
            withAnimation(Theme.Motion.spring) {
                self.capturedImage = image
            }
            self.schedulePreviewDismiss()
        }
    }
}
