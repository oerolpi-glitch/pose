import SwiftUI
import PoseKit
import UIKit
import SuperwallKit

// MARK: - 1. Value proposition

struct IntroStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer()
            if let pose = PoseLibraryService().allPoses().first(where: { $0.id == "power-pose" }) {
                MannequinView(pose: pose.poseVector)
                    .frame(height: 280)
                    .scaleEffect(hasAppeared ? 1 : 0.85)
                    .opacity(hasAppeared ? 1 : 0)
            }
            Text("never freeze in front of a camera again")
                .font(Theme.Typography.screenTitle)
                .foregroundStyle(Theme.Colors.primaryDark)
                .multilineTextAlignment(.center)
            Text("real-time AI coaching that guides you into your best pose, every single shot")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.subtitle)
                .multilineTextAlignment(.center)
            Spacer()
            PillButton(title: "get started") { viewModel.advance() }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            withAnimation(Theme.Motion.spring) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - 2. Goal questionnaire

struct GoalsStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("what do you struggle with most in photos?")
                    .font(Theme.Typography.stepTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding(.top, Theme.Spacing.xl)

                VStack(spacing: Theme.Spacing.s) {
                    ForEach(OnboardingViewModel.struggleOptions, id: \.self) { option in
                        selectableRow(option, isSelected: viewModel.selectedStruggles.contains(option)) {
                            if viewModel.selectedStruggles.contains(option) {
                                viewModel.selectedStruggles.remove(option)
                            } else {
                                viewModel.selectedStruggles.insert(option)
                            }
                        }
                    }
                }

                Text("what type of photos do you want to master?")
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)

                VStack(spacing: Theme.Spacing.s) {
                    ForEach(OnboardingViewModel.goalOptions, id: \.self) { option in
                        selectableRow(option, isSelected: viewModel.selectedGoals.contains(option)) {
                            if viewModel.selectedGoals.contains(option) {
                                viewModel.selectedGoals.remove(option)
                            } else {
                                viewModel.selectedGoals.insert(option)
                            }
                        }
                    }
                }

                PillButton(title: "continue") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
            }
            .padding(Theme.Spacing.xl)
        }
    }

    private func selectableRow(_ label: String, isSelected: Bool,
                               action: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        } label: {
            HStack {
                Text(label)
                    .font(Theme.Typography.body)
                    .foregroundStyle(isSelected ? Theme.Colors.onPrimary : Theme.Colors.primaryDark)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Theme.Icon.inline())
                    .foregroundStyle(isSelected ? Theme.Colors.onPrimary : Theme.Colors.subtitle)
            }
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(isSelected ? Theme.Colors.primaryDark : Theme.Colors.surface)
            )
        }
        .buttonStyle(.pressable)
        .animation(Theme.Motion.spring, value: isSelected)
    }
}

// MARK: - 3. Analyzing animation

struct AnalyzingStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var progress: Double = 0
    @State private var messageIndex = 0

    private let messages = [
        "scanning body mechanics...",
        "curating poses for your goals...",
        "building your custom plan..."
    ]
    private let totalDuration: Double = 3.3

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.Colors.surface, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colors.primaryDark,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(Theme.Typography.screenTitle)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .contentTransition(.numericText(value: progress * 100))
            }
            .frame(width: 180, height: 180)

            Text(messages[messageIndex])
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.subtitle)
                .id(messageIndex)
                .transition(.opacity)

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .task {
            withAnimation(.linear(duration: totalDuration)) {
                progress = 1.0
            }
            let step = totalDuration / Double(messages.count)
            for i in 1..<messages.count {
                try? await Task.sleep(for: .seconds(step))
                withAnimation(Theme.Motion.spring) { messageIndex = i }
            }
            try? await Task.sleep(for: .seconds(step))
            viewModel.advance()
        }
    }
}

// MARK: - 4. Social proof

struct SocialProofStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private let reviews: [(String, String)] = [
        ("\u{201C}this app is my pocket hype man\u{201D}", "mia, 24"),
        ("\u{201C}finally I don't look like a stiff thumb in photos\u{201D}", "jordan, 29"),
        ("\u{201C}my instagram feed has never looked this good\u{201D}", "sofia, 22")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("you're in good company")
                    .font(Theme.Typography.stepTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding(.top, Theme.Spacing.xl)

                ForEach(reviews, id: \.0) { review in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(Theme.Icon.micro())
                                    .foregroundStyle(Theme.Colors.primaryDark)
                            }
                        }
                        Text(review.0)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryDark)
                        Text(review.1)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.subtitle)
                    }
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
                    .themedCardShadow()
                }

                PillButton(title: "continue") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

// MARK: - 5. Feature reveal

struct FeatureRevealStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private let features: [(String, String, String)] = [
        ("figure.stand", "pose me", "pick a pose, match the ghost overlay, nail the shot"),
        ("waveform.badge.mic", "guide me", "live coaching that fixes your posture in real time"),
        ("square.grid.2x2", "pose library", "curated poses for mirror shots, selfies and more")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("here's what you get")
                    .font(Theme.Typography.stepTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding(.top, Theme.Spacing.xl)

                ForEach(features, id: \.1) { feature in
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: feature.0)
                            .font(Theme.Icon.feature())
                            .foregroundStyle(Theme.Colors.primaryDark)
                            .frame(width: 44)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(feature.1)
                                .font(Theme.Typography.sectionTitle)
                                .foregroundStyle(Theme.Colors.primaryDark)
                            Text(feature.2)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.subtitle)
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
                }

                PillButton(title: "continue") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

// MARK: - 6. Custom plan

struct CustomPlanStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("your plan is ready")
                    .font(Theme.Typography.stepTitle)
                    .foregroundStyle(Theme.Colors.primaryDark)
                    .padding(.top, Theme.Spacing.xl)

                Text("built from your answers")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.subtitle)

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    planRow("daily pose coaching",
                            detail: viewModel.selectedGoals.first ?? "aesthetic instagram posts")
                    planRow("fix: \(viewModel.selectedStruggles.first ?? "stiff posture")",
                            detail: "targeted live hints")
                    planRow("curated pose library", detail: "matched to your style")
                }

                PillButton(title: "unlock my plan") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // Presents the `onboarding_complete` paywall. Whether this
                    // closure runs ONLY after subscribing is decided by the
                    // campaign's gating on the Superwall dashboard, not here:
                    // the placement must be set to Gated. If it is non-gated,
                    // errors, or the SDK is unconfigured, the closure fires and
                    // onboarding completes for free. See docs/RELEASE.md.
                    Superwall.shared.register(placement: "onboarding_complete") {
                        appState.completeOnboarding()
                    }
                }
                .padding(.top, Theme.Spacing.s)

                legalFooter

                #if DEBUG
                Button("skip (debug only)") { appState.completeOnboarding() }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.subtitle)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.pressable)
                #endif
            }
            .padding(Theme.Spacing.xl)
        }
    }

    /// Terms + privacy links, shown before the paywall trigger. App Review
    /// requires these reachable from the subscription offer; the Superwall
    /// paywall template carries them too, this is the in-app guarantee.
    private var legalFooter: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Link("terms", destination: Config.termsURL)
            Text("·").foregroundStyle(Theme.Colors.subtitle)
            Link("privacy", destination: Config.privacyURL)
        }
        .font(Theme.Typography.caption)
        .tint(Theme.Colors.subtitle)
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xs)
    }

    private func planRow(_ title: String, detail: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "checkmark.seal.fill")
                .font(Theme.Icon.inline())
                .foregroundStyle(Theme.Colors.primaryDark)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.primaryDark)
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.subtitle)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
    }
}
