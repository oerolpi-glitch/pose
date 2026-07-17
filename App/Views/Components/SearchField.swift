import SwiftUI

struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Theme.Colors.subtitle)
            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.primaryDark)
                .tint(Theme.Colors.primaryDark)
                .autocorrectionDisabled()
        }
        .padding(Theme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
    }
}
