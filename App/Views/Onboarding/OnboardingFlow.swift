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

                // The analyzing step is a full-bleed moment; everywhere else, a
                // slim bar shows how far through the flow the user is.
                if viewModel.step != .analyzing {
                    VStack {
                        progressBar
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
            .animation(Theme.Motion.spring, value: viewModel.step)
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Theme.Colors.surface)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.accent)
                        .frame(width: geo.size.width * viewModel.step.progress)
                }
        }
        .frame(height: 4)
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.s)
    }
}
