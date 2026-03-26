import Foundation
import Combine

// MARK: - Voice Engine
//
// On watchOS, speech recognition is handled by the system dictation built into
// TextField / .searchable. This class provides a lightweight observable wrapper
// so the rest of the app can track "listening" and "speaking" state without
// importing Speech or AVFoundation (neither ships on watchOS).

final class VoiceEngine: ObservableObject {
    @Published var isListening: Bool = false
    @Published var transcription: String = ""
    @Published var isSpeaking: Bool = false

    /// Seconds of silence before auto-sending the transcription.
    var autoSendDelay: TimeInterval = 1.5

    /// Called when silence timer fires after `autoSendDelay`.
    var onAutoSend: ((String) -> Void)?

    private var silenceTimer: Timer?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        // On watchOS, microphone permission is requested automatically by the
        // system when dictation begins. Return true to keep callers happy.
        return true
    }

    // MARK: - Listening (driven by UI dictation)

    func startListening() {
        guard !isListening else { return }
        transcription = ""
        isListening = true
    }

    func stopListening() {
        stopListeningInternal()
    }

    /// Call this when the system dictation result arrives.
    func updateTranscription(_ text: String) {
        transcription = text
        resetSilenceTimer()
    }

    private func stopListeningInternal() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        isListening = false
    }

    // MARK: - Silence Detection

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: autoSendDelay,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            let text = self.transcription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                self.onAutoSend?(text)
            }
            self.stopListeningInternal()
        }
    }

    // MARK: - Text-to-Speech (stub)

    func speak(_ text: String) {
        // TTS is not natively supported on watchOS in the same way.
        // This is a no-op stub; haptic feedback is used instead.
        isSpeaking = false
    }

    func stopSpeaking() {
        isSpeaking = false
    }
}
