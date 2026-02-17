import Foundation
import Speech

/// Handles speech recognition authorization and setup
class SpeechRecognizer: ObservableObject {
    @Published var isAuthorized = false
    @Published var isAvailable = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    init() {
        checkAvailability()
    }
    
    private func checkAvailability() {
        speechRecognizer?.delegate = self
        
        // Check if speech recognition is available
        isAvailable = speechRecognizer?.isAvailable ?? false
        PTTLogger.info("Speech recognizer available: \(isAvailable)")
    }
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.isAuthorized = (status == .authorized)
                    PTTLogger.info("Speech authorization status: \(status.rawValue)")
                    continuation.resume(returning: self.isAuthorized)
                }
            }
        }
    }
    
    func createRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest? {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            PTTLogger.error("Speech recognizer not available")
            return nil
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        
        return request
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            isAvailable = available
            PTTLogger.info("Speech recognizer availability changed: \(available)")
        }
    }
}
