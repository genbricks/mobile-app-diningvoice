import Foundation

@MainActor
class NfcMonitoringViewModel: ObservableObject {
    @Published var devices: [NfcDevice] = []
    @Published var tables: [DiningTable] = []
    @Published var sessions: [TableSession] = []
    @Published var overdueAlerts: [OverdueSession] = []
    @Published var checkins: [ServerCheckin] = []
    @Published var nfcSettings: NfcSettings?
    @Published var features: TenantFeatures?
    @Published var isLoading = false
    @Published var error: String?

    private let network = NetworkService.shared

    var nfcEnabled: Bool {
        features?.features["nfc_monitoring"] ?? false
    }

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        error = nil
        async let d: () = loadDevices()
        async let t: () = loadTables()
        async let s: () = loadSessions()
        async let o: () = loadOverdueAlerts()
        async let st: () = loadNfcSettings()
        _ = await (d, t, s, o, st)
        isLoading = false
    }

    func loadDevices() async {
        do {
            devices = try await network.request("GET", path: "/nfc/devices")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadTables() async {
        do {
            tables = try await network.request("GET", path: "/nfc/tables")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadSessions() async {
        do {
            sessions = try await network.request(
                "GET", path: "/nfc/sessions",
                queryItems: [URLQueryItem(name: "active_only", value: "true")]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadOverdueAlerts() async {
        do {
            overdueAlerts = try await network.request("GET", path: "/nfc/overdue")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadCheckins(sessionId: UUID) async {
        do {
            checkins = try await network.request(
                "GET", path: "/nfc/sessions/\(sessionId.uuidString)/checkins"
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadNfcSettings() async {
        do {
            nfcSettings = try await network.request("GET", path: "/nfc/settings")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadFeatures() async {
        do {
            features = try await network.request("GET", path: "/features")
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Devices

    func registerDevice(uid: String, type: DeviceType, label: String) async {
        do {
            let request = NfcDeviceRequest(
                deviceUid: uid, deviceType: type.rawValue, label: label
            )
            let _: NfcDevice = try await network.request(
                "POST", path: "/nfc/devices", body: request
            )
            await loadDevices()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleDevice(deviceId: UUID, isActive: Bool) async {
        struct Update: Encodable { let is_active: Bool }
        do {
            let _: NfcDevice = try await network.request(
                "PATCH", path: "/nfc/devices/\(deviceId.uuidString)",
                body: Update(is_active: isActive)
            )
            await loadDevices()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Tables

    func createTable(number: String, section: String?, seatCount: Int, nfcDeviceId: UUID?) async {
        do {
            let request = DiningTableRequest(
                tableNumber: number, section: section, seatCount: seatCount,
                nfcDeviceId: nfcDeviceId
            )
            let _: DiningTable = try await network.request(
                "POST", path: "/nfc/tables", body: request
            )
            await loadTables()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sessions

    func openSession(tableId: UUID, serverId: UUID?, guestCount: Int, preference: CheckinPreference) async {
        do {
            let request = TableSessionRequest(
                tableId: tableId, assignedServerId: serverId,
                guestCount: guestCount, checkinPreference: preference.rawValue
            )
            let _: TableSession = try await network.request(
                "POST", path: "/nfc/sessions", body: request
            )
            await loadSessions()
            await loadOverdueAlerts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateSessionStatus(sessionId: UUID, status: TableSessionStatus) async {
        do {
            let request = TableSessionUpdateRequest(
                status: status.rawValue, assignedServerId: nil,
                checkinPreference: nil, guestCount: nil
            )
            let _: TableSession = try await network.request(
                "PATCH", path: "/nfc/sessions/\(sessionId.uuidString)", body: request
            )
            await loadSessions()
            await loadOverdueAlerts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Check-ins

    func recordCheckin(nfcDeviceUid: String, serverMemberId: UUID, notes: String?) async {
        do {
            let request = CheckinRequest(
                nfcDeviceUid: nfcDeviceUid, serverMemberId: serverMemberId,
                notes: notes
            )
            let _: ServerCheckin = try await network.request(
                "POST", path: "/nfc/checkin", body: request
            )
            await loadSessions()
            await loadOverdueAlerts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Settings

    func updateNfcSettings(_ update: NfcSettingsUpdate) async {
        do {
            nfcSettings = try await network.request(
                "PUT", path: "/nfc/settings", body: update
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() {
        error = nil
    }

    // MARK: - Helpers

    func tableName(for tableId: UUID) -> String {
        tables.first(where: { $0.tableId == tableId })?.tableNumber ?? "—"
    }

    func deviceLabel(for deviceId: UUID?) -> String? {
        guard let deviceId else { return nil }
        return devices.first(where: { $0.deviceId == deviceId })?.label
    }
}
