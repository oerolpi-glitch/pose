import SwiftUI

/// Shared tap feedback for every themed tappable component: a slight scale and
/// opacity dip on press, animated with the same spring everywhere.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.Motion.pressedScale : 1)
            .opacity(configuration.isPressed ? Theme.Motion.pressedOpacity : 1)
            .animation(Theme.Motion.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}
