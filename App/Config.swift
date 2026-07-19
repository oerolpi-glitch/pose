import Foundation

enum Config {
    /// Superwall public API key — replace before TestFlight. Dashboard → Settings → Keys.
    static let superwallAPIKey = "pk_REPLACE_ME"
    static let termsURL = URL(string: "https://oerolpi-glitch.github.io/pose-legal/terms.html")!
    static let privacyURL = URL(string: "https://oerolpi-glitch.github.io/pose-legal/privacy.html")!
}
