import SwiftUI

/// The single source of truth for all visual styling.
/// No color, font, spacing, radius, or shadow literals anywhere else.
enum Theme {

    enum Colors {
        /// Soft cream page background.
        static let background = Color(red: 0.961, green: 0.937, blue: 0.902)   // #F5EFE6
        /// Warm dark brown — buttons, headers, primary text.
        static let primaryDark = Color(red: 0.243, green: 0.184, blue: 0.145)  // #3E2F25
        /// Muted taupe for subtitles and secondary text.
        static let subtitle = Color(red: 0.541, green: 0.478, blue: 0.420)     // #8A7A6B
        /// Slightly darker cream for cards.
        static let surface = Color(red: 0.937, green: 0.902, blue: 0.847)      // #EFE6D8
        /// Text/icons on top of primaryDark.
        static let onPrimary = Color(red: 0.961, green: 0.937, blue: 0.902)
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
    /// Soft editorial card shadow.
    func themedCardShadow() -> some View {
        shadow(color: Theme.Colors.primaryDark.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
