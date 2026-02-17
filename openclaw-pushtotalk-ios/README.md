# OpenClaw PTT - iOS Push to Talk App

A native iOS app that uses Apple's PushToTalk framework to enable true "hold-to-talk" voice communication with OpenClaw AI assistant.

## Features

- **True Push-to-Talk**: Hold Action Button to talk, release to send
- **On-device Speech Recognition**: Free, private, real-time transcription
- **Voice Responses**: Audio playback of AI responses
- **Background Operation**: Works from lock screen and Action Button

## Requirements

- iOS 16.0 or later
- iPhone with Action Button (iPhone 15 Pro and later)
- OpenClaw Gateway with Tailscale Funnel

## Setup

### 1. Configure Gateway

On your OpenClaw server:
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Enable Funnel on gateway port
sudo tailscale funnel 18789
```

Note the Funnel URL (e.g., `https://your-machine.tailnet.ts.net`)

### 2. Get Gateway Token

```bash
echo $OPENCLAW_GATEWAY_TOKEN
```

### 3. Build and Install

1. Open `OpenClawPTT.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on your iPhone
4. Configure the Action Button in iOS Settings → Action Button → select OpenClaw PTT

### 4. Configure the App

1. Open the app
2. Go to Settings (gear icon)
3. Enter your Gateway URL and Token
4. Save

## Usage

1. Press and hold the Action Button (or trigger from app)
2. Speak your message
3. Release to send
4. Listen to the response

## Architecture

```
OpenClawPTT/
├── App/
│   ├── OpenClawPTTApp.swift      # App entry point
│   └── ContentView.swift          # Main UI
├── PushToTalk/
│   ├── PTTChannelDelegate.swift   # PTChannelManager delegate
│   ├── PTTTransmitter.swift       # Transmission handling
│   └── AudioRecorder.swift        # Audio capture
├── Speech/
│   ├── SpeechRecognizer.swift     # SFSpeechRecognizer wrapper
│   └── SpeechToTextEngine.swift   # STT processing
├── Networking/
│   ├── GatewayClient.swift        # HTTP client
│   └── Models.swift               # Request/Response models
├── Audio/
│   ├── AudioPlayer.swift          # Audio playback
│   └── TTSEngine.swift            # Text-to-speech
├── Settings/
│   ├── SettingsStore.swift        # Settings persistence
│   ├── SettingsView.swift         # Settings UI
│   └── KeychainManager.swift      # Secure token storage
└── Extensions/
    └── Logger.swift               # Unified logging
```

## Entitlements

The app requires:
- `com.apple.developer.push-to-talk` - PTT framework access
- `aps-environment` - Push notifications (for PTT signaling)
- Microphone and Speech Recognition permissions

## License

MIT License - See LICENSE file for details.

## Links

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Apple PushToTalk Framework](https://developer.apple.com/documentation/pushtotalk)
- [Development Plan](./docs/DEVELOPMENT_PLAN.md)