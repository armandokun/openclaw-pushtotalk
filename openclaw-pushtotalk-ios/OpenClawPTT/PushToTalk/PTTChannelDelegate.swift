import Foundation
import PushToTalk
import Combine

@MainActor
class PTTManager: ObservableObject {
    @Published var channelManager: PTChannelManager?
    @Published var isTransmitting = false
    @Published var isConnected = false
    @Published var transcribedText = ""
    @Published var lastResponse = ""
    
    private var speechEngine: SpeechToTextEngine?
    private var gatewayClient: GatewayClient?
    private var audioPlayer: AudioPlayer?
    private var ttsEngine: TTSEngine?
    
    private let channelUUID = UUID()
    
    func setup() async {
        do {
            // Initialize components
            speechEngine = SpeechToTextEngine()
            gatewayClient = GatewayClient()
            audioPlayer = AudioPlayer()
            ttsEngine = TTSEngine()
            
            // Request speech authorization
            let authorized = await speechEngine?.requestAuthorization() ?? false
            PTTLogger.info("Speech authorization: \(authorized)")
            
            // Setup PTT channel manager
            channelManager = try await PTChannelManager.channelManager(
                delegate: self,
                restorationDelegate: nil
            )
            
            isConnected = true
            PTTLogger.info("PTT Manager setup complete")
        } catch {
            PTTLogger.error("Failed to setup PTT: \(error)")
            isConnected = false
        }
    }
    
    func startTransmitting() async {
        guard !isTransmitting else { return }
        
        isTransmitting = true
        transcribedText = ""
        
        PTTLogger.info("Started transmitting")
        
        // Start recording and speech recognition
        await speechEngine?.startRecording()
    }
    
    func stopTransmitting() async {
        guard isTransmitting else { return }
        
        isTransmitting = false
        PTTLogger.info("Stopped transmitting")
        
        // Stop recording and get transcribed text
        await speechEngine?.stopRecording()
        
        if let text = speechEngine?.transcribedText, !text.isEmpty {
            transcribedText = text
            PTTLogger.info("Transcribed: \(text)")
            
            // Send to Gateway
            await sendToGateway(text: text)
        }
    }
    
    private func sendToGateway(text: String) async {
        guard let client = gatewayClient else { return }
        
        do {
            let response = try await client.sendMessage(text)
            lastResponse = response
            PTTLogger.info("Received response: \(response)")
            
            // Play response audio
            await audioPlayer?.speak(text: response)
        } catch {
            PTTLogger.error("Failed to send message: \(error)")
            lastResponse = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - PTChannelManagerDelegate

extension PTTManager: PTChannelManagerDelegate {
    nonisolated func channelManager(
        _ channelManager: PTChannelManager,
        didActivate audioSession: AVAudioSession
    ) {
        Task { @MainActor in
            PTTLogger.info("Audio session activated")
            await startTransmitting()
        }
    }
    
    nonisolated func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        Task { @MainActor in
            PTTLogger.info("Audio session deactivated")
            await stopTransmitting()
        }
    }
    
    nonisolated func channelManager(
        _ channelManager: PTChannelManager,
        failedToActivateAudioSessionWithError error: Error
    ) {
        Task { @MainActor in
            PTTLogger.error("Failed to activate audio session: \(error)")
        }
    }
}
