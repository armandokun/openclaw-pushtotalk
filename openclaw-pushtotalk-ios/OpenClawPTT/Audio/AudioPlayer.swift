import Foundation
import AVFoundation

/// Handles audio playback
@MainActor
class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    
    private var player: AVAudioPlayer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try session.setActive(true)
        } catch {
            PTTLogger.error("Failed to setup playback audio session: \(error)")
        }
    }
    
    func play(url: URL) async {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
            PTTLogger.info("Playing audio from: \(url.path)")
        } catch {
            PTTLogger.error("Failed to play audio: \(error)")
        }
    }
    
    func play(data: Data) async {
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            isPlaying = true
            PTTLogger.info("Playing audio from data")
        } catch {
            PTTLogger.error("Failed to play audio: \(error)")
        }
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
    }
    
    func speak(text: String) async {
        // Use TTS engine for text-to-speech
        let tts = TTSEngine()
        await tts.speak(text)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            PTTLogger.info("Audio playback finished")
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            PTTLogger.error("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        }
    }
}
