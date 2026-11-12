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

    // Features
    @GET("features")
    suspend fun getFeatures(): io.genbricks.diningvoice.data.model.TenantFeatures

    // NFC Monitoring
    @GET("nfc/devices")
    suspend fun getNfcDevices(): List<io.genbricks.diningvoice.data.model.NfcDevice>

    @POST("nfc/devices")
    suspend fun registerNfcDevice(@Body body: io.genbricks.diningvoice.data.model.NfcDeviceRequest): io.genbricks.diningvoice.data.model.NfcDevice

    @PATCH("nfc/devices/{id}")
    suspend fun updateNfcDevice(@Path("id") id: String, @Body body: Map<String, Any?>): io.genbricks.diningvoice.data.model.NfcDevice

    @GET("nfc/tables")
    suspend fun getNfcTables(): List<io.genbricks.diningvoice.data.model.DiningTable>

    @POST("nfc/tables")
    suspend fun createNfcTable(@Body body: io.genbricks.diningvoice.data.model.DiningTableRequest): io.genbricks.diningvoice.data.model.DiningTable

    @PATCH("nfc/tables/{id}")
    suspend fun updateNfcTable(@Path("id") id: String, @Body body: Map<String, Any?>): io.genbricks.diningvoice.data.model.DiningTable

    @GET("nfc/sessions")
    suspend fun getNfcSessions(@Query("active_only") activeOnly: Boolean = true): List<io.genbricks.diningvoice.data.model.TableSession>

    @POST("nfc/sessions")
    suspend fun openNfcSession(@Body body: io.genbricks.diningvoice.data.model.TableSessionRequest): io.genbricks.diningvoice.data.model.TableSession

    @PATCH("nfc/sessions/{id}")
    suspend fun updateNfcSession(@Path("id") id: String, @Body body: io.genbricks.diningvoice.data.model.TableSessionUpdateRequest): io.genbricks.diningvoice.data.model.TableSession

    @POST("nfc/checkin")
    suspend fun nfcCheckin(@Body body: io.genbricks.diningvoice.data.model.CheckinRequest): io.genbricks.diningvoice.data.model.ServerCheckin

    @GET("nfc/sessions/{id}/checkins")
    suspend fun getSessionCheckins(@Path("id") id: String): List<io.genbricks.diningvoice.data.model.ServerCheckin>

    @GET("nfc/overdue")
    suspend fun getOverdueSessions(): List<io.genbricks.diningvoice.data.model.OverdueSession>

    @GET("nfc/settings")
    suspend fun getNfcSettings(): io.genbricks.diningvoice.data.model.NfcSettings

    @PUT("nfc/settings")
    suspend fun updateNfcSettings(@Body body: io.genbricks.diningvoice.data.model.NfcSettingsUpdateRequest): io.genbricks.diningvoice.data.model.NfcSettings

    // Health
    @GET("health")
    suspend fun health(): Map<String, Any>
}
