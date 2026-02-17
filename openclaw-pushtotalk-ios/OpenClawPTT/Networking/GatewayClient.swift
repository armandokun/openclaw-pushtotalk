import Foundation

/// HTTP client for OpenClaw Gateway
class GatewayClient {
    private let session = URLSession.shared
    private var baseURL: URL?
    private var authToken: String?
    
    struct Config {
        var baseURL: String
        var token: String
    }
    
    func configure(with config: Config) {
        self.baseURL = URL(string: config.baseURL)
        self.authToken = config.token
        PTTLogger.info("Gateway configured: \(config.baseURL)")
    }
    
    func sendMessage(_ text: String) async throws -> String {
        guard let url = baseURL?.appendingPathComponent("/v1/chat/completions") else {
            throw GatewayError.invalidURL
        }
        
        guard let token = authToken else {
            throw GatewayError.notConfigured
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build body
        let body: [String: Any] = [
            "model": "openclaw:main",
            "messages": [
                ["role": "user", "content": text]
            ],
            "user": "iphone-ptt"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        PTTLogger.info("Sending to Gateway: \(text)")
        
        // Send request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            PTTLogger.error("Gateway error (\(httpResponse.statusCode)): \(errorBody)")
            throw GatewayError.httpError(httpResponse.statusCode, errorBody)
        }
        
        // Parse response
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw GatewayError.invalidResponse
        }
        
        return content
    }
}

enum GatewayError: LocalizedError {
    case invalidURL
    case notConfigured
    case invalidResponse
    case httpError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Gateway URL"
        case .notConfigured:
            return "Gateway not configured"
        case .invalidResponse:
            return "Invalid response from Gateway"
        case .httpError(let code, let body):
            return "HTTP error \(code): \(body)"
        }
    }
}
