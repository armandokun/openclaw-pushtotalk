# Push to Talk iOS App - Development Plan

**Created:** 2026-02-17
**Status:** Analysis Complete, Ready for Development
**Repo:** https://github.com/armandokun/openclaw-pushtotalk

---

## Executive Summary

Building a native iOS app that uses Apple's PushToTalk framework to enable true "hold-to-talk" voice communication with OpenClaw. The app will connect to the OpenClaw Gateway via HTTP API, sending transcribed voice and receiving responses (text or audio).

---

## Technical Findings

### 1. Apple PushToTalk Framework

**Requirements:**
- **iOS 16.0+** minimum deployment target
- **Special entitlements required:**
  - `com.apple.developer.push-to-talk` 
  - `unrestricted.voip-ptt` (for background PTT)
- **Background modes:** Voice over IP (VoIP) background mode
- **Framework:** `PushToTalk` (native Apple framework since iOS 16)

**Key Components:**
- `PTChannelManager` - Main manager for PTT channels
- `PTTManager` - Handles transmit/receive state
- System UI overlay shows when PTT is active
- Works from Action Button, lock screen, and app

**Capabilities:**
- Hold to talk, release to send
- Background operation (when app in background)
- System UI shows PTT state
- Audio session management built-in

### 2. OpenClaw Gateway API

**Current Status:**
- Gateway running on port `18789`
- Bind: `loopback` (localhost only)
- Auth: Token-based (`gateway.auth.mode: "token"`)

**Available Endpoints:**

| Endpoint | Status | Purpose |
|----------|--------|---------|
| `/v1/chat/completions` | DISABLED | OpenAI-compatible chat API |
| `/tools/invoke` | ENABLED | Direct tool invocation |
| WebSocket (WS) | ENABLED | Full gateway protocol |

**Required Configuration Changes:**
1. Enable HTTP endpoints:
   ```json5
   gateway: {
     http: {
       endpoints: {
         chatCompletions: { enabled: true }
       }
     }
   }
   ```

2. Expose gateway publicly (options):
   - **Tailscale Funnel** (recommended): `gateway.tailscale.mode: "funnel"`
   - **Reverse proxy** (nginx/Caddy) with TLS
   - **LAN bind**: `gateway.bind: "lan"` (less secure)

### 3. Voice Pipeline

**Speech-to-Text (STT):**
- OpenClaw does NOT have built-in STT API
- Options for the app:
  1. **On-device STT** (iOS Speech framework) - FREE, private
  2. **OpenAI Whisper API** - $0.006/minute, high quality
  3. **Groq Whisper** - Fast, cheap

**Text-to-Speech (TTS):**
- OpenClaw HAS built-in TTS:
  - ElevenLabs (configured with voice ID `3dQb5lTwxTXMP8oxoRWG`)
  - OpenAI TTS
  - Edge TTS (free fallback)
- Can request audio response via API

**Recommended Pipeline:**
```
[Hold Button] → iOS Speech (STT) → Text → Gateway API → Response (text + optional audio)
```

### 4. Auth/Security

**App → Gateway Authentication:**
- Bearer token in `Authorization` header
- Token from `gateway.auth.token` (or `OPENCLAW_GATEWAY_TOKEN`)
- Store securely in iOS Keychain

**Security Considerations:**
- Gateway should use TLS in production (Tailscale Funnel or reverse proxy)
- Token should be provisioned securely (not hardcoded)
- Consider app-specific token with limited scopes

---

## API Contract Design

### Request Format (App → Gateway)

**Option A: OpenAI-compatible endpoint** (RECOMMENDED)
```http
POST https://<gateway-host>/v1/chat/completions
Authorization: Bearer <token>
Content-Type: application/json

{
  "model": "openclaw:main",
  "messages": [
    {"role": "user", "content": "What's the weather today?"}
  ],
  "user": "iphone-ptt"
}
```

**Response:**
```json
{
  "id": "chatcmpl-...",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "The weather today is..."
    }
  }]
}
```

**Option B: Tools invoke** (for specific actions)
```http
POST https://<gateway-host>/tools/invoke
Authorization: Bearer <token>
Content-Type: application/json

{
  "tool": "sessions_send",
  "args": {
    "message": "What's the weather?"
  }
}
```

### Audio Response

To get audio response, the app can:
1. Request TTS from OpenClaw (if using tools invoke)
2. Use iOS AVSpeechSynthesizer for local TTS
3. Make two calls: chat → TTS endpoint

**Recommended:** Use OpenClaw's TTS for consistent voice (ElevenLabs configured).

---

## iOS App Architecture

```
openclaw-pushtotalk/
├── App/
│   ├── OpenClawPTTApp.swift          # App entry point
│   └── ContentView.swift              # Main UI (settings)
├── PushToTalk/
│   ├── PTTChannelDelegate.swift       # PTChannelManager delegate
│   ├── PTTTransmitter.swift           # Handle transmit events
│   └── AudioRecorder.swift            # AVAudioRecorder wrapper
├── Speech/
│   ├── SpeechRecognizer.swift         # SFSpeechRecognizer wrapper
│   └── SpeechToTextEngine.swift       # STT processing
├── Networking/
│   ├── GatewayClient.swift            # HTTP client for Gateway
│   ├── Models.swift                   # Request/Response models
│   └── Endpoints.swift                # API endpoints
├── Audio/
│   ├── AudioPlayer.swift              # AVAudioPlayer wrapper
│   └── TTSEngine.swift                # TTS playback
├── Settings/
│   ├── SettingsView.swift             # Gateway URL, token config
│   └── KeychainManager.swift          # Secure token storage
└── Extensions/
    ├── Logger.swift                   # Unified logging
    └── Extensions.swift               # Helper extensions
```

