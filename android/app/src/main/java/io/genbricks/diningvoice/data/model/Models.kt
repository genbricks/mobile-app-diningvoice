package io.genbricks.diningvoice.data.model

import com.google.gson.annotations.SerializedName

data class User(
    val id: String,
    val email: String,
    val username: String,
    @SerializedName("created_at") val createdAt: String,
    val role: String? = null
)

data class AuthResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("token_type") val tokenType: String,
    val user: User
)

data class LoginRequest(
    val email: String,
    val password: String
)

data class RegisterRequest(
    val email: String,
    val username: String,
    val password: String
)

data class Submission(
    val id: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("audio_url") val audioUrl: String,
    val transcription: Any?,
    val sentiment: String,
    @SerializedName("confidence_score") val confidenceScore: Double,
    @SerializedName("urgency_score") val urgencyScore: Double? = null,
    val duration: Double,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("processing_status") val processingStatus: String? = null,
    @SerializedName("reference_number") val referenceNumber: String? = null
) {
    val transcriptionText: String
        get() = when (transcription) {
            is String -> transcription
            is Map<*, *> -> (transcription["text"] as? String) ?: ""
            else -> ""
        }

    val category: String?
        get() = when (transcription) {
            is Map<*, *> -> transcription["dynamic_category"] as? String
            else -> null
        }

    val tone: String?
        get() = when (transcription) {
            is Map<*, *> -> transcription["tone"] as? String
            else -> null
        }

    val language: String?
        get() = when (transcription) {
            is Map<*, *> -> transcription["language"] as? String
            else -> null
        }

    val originalText: String?
        get() = when (transcription) {
            is Map<*, *> -> transcription["original_text"] as? String
            else -> null
        }
}

data class PagedResponse<T>(
    val items: List<T>,
    val total: Int,
    val page: Int,
    @SerializedName("page_size") val pageSize: Int,
    @SerializedName("total_pages") val totalPages: Int
)

data class AnalyticsData(
    @SerializedName("sentiment_stats") val sentimentStats: SentimentStats,
    @SerializedName("total_submissions") val totalSubmissions: Int,
    @SerializedName("average_confidence") val averageConfidence: Double,
    @SerializedName("total_duration") val totalDuration: Double,
    @SerializedName("time_series") val timeSeries: List<TimeSeriesEntry>,
    @SerializedName("department_stats") val departmentStats: List<DepartmentStats>
)

data class SentimentStats(
    val positive: Int,
    val neutral: Int,
    val negative: Int,
    val total: Int
)

data class TimeSeriesEntry(
    val date: String,
    val positive: Int,
    val neutral: Int,
    val negative: Int,
    val total: Int
)

data class DepartmentStats(
    val category: String,
    val complaints: Int,
    val compliments: Int,
    val neutral: Int,
    val total: Int,
    val subcategories: List<SubCategoryStats>
)

data class SubCategoryStats(
    val subcategory: String,
    val complaints: Int,
    val compliments: Int,
    val neutral: Int,
    val total: Int
)

data class Incident(
    val id: String,
    @SerializedName("incident_number") val incidentNumber: String,
    @SerializedName("alert_rule_name") val alertRuleName: String? = null,
    @SerializedName("department_name") val departmentName: String? = null,
    val sentiment: String? = null,
    @SerializedName("incident_status") val incidentStatus: String,
    val category: String? = null,
    @SerializedName("submission_text") val submissionText: String? = null,
    @SerializedName("resolution_notes") val resolutionNotes: String? = null,
    @SerializedName("closed_at") val closedAt: String? = null,
    @SerializedName("created_at") val createdAt: String
) {
    val isOpen: Boolean get() = incidentStatus != "closed"
}

data class IncidentStats(
    @SerializedName("open_count") val openCount: Int,
    @SerializedName("closed_count") val closedCount: Int
)

data class AuthState(
    val user: User? = null,
    val token: String? = null,
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)
