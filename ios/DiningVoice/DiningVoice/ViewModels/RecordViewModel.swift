import Foundation

@MainActor
final class RecordViewModel: ObservableObject {
    enum InputMode {
        case selection
        case voice
        case text
    }

    enum UploadState {
        case idle
        case uploading
        case success(Submission)
        case error(String)
    }

    @Published var mode: InputMode = .selection
    @Published var uploadState: UploadState = .idle
    @Published var textInput = ""
    @Published var selectedLanguage = "auto"

    let languages = [
        ("auto", "Auto-Detect"),
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("ru", "Russian"),
        ("tr", "Turkish"),
        ("vi", "Vietnamese"),
        ("th", "Thai"),
        ("id", "Indonesian"),
    ]

    private let network = NetworkService.shared

    func submitAudio(data: Data, filename: String) async {
        uploadState = .uploading

        do {
            let submission = try await network.uploadAudio(
                path: "/submissions/upload",
                audioData: data,
                filename: filename
            )
            uploadState = .success(submission)
        } catch let error as NetworkError {
            uploadState = .error(error.errorDescription ?? "Upload failed")
        } catch {
            uploadState = .error(error.localizedDescription)
        }
    }

    func submitText() async {
        guard !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        uploadState = .uploading

        do {
            let submission: Submission = try await network.request(
                "POST",
                path: "/submissions/text",
                body: ["text": textInput, "source": "mobile_app"]
            )
            uploadState = .success(submission)
            textInput = ""
        } catch let error as NetworkError {
            uploadState = .error(error.errorDescription ?? "Submission failed")
        } catch {
            uploadState = .error(error.localizedDescription)
        }
    }

    func reset() {
        mode = .selection
        uploadState = .idle
        textInput = ""
    }
}
