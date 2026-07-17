import SwiftUI
import UIKit

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        } label: {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(isSelected ? Theme.Colors.onAccent : Theme.Colors.foreground)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Capsule().fill(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
                        .overlay(
                            Capsule().strokeBorder(Theme.Colors.hairline,
                                                   lineWidth: isSelected ? 0 : 1)
                        )
                )
        }
        .buttonStyle(.pressable)
        .animation(Theme.Motion.spring, value: isSelected)
    }
}
