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
                    .foregroundStyle(Theme.Colors.foreground)
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
                .foregroundStyle(Theme.Colors.secondary)
            Text("no poses match")
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.foreground)
            Text("try clearing your search or tag filters")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl * 2)
    }
}

struct PoseCard: View {
    let pose: ReferencePose
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onSelect: () -> Void

    /// Photo-first: when a model photograph is bundled for this pose it fills
    /// the card edge-to-edge with the title on a bottom gradient; otherwise the
    /// rendered figure carries the card until its photo lands.
    private var photo: UIImage? { PoseImageProvider.image(for: pose.id) }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                cardBody
                favoriteButton
            }
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .themedCardShadow()
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private var cardBody: some View {
        if let photo {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(2 / 3, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                Text(pose.title)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [.clear, Theme.Colors.background.opacity(0.85)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                MannequinView(pose: pose.poseVector)
                    .padding(Theme.Spacing.s)
                Text(pose.title)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding([.horizontal, .bottom], Theme.Spacing.m)
            }
        }
    }

    private var favoriteButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(Theme.Motion.spring) {
                onFavorite()
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .contentTransition(.symbolEffect(.replace))
                .font(Theme.Icon.inline())
                .foregroundStyle(isFavorite ? Theme.Colors.accent : Theme.Colors.foreground)
                .padding(Theme.Spacing.s)
                .background(Circle().fill(Theme.Colors.hudChip).padding(2))
        }
        .buttonStyle(.pressable)
    }
}
