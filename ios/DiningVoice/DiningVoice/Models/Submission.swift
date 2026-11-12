import Foundation

enum SentimentType: String, Codable, CaseIterable {
    case positive
    case neutral
    case negative
    case mixed

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .positive: return "face.smiling.fill"
        case .neutral: return "face.dashed"
        case .negative: return "exclamationmark.triangle.fill"
        case .mixed: return "arrow.triangle.2.circlepath"
        }
    }
}

enum ProcessingStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

struct TranscriptionData: Codable {
    let text: String
    let originalText: String?
    let englishText: String?
    let tone: String?
    let dynamicCategory: String?
    let language: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case text
        case originalText = "original_text"
        case englishText = "english_text"
        case tone
        case dynamicCategory = "dynamic_category"
        case language
        case confidence
    }
}

struct Submission: Codable, Identifiable {
    let id: String
    let userId: String
    let audioUrl: String
    let transcription: TranscriptionWrapper
    let sentiment: SentimentType
    let confidenceScore: Double
    let urgencyScore: Double?
    let duration: Double
    let createdAt: String
    let metadata: [String: AnyCodable]?
    let processingStatus: ProcessingStatus?
    let referenceNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case audioUrl = "audio_url"
        case transcription
        case sentiment
        case confidenceScore = "confidence_score"
        case urgencyScore = "urgency_score"
        case duration
        case createdAt = "created_at"
        case metadata
        case processingStatus = "processing_status"
        case referenceNumber = "reference_number"
    }

    var transcriptionText: String {
        switch transcription {
        case .text(let str): return str
        case .data(let data): return data.text
        }
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else {
            return createdAt
        }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum TranscriptionWrapper: Codable {
    case text(String)
    case data(TranscriptionData)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .text(str)
        } else if let data = try? container.decode(TranscriptionData.self) {
            self = .data(data)
        } else {
            self = .text("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let str):
            try container.encode(str)
        case .data(let data):
            try container.encode(data)
        }
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String {
            try container.encode(str)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
}
