import SwiftUI

struct SubmissionsView: View {
    @StateObject private var viewModel = SubmissionsViewModel()
    @State private var showDeleteConfirm = false
    @State private var deleteTargetId: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.submissions.isEmpty {
                    LoadingView()
                } else if viewModel.submissions.isEmpty {
                    EmptyStateView(
                        icon: "mic.slash",
                        title: "No Submissions",
                        message: "Record or type feedback to see submissions here."
                    )
                } else {
                    submissionsList
                }
            }
            .navigationTitle("Submissions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(viewModel.totalCount) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .refreshable {
                await viewModel.loadSubmissions()
            }
            .alert("Delete Submission", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    guard let id = deleteTargetId else { return }
                    Task { _ = await viewModel.deleteSubmission(id: id) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .task {
            await viewModel.loadSubmissions()
        }
    }

    private var submissionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.submissions) { submission in
                    SubmissionCardView(submission: submission) {
                        deleteTargetId = submission.id
                        showDeleteConfirm = true
                    }
                    .onAppear {
                        if submission.id == viewModel.submissions.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct SubmissionCardView: View {
    let submission: Submission
    var onDelete: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            transcriptionContent
            footerRow
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SentimentBadge(
                    sentiment: submission.sentiment,
                    confidence: submission.confidenceScore
                )

                if let urgency = submission.urgencyScore, urgency > 0 {
                    UrgencyBadge(score: urgency)
                }

                Spacer()

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
            }

            HStack(spacing: 12) {
                if let ref = submission.referenceNumber {
                    Text(ref)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .monospaced()
                        .foregroundStyle(.secondary)
                }

                Label(submission.formattedDate, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label(submission.formattedDuration, systemImage: "waveform")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let category = extractCategory() {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.primary.opacity(0.1))
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())
            }
        }
    }

    private var transcriptionContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch submission.transcription {
            case .data(let data):
                if let original = data.originalText, original != data.text {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "text.quote")
                                .font(.caption2)
                            Text("Original")
                                .font(.caption2)
                                .fontWeight(.medium)
                            if let lang = data.language {
                                Text("(\(lang))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.secondary)

                        Text(original)
                            .font(.subheadline)
                            .lineLimit(isExpanded ? nil : 3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption2)
                            Text("Translated")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(AppColors.secondary)

                        Text(data.text)
                            .font(.subheadline)
                            .lineLimit(isExpanded ? nil : 3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(data.text)
                        .font(.subheadline)
                        .lineLimit(isExpanded ? nil : 4)
                }

            case .text(let text):
                Text(text)
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 4)
            }

            if submission.transcriptionText.count > 200 {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation { isExpanded.toggle() }
                }
                .font(.caption)
                .foregroundStyle(AppColors.primary)
            }
        }
    }

    private var footerRow: some View {
        HStack {
            if let tone = extractTone() {
                Text(tone)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }

            if let status = submission.processingStatus {
                HStack(spacing: 3) {
                    Circle()
                        .fill(statusColor(status))
                        .frame(width: 6, height: 6)
                    Text(status.rawValue.capitalized)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func extractCategory() -> String? {
        if case .data(let data) = submission.transcription {
            return data.dynamicCategory
        }
        return nil
    }

    private func extractTone() -> String? {
        if case .data(let data) = submission.transcription {
            return data.tone
        }
        return nil
    }

    private func statusColor(_ status: ProcessingStatus) -> Color {
        switch status {
        case .completed: return .green
        case .processing: return .orange
        case .pending: return .gray
        case .failed: return .red
        }
    }
}
