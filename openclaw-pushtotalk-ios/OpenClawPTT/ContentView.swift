import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var pttManager: PTTManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection Status
                HStack {
                    Circle()
                        .fill(pttManager.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(pttManager.isConnected ? "Connected" : "Not Connected")
                        .font(.subheadline)
                }
                
                // PTT Status
                if pttManager.isTransmitting {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Listening...")
                            .font(.headline)
                        
                        // Transcribed text preview
                        if !pttManager.transcribedText.isEmpty {
                            Text(pttManager.transcribedText)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Response Area
                if !pttManager.lastResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(pttManager.lastResponse)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Settings Prompt
                if !settings.isConfigured {
                    VStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        Text("Configure Gateway")
                            .font(.headline)
                        Text("Enter your Gateway URL and token in Settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("OpenClaw PTT")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await pttManager.setup()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(PTTManager())
}
