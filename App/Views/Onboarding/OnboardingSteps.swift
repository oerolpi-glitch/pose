import SwiftUI
import PoseKit
import UIKit
import SuperwallKit

// MARK: - 1. Value proposition

/// Opens on the photography, not on chrome. The library's editorial model set is
/// the strongest thing this app owns, so the first screen is a full-bleed frame
/// of it with the headline set over a gradient — the same treatment as the home
/// cover card, so the app introduces itself in the language it then speaks.
/// A drawn stick figure used to sit here, which undersold every photograph
/// waiting one screen later.
struct IntroStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private var cover: UIImage? { PoseImageProvider.image(for: "power-pose") }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let cover {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .clipped()
                    .overlay {
                        // Two stops, not one: the upper stop lifts the type off
                        // the model's shoulder, the lower grounds the button in
                        // the page colour so the screen ends rather than stops.
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.30),
                                .init(color: Theme.Colors.background.opacity(0.75), location: 0.62),
                                .init(color: Theme.Colors.background, location: 0.90)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
            } else {
                Theme.Colors.background.ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("poseview")
                    .font(Theme.Typography.eyebrow).themedEyebrow()
                    .foregroundStyle(Theme.Colors.accent)
                    .revealed(after: Theme.Motion.stagger)

                Text("never freeze in front of a camera again")
                    .font(Theme.Typography.screenTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .fixedSize(horizontal: false, vertical: true)
                    .revealed(after: Theme.Motion.stagger * 2)

                Text("real-time coaching that guides you into your best pose, every shot")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .revealed(after: Theme.Motion.stagger * 3)

                PillButton(title: "get started") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
                    .revealed(after: Theme.Motion.stagger * 4)
            }
            .padding(Theme.Spacing.xl)
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
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
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
                    .foregroundStyle(Theme.Colors.foreground)

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
                    .foregroundStyle(isSelected ? Theme.Colors.onAccent : Theme.Colors.foreground)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Theme.Icon.inline())
                    .foregroundStyle(isSelected ? Theme.Colors.onAccent : Theme.Colors.secondary)
            }
            .padding(Theme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
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
            // No percentage. The duration is a fixed 3.3s, so a counter would be
            // reporting a number it invented — the same fake precision the
            // camera's match score was removed for. A thin arc reads as "working"
            // without claiming to measure anything.
            ZStack {
                Circle()
                    .stroke(Theme.Colors.surface, lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colors.accent,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 132, height: 132)

            Text(messages[messageIndex])
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondary)
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
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(.top, Theme.Spacing.xl)
                    .revealed()

                ForEach(Array(reviews.enumerated()), id: \.element.0) { index, review in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(Theme.Icon.micro())
                                    .foregroundStyle(Theme.Colors.accent)
                            }
                        }
                        Text(review.0)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.foreground)
                        Text(review.1)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.secondary)
                    }
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
                    .themedCardShadow()
                    .revealed(after: Theme.Motion.stagger * Double(index + 1))
                }

                PillButton(title: "continue") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
                    .revealed(after: Theme.Motion.stagger * Double(reviews.count + 1))
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

// MARK: - 5. Feature reveal

struct FeatureRevealStep: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel

    private let features: [(String, String, String)] = [
        ("sparkles", "collections for every shot", "dating, professional, mirror, candid — curated for the moment"),
        ("waveform.badge.mic", "live coaching", "real-time feedback fixes your posture as you move"),
        ("figure.stand", "match the guide", "line up with the on-screen guide and nail it")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("here's what you get")
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(.top, Theme.Spacing.xl)
                    .revealed()

                ForEach(Array(features.enumerated()), id: \.element.1) { index, feature in
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: feature.0)
                            .font(Theme.Icon.feature())
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 44)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(feature.1)
                                .font(Theme.Typography.sectionTitle)
                                .foregroundStyle(Theme.Colors.foreground)
                            Text(feature.2)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.secondary)
                        }
                    }
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
                    .revealed(after: Theme.Motion.stagger * Double(index + 1))
                }

                PillButton(title: "continue") { viewModel.advance() }
                    .padding(.top, Theme.Spacing.s)
                    .revealed(after: Theme.Motion.stagger * Double(features.count + 1))
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
                    .font(Theme.Typography.stepTitle).themedDisplay()
                    .foregroundStyle(Theme.Colors.foreground)
                    .padding(.top, Theme.Spacing.xl)

                Text("built from your answers")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondary)

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    planRow("daily pose coaching",
                            detail: viewModel.selectedGoals.first ?? "aesthetic instagram posts")
                    planRow("fix: \(viewModel.selectedStruggles.first ?? "stiff posture")",
                            detail: "targeted live hints")
                    planRow("curated pose library", detail: "matched to your style")
                }

                PillButton(title: "start posing free") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    appState.completeOnboarding()
                    appState.unlock(placement: "onboarding_complete") { }
                }
                .padding(.top, Theme.Spacing.s)

                Button("see everything in PoseView+") {
                    appState.unlock(placement: "onboarding_complete") { }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
                .buttonStyle(.pressable)

                legalFooter

                #if DEBUG
                Button("skip (debug only)") { appState.completeOnboarding() }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondary)
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
            Text("·").foregroundStyle(Theme.Colors.secondary)
            Link("privacy", destination: Config.privacyURL)
        }
        .font(Theme.Typography.caption)
        .tint(Theme.Colors.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xs)
    }

    private func planRow(_ title: String, detail: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "checkmark.seal.fill")
                .font(Theme.Icon.inline())
                .foregroundStyle(Theme.Colors.accent)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.foreground)
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondary)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(Theme.Colors.surface))
    }
}
