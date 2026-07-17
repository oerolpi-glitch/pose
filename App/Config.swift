import Foundation

enum Config {
    /// Superwall public API key — replace before TestFlight. Dashboard → Settings → Keys.
    static let superwallAPIKey = "pk_REPLACE_ME"
    static let termsURL = URL(string: "https://oerol.notion.site/pose-terms")!
    static let privacyURL = URL(string: "https://oerol.notion.site/pose-privacy")!
}
