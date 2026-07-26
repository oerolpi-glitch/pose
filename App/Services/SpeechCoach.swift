import AVFoundation

/// Speaks coaching aloud so the user can be coached from across the room.
///
/// Every coaching signal in the camera is visual — the readiness chip, the hint
/// bubble, the body map — which assumes the user can read the screen. The moment
/// they step back far enough to fit their whole body in frame, which is exactly
/// what full-body poses require, the screen is unreadable and all of it is
/// wasted. Voice is the only channel that survives the distance: haptics need
/// the phone in hand, and the display is too small to read across a room.
///
/// Tied to hands-free rather than given its own toggle. Hands-free already
/// means "I am not holding the phone", which is the same condition that makes
/// the screen useless — a second switch would ask the user to describe their
/// situation twice.
@MainActor
final class SpeechCoach {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastPhrase: String?
    private var lastSpokenAt: Date = .distantPast
    private var sessionConfigured = false

    /// Floor between any two utterances. Coaching that talks every frame is
    /// worse than silence — the user cannot act faster than they can hear.
    private static let minimumGap: TimeInterval = 2.5
    /// How long before the same phrase may be repeated. Without this, a user
    /// holding one wrong limb is told about it indefinitely.
    private static let repeatGap: TimeInterval = 7

    /// Speaks `phrase` unless it would be chatter. `urgent` bypasses the repeat
    /// suppression (not the gap) for state changes the user must not miss.
    func say(_ phrase: String, urgent: Bool = false) {
        let now = Date()
        guard now.timeIntervalSince(lastSpokenAt) >= Self.minimumGap else { return }
        if !urgent, phrase == lastPhrase,
           now.timeIntervalSince(lastSpokenAt) < Self.repeatGap { return }

        configureSessionIfNeeded()
        let utterance = AVSpeechUtterance(string: phrase)
        // Slightly above default: coaching is short and the user is mid-pose.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.postUtteranceDelay = 0
        synthesizer.speak(utterance)

        lastPhrase = phrase
        lastSpokenAt = now
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lastPhrase = nil
        lastSpokenAt = .distantPast
    }

    /// Deferred until the first utterance so the audio session is never touched
    /// on a run where the user never enables hands-free — the capture session is
    /// video-only and there is no reason to involve audio otherwise.
    ///
    /// `.playback` rather than `.ambient` on purpose: the user is across the
    /// room and a silent switch they forgot about would make the feature look
    /// broken. `.duckOthers` lowers their music instead of stopping it.
    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers]
        )
    }
}
