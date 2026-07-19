import SwiftUI
import UIKit
import PoseKit

struct HomeView: View {
    @State private var path = NavigationPath()

    /// Rotates through the library once per day — the home screen becomes an
    /// editorial cover that changes daily instead of a static menu.
    private let dailyPose: ReferencePose? = {
        let poses = PoseLibraryService().allPoses()
        guard !poses.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return poses[day % poses.count]
    }()

    enum HomeRoute: Hashable {
        case library
        case camera(ShootingMode)
        case poseCamera(String)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("pose")
                        .font(Theme.Typography.eyebrow)
                        .themedEyebrow()
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.top, Theme.Spacing.xl)

                    Text("shoot your shot")
                        .font(Theme.Typography.screenTitle)
                        .themedDisplay()
                        .foregroundStyle(Theme.Colors.foreground)
                        .padding(.top, Theme.Spacing.xs)

                    if let pose = dailyPose {
                        DailyPoseCard(pose: pose) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            path.append(HomeRoute.poseCamera(pose.id))
                        }
                        .padding(.top, Theme.Spacing.l)
                    }

                    PillButton(title: "open camera") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        path.append(HomeRoute.camera(.guideMe))
                    }
                    .padding(.top, Theme.Spacing.l)

                    Text("shooting modes")
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.foreground)
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.m)

                    HStack(spacing: Theme.Spacing.m) {
                        ModeCard(title: ShootingMode.poseMe.title,
                                 subtitle: ShootingMode.poseMe.subtitle,
                                 systemImage: "figure.stand") {
                            path.append(HomeRoute.library) // pose-me starts from picking a pose
                        }
                        ModeCard(title: ShootingMode.guideMe.title,
                                 subtitle: ShootingMode.guideMe.subtitle,
                                 systemImage: "waveform.badge.mic") {
                            path.append(HomeRoute.camera(.guideMe))
                        }
                    }

                    WideCard(title: "pose library",
                             subtitle: "browse poses",
                             systemImage: "square.grid.2x2") {
                        path.append(HomeRoute.library)
                    }
                    .padding(.top, Theme.Spacing.m)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .library:
                    PoseLibraryView { pose in
                        path.append(HomeRoute.poseCamera(pose.id))
                    }
                case .camera(let mode):
                    CameraScreen(mode: mode, initialPose: nil)
                case .poseCamera(let id):
                    CameraScreen(mode: .poseMe,
                                 initialPose: PoseLibraryService().allPoses().first { $0.id == id })
                }
            }
        }
        .tint(Theme.Colors.accent)
    }
}

/// The editorial cover: today's pose as a full-width photograph with the title
/// set over a scrim, magazine-style. Tapping starts pose-me on that pose.
/// Renders nothing without a photo — the cover treatment only earns its place
/// with real imagery.
private struct DailyPoseCard: View {
    let pose: ReferencePose
    let action: () -> Void

    private var photo: UIImage? { PoseImageProvider.image(for: pose.id) }

    var body: some View {
        if let photo {
            Button(action: action) {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(4 / 5, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    LinearGradient(colors: [.clear, Theme.Colors.background.opacity(0.9)],
                                   startPoint: .center, endPoint: .bottom)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("pose of the day")
                            .font(Theme.Typography.eyebrow)
                            .themedEyebrow()
                            .foregroundStyle(Theme.Colors.accent)
                        HStack(alignment: .firstTextBaseline) {
                            Text(pose.title)
                                .font(Theme.Typography.stepTitle)
                                .themedDisplay()
                                .foregroundStyle(Theme.Colors.foreground)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(Theme.Icon.inline(.semibold))
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    .padding(Theme.Spacing.m)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .themedCardShadow()
            }
            .buttonStyle(.pressable)
        }
    }
}
