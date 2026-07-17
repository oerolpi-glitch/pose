import Foundation
import Combine

enum OnboardingStep: Int, CaseIterable {
    case intro, goals, analyzing, socialProof, featureReveal, customPlan

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }
}

final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .intro
    @Published var selectedStruggles: Set<String> = []
    @Published var selectedGoals: Set<String> = []

    static let struggleOptions = [
        "don't know what to do with my hands",
        "stiff posture",
        "finding flattering angles",
        "awkward facial expressions"
    ]

    static let goalOptions = [
        "aesthetic instagram posts",
        "professional headshots",
        "candid travel memories",
        "mirror selfies"
    ]

    func advance() {
        if let next = step.next { step = next }
    }
}
