import SwiftUI
import AVFoundation

/// UIKit bridge hosting the AVCaptureVideoPreviewLayer.
struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession

    final class PreviewController: UIViewController {
        let previewLayer: AVCaptureVideoPreviewLayer

        init(session: AVCaptureSession) {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("unsupported") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.layer.addSublayer(previewLayer)
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer.frame = view.bounds
        }
    }

    func makeUIViewController(context: Context) -> PreviewController {
        PreviewController(session: session)
    }

    func updateUIViewController(_ controller: PreviewController, context: Context) {}
}
