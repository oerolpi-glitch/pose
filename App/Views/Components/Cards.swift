import SwiftUI

struct ModeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Image(systemName: systemImage)
                    .font(Theme.Icon.feature())
                    .foregroundStyle(Theme.Colors.accent)
                Spacer(minLength: 0)
                Text(title)
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.foreground)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondary)
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .themedCardShadow()
        }
        .buttonStyle(.pressable)
    }
}

struct WideCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: systemImage)
                    .font(Theme.Icon.feature())
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.foreground)
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.Icon.accessory())
                    .foregroundStyle(Theme.Colors.secondary)
            }
            .padding(Theme.Spacing.m)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
            .themedCardShadow()
        }
        .buttonStyle(.pressable)
    }
}
