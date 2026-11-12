import Foundation

struct SentimentStats: Codable {
    let positive: Int
    let neutral: Int
    let negative: Int
    let total: Int
}

struct TimeSeriesData: Codable, Identifiable {
    let date: String
    let positive: Int
    let neutral: Int
    let negative: Int
    let total: Int

    var id: String { date }

    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

struct SubCategoryStats: Codable, Identifiable {
    let subcategory: String
    let complaints: Int
    let compliments: Int
    let neutral: Int
    let total: Int

    var id: String { subcategory }
}

struct DepartmentStats: Codable, Identifiable {
    let category: String
    let complaints: Int
    let compliments: Int
    let neutral: Int
    let total: Int
    let subcategories: [SubCategoryStats]

    var id: String { category }
}

struct AnalyticsData: Codable {
    let sentimentStats: SentimentStats
    let totalSubmissions: Int
    let averageConfidence: Double
    let totalDuration: Double
    let timeSeries: [TimeSeriesData]
    let departmentStats: [DepartmentStats]

    enum CodingKeys: String, CodingKey {
        case sentimentStats = "sentiment_stats"
        case totalSubmissions = "total_submissions"
        case averageConfidence = "average_confidence"
        case totalDuration = "total_duration"
        case timeSeries = "time_series"
        case departmentStats = "department_stats"
    }
}
