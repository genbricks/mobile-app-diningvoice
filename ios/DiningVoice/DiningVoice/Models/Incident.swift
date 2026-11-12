import Foundation

struct Incident: Codable, Identifiable {
    let id: String
    let incidentNumber: String
    let alertRuleName: String?
    let departmentName: String?
    let sentiment: SentimentType?
    let incidentStatus: String
    let category: String?
    let submissionText: String?
    let resolutionNotes: String?
    let closedAt: String?
    let closedByRewardId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case incidentNumber = "incident_number"
        case alertRuleName = "alert_rule_name"
        case departmentName = "department_name"
        case sentiment
        case incidentStatus = "incident_status"
        case category
        case submissionText = "submission_text"
        case resolutionNotes = "resolution_notes"
        case closedAt = "closed_at"
        case closedByRewardId = "closed_by_reward_id"
        case createdAt = "created_at"
    }

    var isOpen: Bool {
        incidentStatus != "closed"
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else { return createdAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

struct IncidentStats: Codable {
    let openCount: Int
    let closedCount: Int

    enum CodingKeys: String, CodingKey {
        case openCount = "open_count"
        case closedCount = "closed_count"
    }
}

struct CloseIncidentRequest: Codable {
    let resolutionNotes: String

    enum CodingKeys: String, CodingKey {
        case resolutionNotes = "resolution_notes"
    }
}
