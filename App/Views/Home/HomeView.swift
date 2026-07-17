import SwiftUI
import UIKit
import PoseKit

struct HomeView: View {
    @State private var path = NavigationPath()

    enum HomeRoute: Hashable {
        case library
        case camera(ShootingMode)
        case poseCamera(String)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    Text("shoot your shot")
                        .font(Theme.Typography.screenTitle)
                        .foregroundStyle(Theme.Colors.foreground)
                        .padding(.top, Theme.Spacing.xl)

                    PillButton(title: "open camera") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        path.append(HomeRoute.camera(.guideMe))
                    }

                    Text("shooting modes")
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.foreground)

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
