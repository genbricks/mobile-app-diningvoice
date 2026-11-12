import Foundation

// MARK: - Enums

enum DeviceType: String, Codable, CaseIterable {
    case tableTag = "table_tag"
    case serverBadge = "server_badge"

    var displayName: String {
        switch self {
        case .tableTag: return "Table Tag"
        case .serverBadge: return "Server Badge"
        }
    }
}

enum TableSessionStatus: String, Codable, CaseIterable {
    case seated
    case orderPlaced = "order_placed"
    case foodDelivered = "food_delivered"
    case closed

    var displayName: String {
        switch self {
        case .seated: return "Seated"
        case .orderPlaced: return "Order Placed"
        case .foodDelivered: return "Food Delivered"
        case .closed: return "Closed"
        }
    }
}

enum CheckinPreference: String, Codable, CaseIterable {
    case all
    case peakOnly = "peak_only"
    case declined

    var displayName: String {
        switch self {
        case .all: return "All Check-ins"
        case .peakOnly: return "Peak Hours Only"
        case .declined: return "Declined"
        }
    }
}

// MARK: - Response Models

struct NfcDevice: Codable, Identifiable {
    let deviceId: UUID
    let deviceUid: String
    let deviceType: String
    let label: String
    let isActive: Bool
    let registeredAt: String

    var id: UUID { deviceId }

    var type: DeviceType {
        DeviceType(rawValue: deviceType) ?? .tableTag
    }

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceUid = "device_uid"
        case deviceType = "device_type"
        case label
        case isActive = "is_active"
        case registeredAt = "registered_at"
    }
}

struct DiningTable: Codable, Identifiable {
    let tableId: UUID
    let tableNumber: String
    let section: String?
    let seatCount: Int
    let nfcDeviceId: UUID?
    let isActive: Bool
    let createdAt: String

    var id: UUID { tableId }

    enum CodingKeys: String, CodingKey {
        case tableId = "table_id"
        case tableNumber = "table_number"
        case section
        case seatCount = "seat_count"
        case nfcDeviceId = "nfc_device_id"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct TableSession: Codable, Identifiable {
    let sessionId: UUID
    let tableId: UUID
    let assignedServerId: UUID?
    let guestCount: Int
    let status: String
    let checkinPreference: String
    let orderPlacedAt: String?
    let foodDeliveredAt: String?
    let nextCheckinDueAt: String?
    let createdAt: String
    let closedAt: String?

    var id: UUID { sessionId }

    var sessionStatus: TableSessionStatus {
        TableSessionStatus(rawValue: status) ?? .seated
    }

    var preference: CheckinPreference {
        CheckinPreference(rawValue: checkinPreference) ?? .all
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case tableId = "table_id"
        case assignedServerId = "assigned_server_id"
        case guestCount = "guest_count"
        case status
        case checkinPreference = "checkin_preference"
        case orderPlacedAt = "order_placed_at"
        case foodDeliveredAt = "food_delivered_at"
        case nextCheckinDueAt = "next_checkin_due_at"
        case createdAt = "created_at"
        case closedAt = "closed_at"
    }
}

struct ServerCheckin: Codable, Identifiable {
    let checkinId: UUID
    let tableSessionId: UUID
    let serverMemberId: UUID
    let nfcDeviceUid: String
    let wasOnTime: Bool
    let checkinAt: String
    let notes: String?

    var id: UUID { checkinId }

    enum CodingKeys: String, CodingKey {
        case checkinId = "checkin_id"
        case tableSessionId = "table_session_id"
        case serverMemberId = "server_member_id"
        case nfcDeviceUid = "nfc_device_uid"
        case wasOnTime = "was_on_time"
        case checkinAt = "checkin_at"
        case notes
    }
}

struct OverdueSession: Codable, Identifiable {
    let sessionId: UUID
    let tableId: UUID
    let tableNumber: String
    let assignedServerId: UUID?
    let serverName: String?
    let nextCheckinDueAt: String?
    let minutesOverdue: Int

    var id: UUID { sessionId }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case tableId = "table_id"
        case tableNumber = "table_number"
        case assignedServerId = "assigned_server_id"
        case serverName = "server_name"
        case nextCheckinDueAt = "next_checkin_due_at"
        case minutesOverdue = "minutes_overdue"
    }
}

struct PeakHourRange: Codable {
    let start: String
    let end: String
}

struct NfcSettings: Codable {
    let enabled: Bool
    let checkinIntervalMinutes: Int
    let gracePeriodMinutes: Int
    let peakHours: [PeakHourRange]
    let alertOnMissedCheckin: Bool
    let alertChannels: [String]

    enum CodingKeys: String, CodingKey {
        case enabled
        case checkinIntervalMinutes = "checkin_interval_minutes"
        case gracePeriodMinutes = "grace_period_minutes"
        case peakHours = "peak_hours"
        case alertOnMissedCheckin = "alert_on_missed_checkin"
        case alertChannels = "alert_channels"
    }
}

struct ModuleInfo: Codable, Identifiable {
    let key: String
    let label: String
    let enabled: Bool

    var id: String { key }
}

struct TenantFeatures: Codable {
    let features: [String: Bool]
    let modules: [ModuleInfo]
}

// MARK: - Request Models

struct NfcDeviceRequest: Encodable {
    let deviceUid: String
    let deviceType: String
    let label: String

    enum CodingKeys: String, CodingKey {
        case deviceUid = "device_uid"
        case deviceType = "device_type"
        case label
    }
}

struct DiningTableRequest: Encodable {
    let tableNumber: String
    let section: String?
    let seatCount: Int
    let nfcDeviceId: UUID?

    enum CodingKeys: String, CodingKey {
        case tableNumber = "table_number"
        case section
        case seatCount = "seat_count"
        case nfcDeviceId = "nfc_device_id"
    }
}

struct TableSessionRequest: Encodable {
    let tableId: UUID
    let assignedServerId: UUID?
    let guestCount: Int
    let checkinPreference: String

    enum CodingKeys: String, CodingKey {
        case tableId = "table_id"
        case assignedServerId = "assigned_server_id"
        case guestCount = "guest_count"
        case checkinPreference = "checkin_preference"
    }
}

struct TableSessionUpdateRequest: Encodable {
    let status: String?
    let assignedServerId: UUID?
    let checkinPreference: String?
    let guestCount: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case assignedServerId = "assigned_server_id"
        case checkinPreference = "checkin_preference"
        case guestCount = "guest_count"
    }
}

struct CheckinRequest: Encodable {
    let nfcDeviceUid: String
    let serverMemberId: UUID
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case nfcDeviceUid = "nfc_device_uid"
        case serverMemberId = "server_member_id"
        case notes
    }
}

struct NfcSettingsUpdate: Encodable {
    var enabled: Bool?
    var checkinIntervalMinutes: Int?
    var gracePeriodMinutes: Int?
    var peakHours: [PeakHourRange]?
    var alertOnMissedCheckin: Bool?
    var alertChannels: [String]?

    enum CodingKeys: String, CodingKey {
        case enabled
        case checkinIntervalMinutes = "checkin_interval_minutes"
        case gracePeriodMinutes = "grace_period_minutes"
        case peakHours = "peak_hours"
        case alertOnMissedCheckin = "alert_on_missed_checkin"
        case alertChannels = "alert_channels"
    }
}
