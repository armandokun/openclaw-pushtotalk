import Foundation
import Speech
import AVFoundation

/// Main speech-to-text engine combining recording and recognition
@MainActor
class SpeechToTextEngine: ObservableObject {
    @Published var transcribedText = ""
    @Published var isRecording = false
    
    private var speechRecognizer: SpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        speechRecognizer = SpeechRecognizer()
        audioEngine = AVAudioEngine()
    }
    
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechAuthorized = await speechRecognizer?.requestAuthorization() ?? false
        
        // Request microphone authorization
        let micAuthorized = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        PTTLogger.info("Speech: \(speechAuthorized), Mic: \(micAuthorized)")
        return speechAuthorized && micAuthorized
    }
    
    func startRecording() async {
        guard let engine = audioEngine else { return }
        
        // Reset previous state
        transcribedText = ""
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        guard let request = speechRecognizer?.createRecognitionRequest() else {
            PTTLogger.error("Failed to create recognition request")
            return
        }
        recognitionRequest = request
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            PTTLogger.error("Failed to configure audio session: \(error)")
            return
        }
        
        // Setup audio engine
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on audio node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        // Prepare and start engine
        engine.prepare()
        do {
            try engine.start()
            isRecording = true
            PTTLogger.info("Recording started")
        } catch {
            PTTLogger.error("Failed to start audio engine: \(error)")
            return
        }
        
        // Start recognition task
        guard let recognizer = speechRecognizer?.speechRecognizer else { return }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        PTTLogger.info("Final transcription: \(self?.transcribedText ?? "")")
                    }
                }
                
                if let error = error {
                    PTTLogger.error("Recognition error: \(error)")
                }
            }
        }
    }
    
    func stopRecording() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
        
        PTTLogger.info("Recording stopped. Final text: \(transcribedText)")
    }
}
