import Foundation
import Combine

enum OnboardingStep: Int, CaseIterable {
    case intro, goals, analyzing, socialProof, featureReveal, customPlan

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    /// 0...1 position through the flow, for the progress indicator.
    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
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
