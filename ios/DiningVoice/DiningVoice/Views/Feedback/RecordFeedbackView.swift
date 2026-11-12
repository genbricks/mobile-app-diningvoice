import SwiftUI

struct RecordFeedbackView: View {
    @StateObject private var viewModel = RecordViewModel()
    @StateObject private var recorder = AudioRecorderService()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.mode {
                case .selection:
                    modeSelectionView
                case .voice:
                    voiceRecordingView
                case .text:
                    textInputView
                }
            }
            .navigationTitle("Record Feedback")
            .overlay {
                if case .uploading = viewModel.uploadState {
                    uploadingOverlay
                }
            }
            .alert("Upload Complete", isPresented: showSuccessBinding) {
                Button("OK") { viewModel.reset() }
            } message: {
                if case .success(let submission) = viewModel.uploadState {
                    Text("Feedback submitted successfully.\nSentiment: \(submission.sentiment.displayName)")
                }
            }
            .alert("Error", isPresented: showErrorBinding) {
                Button("Try Again") { viewModel.uploadState = .idle }
                Button("Cancel", role: .cancel) { viewModel.reset() }
            } message: {
                if case .error(let msg) = viewModel.uploadState {
                    Text(msg)
                }
            }
        }
    }

    private var modeSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How would you like to submit feedback?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                modeCard(
                    title: "Talk",
                    subtitle: "Record voice feedback",
                    icon: "mic.fill",
                    gradient: [AppColors.primary, AppColors.primaryDark]
                ) {
                    Task {
                        let granted = await recorder.requestPermission()
                        if granted {
                            viewModel.mode = .voice
                        }
                    }
                }

                modeCard(
                    title: "Type",
                    subtitle: "Write text feedback",
                    icon: "keyboard.fill",
                    gradient: [AppColors.secondary, Color(hex: "1d4ed8")]
                ) {
                    viewModel.mode = .text
                }
            }
            .padding(.horizontal)

            infoCard

            Spacer()
        }
    }

    private func modeCard(
        title: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, y: 4)
        }
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI-Powered Analysis")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Your feedback will be transcribed, translated, and analyzed for sentiment automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var voiceRecordingView: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    recorder.deleteRecording()
                    viewModel.mode = .selection
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline)
                }

                Spacer()

                languagePicker
            }
            .padding(.horizontal)

            Spacer()

            AudioWaveformView(
                isActive: recorder.isRecording,
                level: recorder.audioLevel,
                isPaused: recorder.isPaused
            )
            .frame(height: 80)
            .padding(.horizontal, 32)

            Text(formatDuration(recorder.recordingDuration))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(recorder.isRecording ? AppColors.primary : .secondary)

            Text("Max \(Int(Configuration.maxRecordingDuration / 60)) minutes")
                .font(.caption)
                .foregroundStyle(.secondary)

            recordingControls

            Spacer()
        }
    }

    private var recordingControls: some View {
        HStack(spacing: 24) {
            if !recorder.isRecording && recorder.recordingURL == nil {
                Button {
                    try? recorder.startRecording()
                } label: {
                    Label("Start Recording", systemImage: "mic.fill")
                        .fontWeight(.semibold)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .clipShape(Capsule())
                .padding(.horizontal, 32)
            } else if recorder.isRecording {
                Button {
                    if recorder.isPaused {
                        recorder.resumeRecording()
                    } else {
                        recorder.pauseRecording()
                    }
                } label: {
                    Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .clipShape(Circle())

                Button {
                    _ = recorder.stopRecording()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .clipShape(Circle())
            } else if recorder.recordingURL != nil {
                Button {
                    recorder.deleteRecording()
                } label: {
                    Label("Record Again", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button {
                    guard let data = recorder.getAudioData(),
                          let url = recorder.recordingURL else { return }
                    Task {
                        await viewModel.submitAudio(
                            data: data,
                            filename: url.lastPathComponent
                        )
                    }
                } label: {
                    Label("Submit", systemImage: "paperplane.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
        }
        .padding(.horizontal)
    }

    private var languagePicker: some View {
        Menu {
            ForEach(viewModel.languages, id: \.0) { code, name in
                Button(name) {
                    viewModel.selectedLanguage = code
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption)
                Text(viewModel.languages.first { $0.0 == viewModel.selectedLanguage }?.1 ?? "Auto")
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .clipShape(Capsule())
        }
        .foregroundStyle(.primary)
    }

    private var textInputView: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    viewModel.mode = .selection
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Write your feedback")
                    .font(.headline)

                TextEditor(text: $viewModel.textInput)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                HStack {
                    Text("\(viewModel.textInput.count) / 10,000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)

            Button {
                Task { await viewModel.submitText() }
            } label: {
                Label("Submit Feedback", systemImage: "paperplane.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            Spacer()
        }
    }

    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Analyzing feedback...")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("This may take a moment")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var showSuccessBinding: Binding<Bool> {
        Binding(
            get: {
                if case .success = viewModel.uploadState { return true }
                return false
            },
            set: { if !$0 { viewModel.uploadState = .idle } }
        )
    }

    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.uploadState { return true }
                return false
            },
            set: { if !$0 { viewModel.uploadState = .idle } }
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}
