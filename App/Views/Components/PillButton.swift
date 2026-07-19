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

/// The quiet sibling of PillButton for secondary actions that sit over imagery
/// or scrims (retake next to save): system blur instead of a fill, so the gold
/// primary keeps sole ownership of the screen's emphasis.
struct QuietPillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundStyle(Theme.Colors.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.m + 2)
                .themedHUD(Capsule())
        }
        .buttonStyle(.pressable)
    }
}
