import SwiftUI
import UIKit
import PoseKit

struct CameraScreen: View {
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    init(mode: ShootingMode, initialPose: ReferencePose?) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(mode: mode, targetPose: initialPose))
    }

    /// What the bottom hint bubble should read. A missing body is a designed
    /// state of its own, distinct from (and taking priority over) a scoring hint.
    private var displayHint: String? {
        guard !viewModel.permissionDenied else { return nil }
        guard viewModel.bodyDetected else { return "step into frame" }
        return viewModel.hintText
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
