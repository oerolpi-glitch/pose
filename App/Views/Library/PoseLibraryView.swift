import SwiftUI
import PoseKit
import UIKit

struct PoseLibraryView: View {
    @StateObject private var viewModel = PoseLibraryViewModel()
    @StateObject private var favorites = FavoritesStore()
    var onSelect: ((ReferencePose) -> Void)?

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible(), spacing: Theme.Spacing.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("choose a pose")
                    .font(Theme.Typography.stepTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding(.top, Theme.Spacing.xl)

                SearchField(placeholder: "describe your shot", text: $viewModel.query)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagChip(label: tag, isSelected: viewModel.selectedTag == tag) {
                                viewModel.toggleTag(tag)
                            }
                        }
                    }
                }

                Group {
                    if viewModel.results.isEmpty {
                        emptyState
                            .transition(.opacity)
                    } else {
                        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
                            ForEach(viewModel.results) { pose in
                                PoseCard(pose: pose,
                                         isFavorite: favorites.isFavorite(pose.id),
                                         onFavorite: { favorites.toggle(pose.id) },
                                         onSelect: { onSelect?(pose) })
                            }
                        }
                    }
                }
                .animation(Theme.Motion.spring, value: viewModel.results.map(\.id))
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .navigationTitle("")
        .toolbarBackground(Theme.Colors.background, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "magnifyingglass")
                .font(Theme.Icon.hero())
                .foregroundStyle(Theme.Colors.subtitle)
            Text("no poses match")
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.primaryDark)
            Text("try clearing your search or tag filters")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.subtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl * 2)
        .padding(.top, Theme.Spacing.xl)
    }
}

struct PoseCard: View {
    let pose: ReferencePose
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ZStack(alignment: .topTrailing) {
                    MannequinView(pose: pose.poseVector)
                        .padding(Theme.Spacing.s)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(Theme.Motion.spring) {
                            onFavorite()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .contentTransition(.symbolEffect(.replace))
                            .font(Theme.Icon.inline())
                            .foregroundStyle(Theme.Colors.primaryDark)
                            .padding(Theme.Spacing.s)
                    }
                    .buttonStyle(.pressable)
                }
                Text(pose.title)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding([.horizontal, .bottom], Theme.Spacing.m)
            }
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .themedCardShadow()
        }
        .buttonStyle(.pressable)
    }
}
