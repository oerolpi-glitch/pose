import SwiftUI

/// Staggered entrance: content lifts and fades in on a short delay cascade.
///
/// One piece of choreography per screen is what separates a composed app from
/// an assembled one — elements arriving together read as a screen being drawn,
/// elements arriving in sequence read as a screen being presented. The offset
/// is deliberately small (12pt); anything larger reads as a slide transition
/// and fights the navigation animation.
private struct Reveal: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .onAppear {
                withAnimation(Theme.Motion.spring.delay(delay)) { shown = true }
            }
    }
}

extension View {
    /// Reveals this view after `delay` seconds. Stagger siblings by index —
    /// `.revealed(after: Theme.Motion.stagger * 2)` — so the cascade stays on
    /// one rhythm across the app.
    func revealed(after delay: Double = 0) -> some View {
        modifier(Reveal(delay: delay))
    }
}
