import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    var body: some View {
        Button("begin") { appState.completeOnboarding() }
            .font(Theme.Typography.sectionTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
