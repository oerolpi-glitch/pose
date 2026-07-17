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

    enum Typography {
        /// Elegant serif for editorial headers ("shoot your shot").
        static func header(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .serif)
        }
        static func title() -> Font {
            .system(size: 20, weight: .semibold, design: .serif)
        }
        /// Legible sans-serif for body and subtitles.
        static func body() -> Font {
            .system(size: 16, weight: .regular, design: .default)
        }
        static func caption() -> Font {
            .system(size: 13, weight: .regular, design: .default)
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
}

extension View {
    /// Soft editorial card shadow.
    func themedCardShadow() -> some View {
        shadow(color: Theme.Colors.primaryDark.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
