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
                .foregroundStyle(isSelected ? Theme.Colors.onPrimary : Theme.Colors.primaryDark)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Capsule().fill(isSelected ? Theme.Colors.primaryDark : Theme.Colors.surface)
                )
        }
        .buttonStyle(.pressable)
        .animation(Theme.Motion.spring, value: isSelected)
    }
}
