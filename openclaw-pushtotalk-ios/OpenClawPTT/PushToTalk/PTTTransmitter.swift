import Foundation
import PushToTalk

/// Handles PTT transmission events and state
class PTTTransmitter {
    private weak var channelManager: PTChannelManager?
    private let channelUUID: UUID
    
    init(channelManager: PTChannelManager, channelUUID: UUID) {
        self.channelManager = channelManager
        self.channelUUID = channelUUID
    }
    
    /// Request to start transmitting
    func beginTransmitting() async throws {
        guard let manager = channelManager else {
            throw PTTError.channelNotAvailable
        }
        
        try await manager.requestBeginTransmitting(channelUUID: channelUUID)
    }
    
    /// Stop transmitting
    func endTransmitting() async throws {
        guard let manager = channelManager else {
            throw PTTError.channelNotAvailable
        }
        
        await manager.stopTransmitting()
    }
    
    /// Join the PTT channel
    func joinChannel() async throws {
        guard let manager = channelManager else {
            throw PTTError.channelNotAvailable
        }
        
        // Create channel descriptor
        let descriptor = PTChannelDescriptor(
            name: "OpenClaw",
            channelUUID: channelUUID
        )
        
        try await manager.joinChannel(descriptor: descriptor)
    }
    
    /// Leave the PTT channel
    func leaveChannel() async throws {
        guard let manager = channelManager else {
            throw PTTError.channelNotAvailable
        }
        
        await manager.leaveChannel(channelUUID: channelUUID)
    }
}

enum PTTError: LocalizedError {
    case channelNotAvailable
    case transmissionFailed
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .channelNotAvailable:
            return "PTT channel is not available"
        case .transmissionFailed:
            return "Failed to start transmission"
        case .notAuthorized:
            return "Not authorized for push-to-talk"
        }
    }
}
