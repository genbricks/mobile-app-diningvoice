package io.genbricks.diningvoice.data.api

import io.genbricks.diningvoice.data.model.*
import okhttp3.MultipartBody
import retrofit2.http.*

interface DiningVoiceApi {

    // Auth
    @POST("auth/login-json")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("auth/send-otp")
    suspend fun sendOtp(@Body body: Map<String, String>): Map<String, String>

    @POST("auth/verify-otp")
    suspend fun verifyOtp(@Body body: Map<String, String>): AuthResponse

    @GET("auth/me")
    suspend fun getMe(): User

    @POST("auth/logout")
    suspend fun logout()

    @POST("auth/forgot-password")
    suspend fun forgotPassword(@Body body: Map<String, String>): Map<String, String>

    // Submissions
    @GET("submissions/")
    suspend fun getSubmissions(
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20,
        @Query("include_transcription") includeTranscription: Boolean = true,
        @Query("category") category: String? = null,
        @Query("status_filter") statusFilter: String? = null
    ): PagedResponse<Submission>

    @Multipart
    @POST("submissions/upload")
    suspend fun uploadAudio(
        @Part file: MultipartBody.Part
    ): Map<String, Any>

    @POST("submissions/text")
    suspend fun submitText(@Body body: Map<String, String>): Submission

    @DELETE("submissions/{id}")
    suspend fun deleteSubmission(@Path("id") id: String)

    // Analytics
    @GET("analytics/")
    suspend fun getAnalytics(
        @Query("category") category: String? = null,
        @Query("start_date") startDate: String? = null,
        @Query("end_date") endDate: String? = null
    ): AnalyticsData

    @GET("analytics/categories")
    suspend fun getCategories(): List<String>

    // Incidents
    @GET("admin/alerts/incidents")
    suspend fun getIncidents(
        @Query("sentiment") sentiment: String? = null,
        @Query("limit") limit: Int = 200
    ): List<Incident>

    @GET("admin/alerts/incident-stats")
    suspend fun getIncidentStats(): IncidentStats

    @POST("admin/alerts/incidents/{id}/close")
    suspend fun closeIncident(
        @Path("id") id: String,
        @Body body: Map<String, String>
    ): Map<String, Any>

    // Public
    @POST("public/customer-feedback")
    suspend fun submitPublicFeedback(@Body body: Map<String, String?>): Map<String, Any?>

    @Multipart
    @POST("public/transcribe")
    suspend fun transcribeAudio(@Part audio: MultipartBody.Part): Map<String, String?>

    @POST("public/proofread")
    suspend fun proofread(@Body body: Map<String, String>): Map<String, String>

    // Health
    @GET("health")
    suspend fun health(): Map<String, Any>
}
