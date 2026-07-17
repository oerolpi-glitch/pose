import SwiftUI
import UIKit
import PoseKit

struct CameraScreen: View {
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: ShootingMode, initialPose: ReferencePose?) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(mode: mode, targetPose: initialPose))
    }

    /// The bottom bubble carries coaching only. A missing body gets its own
    /// centered treatment instead, so coaching text never competes with it.
    private var displayHint: String? {
        guard !viewModel.permissionDenied, viewModel.bodyDetected else { return nil }
        return viewModel.hintText
    }

    private var isSearchingForBody: Bool {
        !viewModel.permissionDenied && !viewModel.bodyDetected && viewModel.capturedImage == nil
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()

                if let target = viewModel.targetPose, viewModel.mode == .poseMe {
                    MannequinView(pose: target.poseVector,
                                  lineColor: Theme.Colors.onPrimary.opacity(0.35),
                                  fillHead: false)
                        .allowsHitTesting(false)
                        .padding(Theme.Spacing.xl)
                }

                SkeletonOverlay(segments: viewModel.liveSegments)
                    .ignoresSafeArea()

                if isSearchingForBody {
                    searchingForBodyView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                VStack {
                    topBar
                    Spacer()
                    bottomHUD
                }
                .padding(Theme.Spacing.l)

                if let img = viewModel.capturedImage {
                    capturedPreview(img)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                if viewModel.permissionDenied {
                    permissionDeniedView
                        .transition(.opacity)
                }
            }
            .animation(Theme.Motion.spring, value: isSearchingForBody)
            .task {
                await viewModel.start(viewSize: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                viewModel.updateViewSize(newSize)
            }
            .onDisappear { viewModel.stop() }
        }
        .navigationBarBackButtonHidden(true)
        .statusBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(Theme.Icon.control())
                    .foregroundStyle(Theme.Colors.onPrimary)
                    .padding(Theme.Spacing.m)
                    .background(Circle().fill(Theme.Colors.primaryDark.opacity(0.5)))
            }
            .buttonStyle(.pressable)

            Spacer()

            if let score = viewModel.score {
                Text("\(Int(score * 100))%")
                    .font(Theme.Typography.readout)
                    .foregroundStyle(Theme.Colors.onPrimary)
                    .contentTransition(.numericText())
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(Capsule().fill(Theme.Colors.primaryDark.opacity(0.5)))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer()

            Button {
                viewModel.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(Theme.Icon.control())
                    .foregroundStyle(Theme.Colors.onPrimary)
                    .padding(Theme.Spacing.m)
                    .background(Circle().fill(Theme.Colors.primaryDark.opacity(0.5)))
            }
            .buttonStyle(.pressable)
        }
        .animation(Theme.Motion.spring, value: viewModel.score)
    }

    /// Shown while no body is tracked. Deliberately calm and centered — it is a
    /// state of the app, not a coaching correction, so it gets its own moment
    /// rather than borrowing the hint bubble.
    private var searchingForBodyView: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "figure.stand")
                .font(Theme.Icon.hero())
                .foregroundStyle(Theme.Colors.onPrimary.opacity(0.9))
                .symbolEffect(.pulse)
            Text("step into frame")
                .font(Theme.Typography.stepTitle)
                .foregroundStyle(Theme.Colors.onPrimary)
            Text("stand back until your whole body fits")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.onPrimary.opacity(0.75))
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.primaryDark.opacity(0.45))
        )
        .allowsHitTesting(false)
    }

    private var bottomHUD: some View {
        VStack(spacing: Theme.Spacing.m) {
            Group {
                if let hint = displayHint {
                    Text(hint)
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundStyle(Theme.Colors.onPrimary)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Capsule().fill(Theme.Colors.primaryDark.opacity(0.6)))
                        .id(hint)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(Theme.Motion.spring, value: displayHint)

            ZStack {
                Circle()
                    .trim(from: 0, to: viewModel.autoCaptureProgress)
                    .stroke(Theme.Colors.onPrimary, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 84, height: 84)
                    .animation(Theme.Motion.spring, value: viewModel.autoCaptureProgress)
                Button {
                    viewModel.capture()
                } label: {
                    Circle()
                        .fill(Theme.Colors.onPrimary)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(Theme.Colors.primaryDark, lineWidth: 3))
                }
                .buttonStyle(.pressable)
            }
        }
    }

    private func capturedPreview(_ image: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: Theme.Spacing.l) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .padding(Theme.Spacing.l)
                HStack(spacing: Theme.Spacing.m) {
                    PillButton(title: "save") {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        viewModel.dismissCapturedPreview()
                    }
                    PillButton(title: "retake") {
                        viewModel.dismissCapturedPreview()
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }

    private var permissionDeniedView: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.m) {
                Text("camera access needed")
                    .font(Theme.Typography.readout)
                    .foregroundStyle(Theme.Colors.primaryDark)
                Text("enable camera access in settings to get live pose coaching")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.subtitle)
                    .multilineTextAlignment(.center)
                PillButton(title: "open settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
