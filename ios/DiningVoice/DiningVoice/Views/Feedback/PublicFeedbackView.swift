import SwiftUI

struct PublicFeedbackView: View {
    @StateObject private var viewModel = PublicFeedbackViewModel()
    @StateObject private var recorder = AudioRecorderService()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isRecording = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.submitted {
                    successView
                } else {
                    feedbackForm
                }
            }
            .background(
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.05), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Guest Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        themeManager.toggle()
                    } label: {
                        Image(systemName: themeManager.iconName)
                    }
                }
            }
        }
        .task {
            await viewModel.loadDepartments()
        }
    }

    private var feedbackForm: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primary)

                Text("Share Your Experience")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your feedback helps us improve")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal)
            }

            VStack(spacing: 16) {
                if !viewModel.departments.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Department (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Menu {
                            Button("None") { viewModel.selectedDepartment = nil }
                            ForEach(viewModel.departments) { dept in
                                Button(dept.departmentName) {
                                    viewModel.selectedDepartment = dept.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(
                                    viewModel.departments.first {
                                        $0.id == viewModel.selectedDepartment
                                    }?.departmentName ?? "Select department"
                                )
                                .foregroundStyle(
                                    viewModel.selectedDepartment == nil ? .secondary : .primary
                                )
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email (optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("your@email.com", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Your feedback")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(viewModel.feedbackText.count)/\(viewModel.maxCharacters)")
                            .font(.caption)
                            .foregroundStyle(
                                viewModel.feedbackText.count > viewModel.maxCharacters
                                    ? .red : .secondary
                            )
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.feedbackText)
                            .frame(minHeight: 120)
                            .padding(4)

                        if viewModel.feedbackText.isEmpty {
                            Text("Tell us about your dining experience...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                    toolbarButtons
                }
            }
            .padding(.horizontal)

            Button {
                Task { await viewModel.submitFeedback() }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Label("Submit Feedback", systemImage: "paperplane.fill")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(
                viewModel.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSubmitting
                    || viewModel.feedbackText.count > viewModel.maxCharacters
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            featuresInfo
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
    }

    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.proofread() }
            } label: {
                if viewModel.isProofreading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "textformat.abc")
                }
            }
            .disabled(viewModel.feedbackText.isEmpty || viewModel.isProofreading)

            Button {
                if recorder.isRecording {
                    if let url = recorder.stopRecording(),
                       let data = try? Data(contentsOf: url) {
                        Task { await viewModel.transcribeAudio(data: data) }
                        recorder.deleteRecording()
                    }
                } else {
                    Task {
                        let granted = await recorder.requestPermission()
                        if granted {
                            try? recorder.startRecording()
                        }
                    }
                }
            } label: {
                if viewModel.isTranscribing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.fill")
                        .foregroundStyle(recorder.isRecording ? .red : AppColors.primary)
                }
            }
            .disabled(viewModel.isTranscribing)

            Spacer()
        }
        .font(.title3)
        .padding(.top, 4)
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppColors.positive)

            Text("Thank You!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your feedback has been submitted successfully.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let ref = viewModel.referenceNumber {
                VStack(spacing: 4) {
                    Text("Reference Number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ref)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospaced()
                        .foregroundStyle(AppColors.primary)
                }
                .padding()
                .background(AppColors.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                viewModel.reset()
            } label: {
                Text("Submit Another")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var featuresInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Features")
                .font(.subheadline)
                .fontWeight(.medium)

            featureRow(icon: "globe", title: "Multi-Language", detail: "Speak in any language")
            featureRow(icon: "text.badge.checkmark", title: "Auto-Translation", detail: "Automatic translation to English")
            featureRow(icon: "brain", title: "AI Analysis", detail: "Sentiment and category classification")
            featureRow(icon: "text.bubble", title: "Mixed Language", detail: "Mix languages in one message")
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 24, height: 24)
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
