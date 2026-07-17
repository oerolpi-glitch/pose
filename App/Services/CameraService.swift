import AVFoundation

protocol CameraServicing: AnyObject {
    var session: AVCaptureSession { get }
    var isFront: Bool { get }
    func configure() async -> Bool
    func start()
    func stop()
    func switchCamera()
    func setVideoOutputDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
                                queue: DispatchQueue)
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate)
}

/// Owns the AVCaptureSession. All session mutations happen on `sessionQueue`.
final class CameraService: NSObject, CameraServicing {
    let session = AVCaptureSession()
    private(set) var isFront = false

    private let sessionQueue = DispatchQueue(label: "pose.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?

    func configure() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else { return false }
        return await withCheckedContinuation { cont in
            sessionQueue.async { [self] in
                session.beginConfiguration()
                session.sessionPreset = .hd1280x720

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    session.commitConfiguration()
                    cont.resume(returning: false)
                    return
                }
                session.addInput(input)
                currentInput = input

                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.videoSettings =
                    [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
                if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

                if let conn = videoOutput.connection(with: .video),
                   conn.isVideoRotationAngleSupported(90) {
                    conn.videoRotationAngle = 90 // portrait buffers
                }
                session.commitConfiguration()
                cont.resume(returning: true)
            }
        }
    }

    func start() {
        sessionQueue.async { [self] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func switchCamera() {
        sessionQueue.async { [self] in
            guard let old = currentInput else { return }
            let newPosition: AVCaptureDevice.Position = isFront ? .back : .front
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video, position: newPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            session.beginConfiguration()
            session.removeInput(old)
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
                isFront = (newPosition == .front)
            } else {
                session.addInput(old)
            }
            if let conn = videoOutput.connection(with: .video),
               conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90
            }
            session.commitConfiguration()
        }
    }

    func setVideoOutputDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
                                queue: DispatchQueue) {
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        sessionQueue.async { [self] in
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
