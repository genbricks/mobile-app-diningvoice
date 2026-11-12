import SwiftUI

struct NfcCheckinHistoryView: View {
    let session: TableSession
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @State private var showRecordCheckin = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sessionHeader
                checkinTimeline
            }
            .padding(16)
        }
        .navigationTitle("Check-in History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if session.sessionStatus != .closed {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRecordCheckin = true
                    } label: {
                        Label("Check In", systemImage: "wave.3.right")
                    }
                }
            }
        }
        .sheet(isPresented: $showRecordCheckin) {
            RecordCheckinSheet(session: session, viewModel: viewModel)
        }
        .task {
            await viewModel.loadCheckins(sessionId: session.sessionId)
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.tableName(for: session.tableId))
                        .font(.title2.weight(.bold))

                    SessionStatusChip(status: session.sessionStatus)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(session.guestCount) guest\(session.guestCount == 1 ? "" : "s")")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)

                    Text(session.preference.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                TimelineSlot(label: "Seated", time: session.createdAt, isActive: true)
                TimelineSlot(label: "Ordered", time: session.orderPlacedAt, isActive: session.orderPlacedAt != nil)
                TimelineSlot(label: "Served", time: session.foodDeliveredAt, isActive: session.foodDeliveredAt != nil)
                TimelineSlot(label: "Closed", time: session.closedAt, isActive: session.closedAt != nil)
            }

            if session.sessionStatus == .foodDelivered, let due = session.nextCheckinDueAt {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                    Text("Next check-in due: \(formatTime(due))")
                        .font(.subheadline)
                }
                .foregroundStyle(AppColors.mixed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(AppColors.mixed.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Checkin Timeline

    @ViewBuilder
    private var checkinTimeline: some View {
        if viewModel.checkins.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.neutral.opacity(0.4))
                Text("No check-ins recorded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: 0) {
                Text("Check-ins (\(viewModel.checkins.count))")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                ForEach(Array(viewModel.checkins.enumerated()), id: \.element.id) { index, checkin in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(checkin.wasOnTime ? AppColors.positive : AppColors.negative)
                                .frame(width: 12, height: 12)
                                .padding(.top, 4)

                            if index < viewModel.checkins.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 12)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(formatTime(checkin.checkinAt))
                                    .font(.subheadline.weight(.medium))

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: checkin.wasOnTime ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.caption)
                                    Text(checkin.wasOnTime ? "On Time" : "Late")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundStyle(checkin.wasOnTime ? AppColors.positive : AppColors.negative)
                            }

                            Text("Tag: \(checkin.nfcDeviceUid)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Text("Server: \(checkin.serverMemberId.uuidString.prefix(8))...")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let notes = checkin.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.bottom, index < viewModel.checkins.count - 1 ? 16 : 0)
                    }
                }
            }
        }
    }

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.timeStyle = .short
        display.dateStyle = .short
        return display.string(from: date)
    }
}

// MARK: - Timeline Slot

struct TimelineSlot: View {
    let label: String
    let time: String?
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? AppColors.primary : Color.secondary.opacity(0.2))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(isActive ? .primary : .tertiary)

            if let time, isActive {
                Text(formatShortTime(time))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func formatShortTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return "" }
        let display = DateFormatter()
        display.timeStyle = .short
        return display.string(from: date)
    }
}

// MARK: - Record Checkin Sheet

struct RecordCheckinSheet: View {
    let session: TableSession
    @ObservedObject var viewModel: NfcMonitoringViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nfcUid = ""
    @State private var serverMemberId = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("NFC Tap") {
                    TextField("NFC Device UID", text: $nfcUid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Tap the table's NFC tag or enter the UID manually.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Server") {
                    TextField("Server Member ID", text: $serverMemberId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Notes (optional)") {
                    TextField("Any observations?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Record Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        guard let memberId = UUID(uuidString: serverMemberId) else { return }
                        Task {
                            await viewModel.recordCheckin(
                                nfcDeviceUid: nfcUid,
                                serverMemberId: memberId,
                                notes: notes.isEmpty ? nil : notes
                            )
                            await viewModel.loadCheckins(sessionId: session.sessionId)
                            dismiss()
                        }
                    }
                    .disabled(nfcUid.isEmpty || serverMemberId.isEmpty)
                }
            }
        }
    }
}
