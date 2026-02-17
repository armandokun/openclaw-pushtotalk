import Foundation

// MARK: - Request Models

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let user: String
    
    init(message: String, model: String = "openclaw:main", user: String = "iphone-ptt") {
        self.model = model
        self.messages = [ChatMessage(role: "user", content: message)]
        self.user = user
    }
}

struct ChatMessage: Encodable {
    let role: String
    let content: String
}

// MARK: - Response Models

struct ChatCompletionResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
    let usage: Usage?
}

struct ChatChoice: Decodable {
    let index: Int
    let message: ChatMessageResponse
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct ChatMessageResponse: Decodable {
    let role: String
    let content: String
}

struct Usage: Decodable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Error Models

struct GatewayErrorResponse: Decodable {
    let error: GatewayErrorDetail
}

struct GatewayErrorDetail: Decodable {
    let message: String
    let type: String
    let code: String?
}
