import SwiftUI
import SuperwallKit

@main
struct PoseApp: App {
    @StateObject private var appState = AppState()

    init() {
        Superwall.configure(apiKey: Config.superwallAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingFlow()
                }
            }
            .environmentObject(appState)
        }
    }
}
