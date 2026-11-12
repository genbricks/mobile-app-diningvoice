import Foundation

struct PublicFeedbackRequest: Codable {
    let text: String
    let language: String?
    let source: String
}

struct PublicFeedbackResponse: Codable {
    let message: String
    let feedbackId: String?
    let referenceNumber: String?
    let sentiment: SentimentType?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case message
        case feedbackId = "feedback_id"
        case referenceNumber = "reference_number"
        case sentiment
        case category
    }
}

struct FeedbackConfirmation: Codable {
    let sent: Bool
    let message: String?
}
