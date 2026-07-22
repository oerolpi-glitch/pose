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
        case collection(IntentCollection)
        case allPoses
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

                    Text("what are you shooting today?")
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

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m),
                                        GridItem(.flexible(), spacing: Theme.Spacing.m)],
                              spacing: Theme.Spacing.m) {
                        ForEach(IntentCollection.allCases) { collection in
                            CollectionCard(collection: collection) {
                                guard !collection.comingSoon else { return }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                path.append(HomeRoute.collection(collection))
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.l)

                    WideCard(title: "live coaching",
                             subtitle: "real-time posture feedback",
                             systemImage: "waveform.badge.mic") {
                        path.append(HomeRoute.camera(.guideMe))
                    }
                    .padding(.top, Theme.Spacing.m)

                    WideCard(title: "all poses",
                             subtitle: "search the full library",
                             systemImage: "magnifyingglass") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        path.append(HomeRoute.allPoses)
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
                case .collection(let collection):
                    CollectionView(collection: collection) { pose in
                        path.append(HomeRoute.poseCamera(pose.id))
                    }
                case .allPoses:
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

/// One shooting intent in the home grid — the primary entry point into the
/// library, filtered to that intent. Collections without shipped poses yet
/// (`comingSoon`) render dimmed and inert rather than disappearing, so users
/// see the full breadth of what Pose is building toward.
private struct CollectionCard: View {
    let collection: IntentCollection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Image(systemName: collection.systemImage)
                    .font(Theme.Icon.feature())
                    .foregroundStyle(Theme.Colors.accent)
                Spacer(minLength: Theme.Spacing.l)
                Text(collection.title)
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.foreground)
                Text(collection.comingSoon ? "coming soon" : collection.subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Colors.hairline, lineWidth: 1))
            .opacity(collection.comingSoon ? 0.55 : 1)
        }
        .buttonStyle(.pressable)
        .disabled(collection.comingSoon)
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
