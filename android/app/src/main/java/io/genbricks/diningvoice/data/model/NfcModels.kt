package io.genbricks.diningvoice.data.model

import com.google.gson.annotations.SerializedName

// ---------------------------------------------------- Feature flags

data class ModuleInfo(
    val key: String,
    val label: String,
    val enabled: Boolean
)

data class TenantFeatures(
    val features: Map<String, Boolean>,
    val modules: List<ModuleInfo>
)

// ----------------------------------------- NFC devices

data class NfcDevice(
    @SerializedName("device_id") val deviceId: String,
    @SerializedName("device_uid") val deviceUid: String,
    @SerializedName("device_type") val deviceType: String,
    val label: String,
    @SerializedName("is_active") val isActive: Boolean,
    @SerializedName("registered_at") val registeredAt: String
)

data class NfcDeviceRequest(
    @SerializedName("device_uid") val deviceUid: String,
    @SerializedName("device_type") val deviceType: String = "table_tag",
    val label: String
)

data class NfcDeviceUpdateRequest(
    val label: String? = null,
    @SerializedName("is_active") val isActive: Boolean? = null
)

// ----------------------------------------- Dining tables

data class DiningTable(
    @SerializedName("table_id") val tableId: String,
    @SerializedName("table_number") val tableNumber: String,
    val section: String?,
    @SerializedName("seat_count") val seatCount: Int,
    @SerializedName("nfc_device_id") val nfcDeviceId: String?,
    @SerializedName("is_active") val isActive: Boolean,
    @SerializedName("created_at") val createdAt: String
)

data class DiningTableRequest(
    @SerializedName("table_number") val tableNumber: String,
    val section: String? = null,
    @SerializedName("seat_count") val seatCount: Int = 4,
    @SerializedName("nfc_device_id") val nfcDeviceId: String? = null
)

// ----------------------------------------- Table sessions

data class TableSession(
    @SerializedName("session_id") val sessionId: String,
    @SerializedName("table_id") val tableId: String,
    @SerializedName("assigned_server_id") val assignedServerId: String?,
    @SerializedName("guest_count") val guestCount: Int,
    val status: String,
    @SerializedName("checkin_preference") val checkinPreference: String,
    @SerializedName("order_placed_at") val orderPlacedAt: String?,
    @SerializedName("food_delivered_at") val foodDeliveredAt: String?,
    @SerializedName("next_checkin_due_at") val nextCheckinDueAt: String?,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("closed_at") val closedAt: String?
)

data class TableSessionRequest(
    @SerializedName("table_id") val tableId: String,
    @SerializedName("assigned_server_id") val assignedServerId: String? = null,
    @SerializedName("guest_count") val guestCount: Int = 1,
    @SerializedName("checkin_preference") val checkinPreference: String = "all"
)

data class TableSessionUpdateRequest(
    val status: String? = null,
    @SerializedName("assigned_server_id") val assignedServerId: String? = null,
    @SerializedName("checkin_preference") val checkinPreference: String? = null,
    @SerializedName("guest_count") val guestCount: Int? = null
)

// ----------------------------------------- Server check-ins

data class ServerCheckin(
    @SerializedName("checkin_id") val checkinId: String,
    @SerializedName("table_session_id") val tableSessionId: String,
    @SerializedName("server_member_id") val serverMemberId: String,
    @SerializedName("nfc_device_uid") val nfcDeviceUid: String,
    @SerializedName("was_on_time") val wasOnTime: Boolean,
    @SerializedName("checkin_at") val checkinAt: String,
    val notes: String?
)

data class CheckinRequest(
    @SerializedName("nfc_device_uid") val nfcDeviceUid: String,
    @SerializedName("server_member_id") val serverMemberId: String,
    val notes: String? = null
)

// ----------------------------------------- Overdue alerts

data class OverdueSession(
    @SerializedName("session_id") val sessionId: String,
    @SerializedName("table_id") val tableId: String,
    @SerializedName("table_number") val tableNumber: String,
    @SerializedName("assigned_server_id") val assignedServerId: String?,
    @SerializedName("server_name") val serverName: String?,
    @SerializedName("next_checkin_due_at") val nextCheckinDueAt: String?,
    @SerializedName("minutes_overdue") val minutesOverdue: Int
)

// ----------------------------------------- NFC settings

data class NfcSettings(
    val enabled: Boolean = false,
    @SerializedName("checkin_interval_minutes") val checkinIntervalMinutes: Int = 15,
    @SerializedName("grace_period_minutes") val gracePeriodMinutes: Int = 5,
    @SerializedName("peak_hours") val peakHours: List<PeakHourRange> = emptyList(),
    @SerializedName("alert_on_missed_checkin") val alertOnMissedCheckin: Boolean = true,
    @SerializedName("alert_channels") val alertChannels: List<String> = emptyList()
)

data class PeakHourRange(
    val start: String,
    val end: String
)

data class NfcSettingsUpdateRequest(
    val enabled: Boolean? = null,
    @SerializedName("checkin_interval_minutes") val checkinIntervalMinutes: Int? = null,
    @SerializedName("grace_period_minutes") val gracePeriodMinutes: Int? = null,
    @SerializedName("alert_on_missed_checkin") val alertOnMissedCheckin: Boolean? = null
)
