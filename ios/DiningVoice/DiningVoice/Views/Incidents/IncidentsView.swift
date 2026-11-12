import SwiftUI

struct IncidentsView: View {
    @StateObject private var viewModel = IncidentsViewModel()
    @State private var showCloseSheet = false
    @State private var selectedIncident: Incident?
    @State private var resolutionNotes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sentimentPicker

                Group {
                    if viewModel.isLoading && viewModel.incidents.isEmpty {
                        LoadingView()
                    } else if viewModel.incidents.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.shield.fill",
                            title: "No Incidents",
                            message: "No \(viewModel.selectedSentiment.rawValue) incidents to display."
                        )
                    } else {
                        incidentsList
                    }
                }
            }
            .navigationTitle("Incidents")
            .refreshable {
                await viewModel.loadIncidents()
            }
            .sheet(isPresented: $showCloseSheet) {
                closeIncidentSheet
            }
        }
        .task {
            await viewModel.loadIncidents()
        }
    }

    private var sentimentPicker: some View {
        VStack(spacing: 12) {
            if let stats = viewModel.stats {
                HStack(spacing: 8) {
                    MiniStatCard(title: "Open", value: stats.openCount, color: .orange)
                    MiniStatCard(title: "Closed", value: stats.closedCount, color: AppColors.positive)
                    MiniStatCard(title: "Total", value: stats.openCount + stats.closedCount, color: AppColors.primary)
                }
                .padding(.horizontal)
            }

            Picker("Sentiment", selection: $viewModel.selectedSentiment) {
                Text("Negative").tag(SentimentType.negative)
                Text("Positive").tag(SentimentType.positive)
                Text("Neutral").tag(SentimentType.neutral)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: viewModel.selectedSentiment) { _, _ in
                Task { await viewModel.loadIncidents() }
            }
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var incidentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.incidents) { incident in
                    IncidentCard(incident: incident) {
                        selectedIncident = incident
                        resolutionNotes = ""
                        showCloseSheet = true
                    }
                }
            }
            .padding()
        }
    }

    private var closeIncidentSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let incident = selectedIncident {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(incident.incidentNumber)
                            .font(.headline)
                            .monospaced()

                        if let dept = incident.departmentName {
                            Label(dept, systemImage: "building.2")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let category = incident.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.primary.opacity(0.1))
                                .foregroundStyle(AppColors.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Resolution Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $resolutionNotes)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                Button {
                    guard let incident = selectedIncident else { return }
                    Task {
                        let success = await viewModel.closeIncident(
                            id: incident.id,
                            notes: resolutionNotes
                        )
                        if success { showCloseSheet = false }
                    }
                } label: {
                    Text("Close Incident")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.positive)
                .disabled(resolutionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()
            }
            .padding()
            .navigationTitle("Close Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCloseSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct IncidentCard: View {
    let incident: Incident
    var onClose: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(incident.incidentNumber)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospaced()

                Spacer()

                statusChip
            }

            if let dept = incident.departmentName {
                Label(dept, systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let category = incident.category {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.primary.opacity(0.1))
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())
            }

            if let text = incident.submissionText {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Label(incident.formattedDate, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if incident.isOpen, let onClose {
                    Button("Close", action: onClose)
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .tint(AppColors.positive)
                }
            }

            if let notes = incident.resolutionNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resolution")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(AppColors.positive.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(incident.isOpen ? Color.orange : AppColors.positive)
                .frame(width: 6, height: 6)
            Text(incident.isOpen ? "Open" : "Closed")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(incident.isOpen ? Color.orange.opacity(0.1) : AppColors.positive.opacity(0.1))
        .foregroundStyle(incident.isOpen ? .orange : AppColors.positive)
        .clipShape(Capsule())
    }
}
