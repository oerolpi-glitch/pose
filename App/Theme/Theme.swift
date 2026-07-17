import SwiftUI

/// The single source of truth for all visual styling.
/// No color, font, spacing, radius, or shadow literals anywhere else.
enum Theme {

    /// Noir Editorial. A near-black canvas with warm white and a single
    /// champagne-gold accent — premium, photography-forward, cohesive with the
    /// live camera. Roles are named by intent so a future light theme is a
    /// values-only change.
    enum Colors {
        // --- grounds ---
        /// Near-black page canvas.
        static let background = Color(red: 0.055, green: 0.055, blue: 0.067)    // #0E0E11
        /// Slightly lifted surface for cards and controls.
        static let surface = Color(red: 0.110, green: 0.110, blue: 0.129)       // #1C1C21

        // --- content ---
        /// Warm white — primary text, icons, and strokes.
        static let foreground = Color(red: 0.965, green: 0.957, blue: 0.937)    // #F6F4EF
        /// Muted warm grey — secondary text.
        static let secondary = Color(red: 0.655, green: 0.635, blue: 0.606)     // #A7A29B

        // --- accent ---
        /// Champagne gold — the one accent: primary actions, active states, score.
        static let accent = Color(red: 0.788, green: 0.663, blue: 0.416)        // #C9A96A
        /// Deep espresso for text/icons sitting on the gold accent.
        static let onAccent = Color(red: 0.102, green: 0.082, blue: 0.035)      // #1A1509

        // --- utility ---
        /// Dimming layer behind full-screen overlays (captured photo, modals).
        static let scrim = Color.black.opacity(0.62)
        /// Hairline edge that separates surfaces on the dark ground.
        static let hairline = foreground.opacity(0.10)
        /// One consistent frosted fill for every floating control over the
        /// camera feed, so the HUD reads as a single system.
        static let hudChip = Color.black.opacity(0.38)
    }

    /// Semantic type scale. Views name the role, never a size.
    enum Typography {
        /// Serif, 36 — the one big editorial statement per screen ("shoot your shot").
        static let screenTitle = serif(36)
        /// Serif, 30 — headers on secondary screens and onboarding steps.
        static let stepTitle = serif(30)
        /// Serif, 28 — numeric readouts over the camera.
        static let readout = serif(28, weight: .semibold)
        /// Serif, 20 — section headers and card titles.
        static let sectionTitle = serif(20, weight: .semibold)
        /// Sans, 16 — body copy, button labels, subtitles.
        static let body = sans(16)
        /// Sans, 16 semibold — emphasized body (primary button labels, hints).
        static let bodyEmphasis = sans(16, weight: .medium)
        /// Sans, 13 — captions and metadata.
        static let caption = sans(13)

        private static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .serif)
        }

        private static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }
    }

    /// SF Symbol sizes. Weights are matched to the adjacent text at each call site.
    enum Icon {
        /// 24 — feature icons on cards.
        static func feature(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 24, weight: weight)
        }
        /// 16 — inline icons beside body text.
        static func inline(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight)
        }
        /// 14 — accessory icons (chevrons, metadata).
        static func accessory(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 14, weight: weight)
        }
        /// 18 — controls overlaid on the camera.
        static func control(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 18, weight: weight)
        }
        /// 12 — dense decorative glyphs (review stars).
        static func micro(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight)
        }
        /// 44 — the single focal glyph of a full-screen state.
        static func hero(_ weight: Font.Weight = .light) -> Font {
            .system(size: 44, weight: weight)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 24
        static let pill: CGFloat = 999
    }

    /// One spring for every state change in the app, so press feedback,
    /// selection, and screen transitions all move with the same physics.
    enum Motion {
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let pressedScale: CGFloat = 0.97
        static let pressedOpacity: CGFloat = 0.85
    }
}

extension View {
    /// Soft editorial card shadow plus a hairline edge. Card surface and page
    /// differ by only ~3% luminance, so the shadow alone reads muddy; the
    /// hairline gives a crisp, first-party separation. Applied over the same
    /// corner radius the card fills with.
    func themedCardShadow() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.Colors.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
    }

    /// Lift for the primary call-to-action — a soft gold glow so the one gold
    /// action reads as lit rather than flat on the dark ground.
    func themedPrimaryLift() -> some View {
        shadow(color: Theme.Colors.accent.opacity(0.30), radius: 12, x: 0, y: 4)
    }
}