### Key Implementation Details

1. **PTTManager Setup:**
   ```swift
   import PushToTalk
   
   class PTTManager: ObservableObject {
       var channelManager: PTChannelManager?
       
       func setup() async throws {
           channelManager = try await PTChannelManager.channelManager(
               delegate: self,
               restorationDelegate: self
           )
       }
   }
   ```

2. **On Transmit Start:**
   - Start audio recording
   - Begin real-time STT (optional) or record full clip

3. **On Transmit End:**
   - Stop recording
   - Transcribe audio (iOS Speech or Whisper API)
   - Send text to Gateway
   - Receive response
   - Play audio or speak text

4. **Background Handling:**
   - PushToTalk framework handles background activation
   - App must handle audio session activation/deactivation

---

## OpenClaw Gateway Changes Required

### 1. Enable HTTP Endpoints

```json5
{
  gateway: {
    http: {
      endpoints: {
        chatCompletions: { enabled: true }
      }
    }
  }
}
```

### 2. Expose Gateway

**Option A: Tailscale Funnel** (RECOMMENDED for personal use)
```json5
{
  gateway: {
    tailscale: {
      mode: "funnel"
    }
  }
}
```

**Option B: Custom Domain + Reverse Proxy**
- Set up nginx/Caddy with TLS
- Point to `http://127.0.0.1:18789`
- Use Let's Encrypt for TLS

### 3. Create App-Specific Token (Optional)

For better security, create a dedicated token for the PTT app with limited scope.

---

## Development Phases

### Phase 1: Foundation (2-3 days)
- [ ] Create Xcode project structure
- [ ] Implement PushToTalk framework integration
- [ ] Set up PTChannelManager and delegates
- [ ] Test PTT UI appears on Action Button press
- [ ] Configure iOS entitlements and background modes

### Phase 2: Speech Recognition (1-2 days)
- [ ] Implement iOS Speech framework integration
- [ ] Handle speech authorization
- [ ] Create SpeechRecognizer class
- [ ] Test real-time transcription

### Phase 3: Gateway Integration (2-3 days)
- [ ] Create GatewayClient HTTP client
- [ ] Implement token auth with Keychain storage
- [ ] Build request/response models
- [ ] Enable Gateway HTTP endpoint
- [ ] Test end-to-end: PTT → STT → Gateway → Response

### Phase 4: Audio Playback (1-2 days)
- [ ] Implement AudioPlayer for response audio
- [ ] Add TTS fallback for text responses
- [ ] Handle audio session management
- [ ] Test audio interruption handling

### Phase 5: Settings & Polish (1-2 days)
- [ ] Build settings UI (Gateway URL, token)
- [ ] Add connection status indicator
- [ ] Implement error handling and retries
- [ ] Add haptic feedback for PTT events

### Phase 6: Production Ready (1-2 days)
- [ ] Set up Tailscale Funnel or reverse proxy
- [ ] Configure production Gateway URL
- [ ] Test on physical device
- [ ] Write user documentation
- [ ] Submit to TestFlight (optional)

**Estimated Total:** 8-14 days

---

## Dependencies

### iOS Frameworks (System)
- `PushToTalk` - PTT functionality
- `Speech` - Speech recognition
- `AVFAudio` - Audio playback
- `Security` - Keychain storage

### Third-Party (Optional)
- `Alamofire` - HTTP networking (or use URLSession)
- No other dependencies needed

### External Services
- OpenClaw Gateway (existing)
- Optional: OpenAI Whisper API (for better STT)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gateway not accessible from iPhone | BLOCKER | Use Tailscale Funnel or reverse proxy with TLS |
| iOS Speech recognition accuracy poor | MEDIUM | Add Whisper API fallback |
| PushToTalk entitlement rejected | BLOCKER | Use standard Apple developer account, entitlement is documented |
| Background PTT not working | MEDIUM | Proper VoIP background mode configuration |
| Audio session conflicts | MEDIUM | Careful audio session category management |

---

## Next Steps

1. **Configure Gateway** - Enable HTTP endpoint and expose publicly
2. **Set up Xcode project** - Create app with proper entitlements
3. **Implement PTT** - Get basic PushToTalk working
4. **Add STT** - Integrate iOS Speech framework
5. **Connect to Gateway** - Test full pipeline

---

## Questions for User

Before proceeding to development:

1. **Gateway exposure:** Do you want to use Tailscale Funnel, or do you have a domain/reverse proxy setup?
2. **STT preference:** Use free iOS on-device Speech, or integrate Whisper API ($0.006/min)?
3. **Response format:** Text only, audio response, or both?
4. **Distribution:** Personal TestFlight, or App Store release?

---

*Plan created by GAIA - OpenClaw AI Assistant*