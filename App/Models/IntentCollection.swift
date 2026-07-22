import Foundation

/// A shooting-intent collection — the top-level way users browse poses.
/// This is the app's answer to "what are you shooting today?", and the primary
/// structural difference from a mode-first camera app.
enum IntentCollection: String, CaseIterable, Identifiable, Hashable {
    case dating, professional, mirror, fullbody, couple, candid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dating:       return "dating & profile"
        case .professional: return "professional"
        case .mirror:       return "mirror selfie"
        case .fullbody:     return "full body"
        case .couple:       return "couples"
        case .candid:       return "candid"
        }
    }

    var subtitle: String {
        switch self {
        case .dating:       return "shots that spark a swipe right"
        case .professional: return "headshots that mean business"
        case .mirror:       return "the effortless mirror moment"
        case .fullbody:     return "head-to-toe, framed right"
        case .couple:       return "two people, one great frame"
        case .candid:       return "caught-in-the-moment, on purpose"
        }
    }

    var systemImage: String {
        switch self {
        case .dating:       return "sparkles"
        case .professional: return "briefcase"
        case .mirror:       return "rectangle.portrait"
        case .fullbody:     return "figure.stand"
        case .couple:       return "figure.2"
        case .candid:       return "camera.viewfinder"
        }
    }

    /// No poses shipped yet — shown but not enterable. Couples poses arrive in Phase 2.
    var comingSoon: Bool { self == .couple }
}
