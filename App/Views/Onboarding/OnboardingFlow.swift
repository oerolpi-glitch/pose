import SwiftUI

struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                Group {
                    switch viewModel.step {
                    case .intro:         IntroStep()
                    case .goals:         GoalsStep()
                    case .analyzing:     AnalyzingStep()
                    case .socialProof:   SocialProofStep()
                    case .featureReveal: FeatureRevealStep()
                    case .customPlan:    CustomPlanStep()
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
                .id(viewModel.step)
            }
            .animation(Theme.Motion.spring, value: viewModel.step)
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}
