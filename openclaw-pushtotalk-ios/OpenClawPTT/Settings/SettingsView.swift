import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss
    
    @State private var editingURL: String = ""
    @State private var editingToken: String = ""
    @State private var showSaveConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("Gateway Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gateway URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("https://your-gateway.ts.net", text: $editingURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Auth Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Enter your token", text: $editingToken)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            
            Section(header: Text("Response Settings")) {
                Toggle("Auto-speak responses", isOn: $settings.autoSpeak)
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(editingURL.isEmpty || editingToken.isEmpty)
                
                Button(role: .destructive, action: clearSettings) {
                    HStack {
                        Spacer()
                        Text("Clear All Settings")
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Setup Instructions")) {
                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(number: 1, text: "Run Tailscale Funnel on your Gateway server")
                    instructionRow(number: 2, text: "Copy the Funnel URL (e.g., https://your-machine.tailnet.ts.net)")
                    instructionRow(number: 3, text: "Get your Gateway token from OPENCLAW_GATEWAY_TOKEN env var")
                    instructionRow(number: 4, text: "Configure the Action Button in iOS Settings → Action Button → OpenClaw PTT")
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("OpenClaw Documentation", destination: URL(string: "https://docs.openclaw.ai")!)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            editingURL = settings.gatewayURL
            editingToken = settings.gatewayToken
        }
        .alert("Settings Saved", isPresented: $showSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your Gateway configuration has been saved.")
        }
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
        }
    }
    
    private func saveSettings() {
        settings.gatewayURL = editingURL.trimmingCharacters(in: .whitespaces)
        settings.gatewayToken = editingToken.trimmingCharacters(in: .whitespaces)
        showSaveConfirmation = true
    }
    
    private func clearSettings() {
        settings.clearSettings()
        editingURL = ""
        editingToken = ""
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(SettingsStore())
    }
}
