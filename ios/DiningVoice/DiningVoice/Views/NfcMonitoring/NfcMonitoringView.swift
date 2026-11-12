import SwiftUI

enum NfcTab: String, CaseIterable {
    case sessions = "Sessions"
    case devices = "Devices"
    case tables = "Tables"
    case settings = "Settings"
}

struct NfcMonitoringView: View {
    @StateObject private var viewModel = NfcMonitoringViewModel()
    @State private var selectedTab: NfcTab = .sessions
    @State private var showAddDevice = false
    @State private var showAddTable = false
    @State private var showOpenSession = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.overdueAlerts.isEmpty {
                    overdueAlertsBanner
                }

                Picker("Section", selection: $selectedTab) {
                    ForEach(NfcTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch selectedTab {
                case .sessions:
                    sessionsTab
                case .devices:
                    devicesTab
                case .tables:
                    tablesTab
                case .settings:
                    nfcSettingsTab
                }
            }
            .navigationTitle("NFC Monitoring")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButton
                }
            }
            .task {
                await viewModel.loadAll()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Overdue Banner

    private var overdueAlertsBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.overdueAlerts.count) table\(viewModel.overdueAlerts.count == 1 ? "" : "s") need\(viewModel.overdueAlerts.count == 1 ? "s" : "") attention")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                let names = viewModel.overdueAlerts.prefix(3).map(\.tableNumber).joined(separator: ", ")
                Text(names + (viewModel.overdueAlerts.count > 3 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(12)
        .background(AppColors.negative.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButton: some View {
        switch selectedTab {
        case .devices:
            Button { showAddDevice = true } label: {
                Image(systemName: "plus")
            }
            .sheet(isPresented: $showAddDevice) {
                AddDeviceSheet(viewModel: viewModel)
            }
        case .tables:
            Button { showAddTable = true } label: {
                Image(systemName: "plus")
            }
            .sheet(isPresented: $showAddTable) {
                AddTableSheet(viewModel: viewModel)
            }
        case .sessions:
            Button { showOpenSession = true } label: {
                Image(systemName: "plus")
            }
            .sheet(isPresented: $showOpenSession) {
                OpenSessionSheet(viewModel: viewModel)
            }
        case .settings:
            EmptyView()
        }
    }

    // MARK: - Sessions Tab

    private var sessionsTab: some View {
        List {
            if viewModel.sessions.isEmpty && !viewModel.isLoading {
                EmptyStateRow(
                    icon: "fork.knife.circle",
                    title: "No Active Sessions",
                    subtitle: "Open a session when guests are seated"
                )
            }
            ForEach(viewModel.sessions) { session in
                NavigationLink {
                    NfcCheckinHistoryView(session: session, viewModel: viewModel)
                } label: {
                    SessionCardView(session: session, viewModel: viewModel)
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.loadSessions(); await viewModel.loadOverdueAlerts() }
    }

    // MARK: - Devices Tab

    private var devicesTab: some View {
        List {
            if viewModel.devices.isEmpty && !viewModel.isLoading {
                EmptyStateRow(
                    icon: "wave.3.right.circle",
                    title: "No NFC Devices",
                    subtitle: "Register NFC tags to get started"
                )
            }
            ForEach(viewModel.devices) { device in
                DeviceRow(device: device, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.loadDevices() }
    }

    // MARK: - Tables Tab

    private var tablesTab: some View {
        List {
            if viewModel.tables.isEmpty && !viewModel.isLoading {
                EmptyStateRow(
                    icon: "tablecells",
                    title: "No Dining Tables",
                    subtitle: "Add tables and link NFC tags"
                )
            }
            ForEach(viewModel.tables) { table in
                TableRow(table: table, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.loadTables() }
    }

    // MARK: - Settings Tab

    private var nfcSettingsTab: some View {
        NfcSettingsView(viewModel: viewModel)
    }
}

// MARK: - Session Card

struct SessionCardView: View {
    let session: TableSession
    @ObservedObject var viewModel: NfcMonitoringViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.tableName(for: session.tableId))
                    .font(.headline)

                Spacer()

                SessionStatusChip(status: session.sessionStatus)
            }

            HStack(spacing: 16) {
                Label("\(session.guestCount)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(session.preference.displayName, systemImage: "bell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if session.sessionStatus == .foodDelivered, let due = session.nextCheckinDueAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Next check-in: \(formatTime(due))")
                        .font(.caption)
                }
                .foregroundStyle(AppColors.mixed)
            }

            HStack(spacing: 8) {
                if session.sessionStatus == .seated {
                    Button("Order Placed") {
                        Task { await viewModel.updateSessionStatus(sessionId: session.sessionId, status: .orderPlaced) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(AppColors.mixed)
                }

                if session.sessionStatus == .orderPlaced {
                    Button("Food Delivered") {
                        Task { await viewModel.updateSessionStatus(sessionId: session.sessionId, status: .foodDelivered) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(AppColors.positive)
                }

                if session.sessionStatus != .closed {
                    Button("Close") {
                        Task { await viewModel.updateSessionStatus(sessionId: session.sessionId, status: .closed) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(AppColors.neutral)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.timeStyle = .short
        return display.string(from: date)
    }
}

// MARK: - Status Chip

struct SessionStatusChip: View {
    let status: TableSessionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .seated: return AppColors.secondary
        case .orderPlaced: return AppColors.mixed
        case .foodDelivered: return AppColors.positive
        case .closed: return AppColors.neutral
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: NfcDevice
    @ObservedObject var viewModel: NfcMonitoringViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.type == .tableTag ? "tag.fill" : "person.badge.shield.checkmark")
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.label)
                    .font(.subheadline.weight(.medium))
                Text(device.deviceUid)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(device.type.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.primary.opacity(0.1))
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())

                Text(device.isActive ? "Active" : "Inactive")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(device.isActive ? AppColors.positive : AppColors.neutral)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                Task { await viewModel.toggleDevice(deviceId: device.deviceId, isActive: !device.isActive) }
            } label: {
                Label(device.isActive ? "Disable" : "Enable",
                      systemImage: device.isActive ? "xmark.circle" : "checkmark.circle")
            }
            .tint(device.isActive ? AppColors.neutral : AppColors.positive)
        }
    }
}

// MARK: - Table Row

struct TableRow: View {
    let table: DiningTable
    @ObservedObject var viewModel: NfcMonitoringViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tablecells")
                .font(.title3)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(table.tableNumber)
                    .font(.subheadline.weight(.medium))
                if let section = table.section {
                    Text(section)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption2)
                    Text("\(table.seatCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if let nfcLabel = viewModel.deviceLabel(for: table.nfcDeviceId) {
                    HStack(spacing: 3) {
                        Image(systemName: "wave.3.right")
                            .font(.caption2)
                        Text(nfcLabel)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.positive.opacity(0.1))
                    .foregroundStyle(AppColors.positive)
                    .clipShape(Capsule())
                } else {
                    Text("No NFC")
                        .font(.caption2)
                        .foregroundStyle(AppColors.neutral)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State Row

struct EmptyStateRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(AppColors.neutral.opacity(0.5))

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Add Device Sheet

struct AddDeviceSheet: View {
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var uid = ""
    @State private var deviceType: DeviceType = .tableTag
    @State private var label = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Device Details") {
                    TextField("NFC Tag UID", text: $uid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Type", selection: $deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField("Label (e.g. Table 5 Tag)", text: $label)
                }

                Section {
                    Text("Scan the NFC tag with a reader to find its UID, or enter it from the tag's packaging label.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Register NFC Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") {
                        Task {
                            await viewModel.registerDevice(uid: uid, type: deviceType, label: label)
                            dismiss()
                        }
                    }
                    .disabled(uid.isEmpty || label.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Table Sheet

struct AddTableSheet: View {
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tableNumber = ""
    @State private var section = ""
    @State private var seatCount = 4
    @State private var selectedDeviceId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Table Details") {
                    TextField("Table Number (e.g. T5)", text: $tableNumber)
                    TextField("Section (e.g. Patio)", text: $section)
                    Stepper("Seats: \(seatCount)", value: $seatCount, in: 1...100)
                }

                Section("NFC Tag") {
                    Picker("Link NFC Device", selection: $selectedDeviceId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(availableDevices) { device in
                            Text("\(device.label) (\(device.deviceUid))")
                                .tag(device.deviceId as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("Add Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.createTable(
                                number: tableNumber,
                                section: section.isEmpty ? nil : section,
                                seatCount: seatCount,
                                nfcDeviceId: selectedDeviceId
                            )
                            dismiss()
                        }
                    }
                    .disabled(tableNumber.isEmpty)
                }
            }
        }
    }

    private var availableDevices: [NfcDevice] {
        viewModel.devices.filter { $0.isActive && $0.type == .tableTag }
    }
}

// MARK: - Open Session Sheet

struct OpenSessionSheet: View {
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTableId: UUID?
    @State private var guestCount = 2
    @State private var preference: CheckinPreference = .all

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    Picker("Table", selection: $selectedTableId) {
                        Text("Select Table").tag(nil as UUID?)
                        ForEach(viewModel.tables.filter(\.isActive)) { table in
                            Text("\(table.tableNumber)\(table.section.map { " — \($0)" } ?? "")")
                                .tag(table.tableId as UUID?)
                        }
                    }

                    Stepper("Guests: \(guestCount)", value: $guestCount, in: 1...50)

                    Picker("Check-in Preference", selection: $preference) {
                        ForEach(CheckinPreference.allCases, id: \.self) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                }

                Section {
                    Text("The check-in timer starts automatically when food is delivered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Open Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Open") {
                        guard let tableId = selectedTableId else { return }
                        Task {
                            await viewModel.openSession(
                                tableId: tableId, serverId: nil,
                                guestCount: guestCount, preference: preference
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedTableId == nil)
                }
            }
        }
    }
}

// MARK: - NFC Settings View

struct NfcSettingsView: View {
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @State private var enabled = false
    @State private var interval = 15
    @State private var grace = 5
    @State private var alertOnMissed = true
    @State private var hasEdited = false

    var body: some View {
        Form {
            Section("NFC Monitoring") {
                Toggle("Enabled", isOn: $enabled)
                    .onChange(of: enabled) { hasEdited = true }
            }

            Section("Check-in Timer") {
                Stepper("Interval: \(interval) min", value: $interval, in: 1...120)
                    .onChange(of: interval) { hasEdited = true }

                Stepper("Grace Period: \(grace) min", value: $grace, in: 0...60)
                    .onChange(of: grace) { hasEdited = true }
            }

            Section("Alerts") {
                Toggle("Alert on Missed Check-in", isOn: $alertOnMissed)
                    .onChange(of: alertOnMissed) { hasEdited = true }
            }

            if hasEdited {
                Section {
                    Button {
                        Task {
                            let update = NfcSettingsUpdate(
                                enabled: enabled,
                                checkinIntervalMinutes: interval,
                                gracePeriodMinutes: grace,
                                alertOnMissedCheckin: alertOnMissed
                            )
                            await viewModel.updateNfcSettings(update)
                            hasEdited = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Settings")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .tint(AppColors.primary)
                }
            }
        }
        .onAppear {
            if let settings = viewModel.nfcSettings {
                enabled = settings.enabled
                interval = settings.checkinIntervalMinutes
                grace = settings.gracePeriodMinutes
                alertOnMissed = settings.alertOnMissedCheckin
            }
        }
    }
}
