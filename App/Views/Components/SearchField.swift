import SwiftUI

struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .font(Theme.Icon.inline())
                .foregroundStyle(Theme.Colors.secondary)
            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.foreground)
                .tint(Theme.Colors.accent)
                .autocorrectionDisabled()
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.Colors.hairline, lineWidth: 1))
        )
    }
}
