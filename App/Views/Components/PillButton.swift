import SwiftUI

struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundStyle(Theme.Colors.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.m + 2)
                .background(Capsule().fill(Theme.Colors.accent))
                .themedPrimaryLift()
        }
        .buttonStyle(.pressable)
    }
}
