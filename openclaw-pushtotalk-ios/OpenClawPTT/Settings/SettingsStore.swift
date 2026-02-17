import Foundation
import Combine

/// Stores and retrieves settings for the app
class SettingsStore: ObservableObject {
    @Published var gatewayURL: String = "" {
        didSet { saveSettings() }
    }
    
    @Published var gatewayToken: String = "" {
        didSet { saveSettings() }
    }
    
    @Published var autoSpeak: Bool = true {
        didSet { saveSettings() }
    }
    
    var isConfigured: Bool {
        !gatewayURL.isEmpty && !gatewayToken.isEmpty
    }
    
    private let defaults = UserDefaults.standard
    private let keychain = KeychainManager()
    
    private enum Keys {
        static let gatewayURL = "gatewayURL"
        static let autoSpeak = "autoSpeak"
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load URL from UserDefaults
        gatewayURL = defaults.string(forKey: Keys.gatewayURL) ?? ""
        autoSpeak = defaults.bool(forKey: Keys.autoSpeak)
        
        // Load token from Keychain (more secure)
        if let token = keychain.getToken() {
            gatewayToken = token
        }
    }
    
    private func saveSettings() {
        // Save URL to UserDefaults
        defaults.set(gatewayURL, forKey: Keys.gatewayURL)
        defaults.set(autoSpeak, forKey: Keys.autoSpeak)
        
        // Save token to Keychain
        if !gatewayToken.isEmpty {
            keychain.saveToken(gatewayToken)
        }
    }
    
    func clearSettings() {
        gatewayURL = ""
        gatewayToken = ""
        defaults.removeObject(forKey: Keys.gatewayURL)
        defaults.removeObject(forKey: Keys.autoSpeak)
        keychain.deleteToken()
    }
}
