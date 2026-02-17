import Foundation
import AVFoundation

/// Handles audio recording for PTT
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            PTTLogger.error("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("ptt_recording.m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            PTTLogger.info("Started recording to: \(audioURL.path)")
            return audioURL
        } catch {
            PTTLogger.error("Failed to start recording: \(error)")
            return nil
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        let url = audioRecorder?.url
        PTTLogger.info("Stopped recording: \(url?.path ?? "nil")")
        return url
    }
    
    func getAudioData(from url: URL) -> Data? {
        try? Data(contentsOf: url)
    }
}
