import SwiftUI
import Combine
import SuperwallKit

/// Global app state: onboarding completion + subscription entitlement.
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }
    @Published var isSubscribed: Bool = false

    static let onboardingKey = "hasCompletedOnboarding"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Self.onboardingKey)
    }

    /// Mirrors Superwall's entitlement into `isSubscribed`.
    /// Kept out of `init` so the type stays constructible in tests, where
    /// Superwall is never configured — touching `Superwall.shared` there would
    /// bring the SDK up in an unconfigured state.
    func observeSubscriptionStatus() {
        Superwall.shared.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .map(\.isActive)
            .assign(to: &$isSubscribed)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Presents the Pose+ paywall for `placement`; `onGranted` runs when the
    /// user is entitled. Whether it runs ONLY after subscribing depends on the
    /// placement being set to Gated on the Superwall dashboard (see RELEASE.md).
    func unlock(placement: String, onGranted: @escaping () -> Void) {
        Superwall.shared.register(placement: placement, feature: onGranted)
    }
}
