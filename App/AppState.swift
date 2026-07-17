import SwiftUI
import Combine

/// Global app state: onboarding completion + subscription entitlement.
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }
    @Published var isSubscribed: Bool = false

    static let onboardingKey = "hasCompletedOnboarding"

    init(defaults: UserDefaults = .standard) {
        hasCompletedOnboarding = defaults.bool(forKey: Self.onboardingKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
