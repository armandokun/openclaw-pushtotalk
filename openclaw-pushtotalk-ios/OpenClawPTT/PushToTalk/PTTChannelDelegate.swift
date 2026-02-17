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
    @Published var lastError: String?
    
    private var speechEngine: SpeechToTextEngine?
    private var gatewayClient: GatewayClient?
    private var audioPlayer: AudioPlayer?
    
    private let channelUUID = UUID()
    
    // Reference to settings (injected from app)
    weak var settings: SettingsStore?
    
    func setup() async {
        do {
            // Initialize components
            speechEngine = SpeechToTextEngine()
            gatewayClient = GatewayClient()
            audioPlayer = AudioPlayer()
            
            // Configure gateway client with settings
            if let settings = settings, settings.isConfigured {
                gatewayClient?.configure(with: .init(baseURL: settings.gatewayURL, token: settings.gatewayToken))
            }
            
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
            lastError = "Setup failed: \(error.localizedDescription)"
        }
    }
    
    /// Update gateway configuration when settings change
    func updateGatewayConfig(url: String, token: String) {
        gatewayClient?.configure(with: .init(baseURL: url, token: token))
        PTTLogger.info("Gateway config updated")
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
        if let text = await speechEngine?.stopRecording(), !text.isEmpty {
            transcribedText = text
            PTTLogger.info("Transcribed: \(text)")
            
            // Send to Gateway
            await sendToGateway(text: text)
        } else {
            PTTLogger.warning("No transcription available")
            lastError = "No speech detected"
        }
    }
    
    private func sendToGateway(text: String) async {
        guard let client = gatewayClient else {
            lastError = "Gateway not configured"
            return
        }
        
        // Clear previous error
        lastError = nil
        
        do {
            let response = try await client.sendMessage(text)
            lastResponse = response
            PTTLogger.info("Received response: \(response)")
            
            // Speak response if auto-speak is enabled
            if settings?.autoSpeak == true {
                await audioPlayer?.speak(text: response)
            }
        } catch {
            PTTLogger.error("Failed to send message: \(error)")
            lastError = error.localizedDescription
            lastResponse = ""
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
