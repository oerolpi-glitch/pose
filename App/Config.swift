import Foundation

enum Config {
    /// Superwall public API key (safe to ship in source — public by design).
    static let superwallAPIKey = "pk_uNYzMv3S_QisMA3aLYYhR"
    static let termsURL = URL(string: "https://oerolpi-glitch.github.io/pose/legal/terms.html")!
    static let privacyURL = URL(string: "https://oerolpi-glitch.github.io/pose/legal/privacy.html")!
}
