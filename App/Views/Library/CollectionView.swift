import SwiftUI
import PoseKit
import UIKit

struct CollectionView: View {
    let collection: IntentCollection
    var onSelect: (ReferencePose) -> Void

    @EnvironmentObject private var appState: AppState
    @StateObject private var favorites = FavoritesStore()

    private var poses: [ReferencePose] { PoseLibraryService().poses(in: collection) }
    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.m),
                           GridItem(.flexible(), spacing: Theme.Spacing.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(collection.title)
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(.top, Theme.Spacing.xl)
                Text(collection.subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondary)
                    .padding(.top, Theme.Spacing.xs)

                LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
                    ForEach(poses) { pose in
                        PoseCard(pose: pose,
                                 isLocked: PremiumGate.isLocked(pose, subscribed: appState.isSubscribed),
                                 isFavorite: favorites.isFavorite(pose.id),
                                 onFavorite: { favorites.toggle(pose.id) },
                                 onSelect: { select(pose) })
                    }
                }
                .padding(.top, Theme.Spacing.l)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .toolbarBackground(Theme.Colors.background, for: .navigationBar)
    }

    private func select(_ pose: ReferencePose) {
        if PremiumGate.isLocked(pose, subscribed: appState.isSubscribed) {
            appState.unlock(placement: "pose_unlock") { onSelect(pose) }
        } else {
            onSelect(pose)
        }
    }
}
