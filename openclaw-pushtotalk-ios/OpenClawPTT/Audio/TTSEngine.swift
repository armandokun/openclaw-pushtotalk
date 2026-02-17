import Foundation
import AVFoundation

/// Text-to-speech engine using iOS native synthesizer
@MainActor
class TTSEngine: NSObject, ObservableObject {
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) async {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        synthesizer.stopSpeaking(at: .immediate)
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        
        isSpeaking = true
        PTTLogger.info("Speaking: \(text.prefix(50))...")
        
        synthesizer.speak(utterance)
        
        // Wait for completion
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        continuation?.resume()
        continuation = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            continuation?.resume()
            continuation = nil
            PTTLogger.info("Speech finished")
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            continuation?.resume()
            continuation = nil
            PTTLogger.info("Speech cancelled")
        }
    }
}
