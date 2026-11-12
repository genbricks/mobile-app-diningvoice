import Foundation

@MainActor
final class PublicFeedbackViewModel: ObservableObject {
    @Published var feedbackText = ""
    @Published var email = ""
    @Published var selectedDepartment: String?
    @Published var departments: [PublicDepartment] = []
    @Published var isSubmitting = false
    @Published var isTranscribing = false
    @Published var isProofreading = false
    @Published var submitted = false
    @Published var referenceNumber: String?
    @Published var errorMessage: String?

    private let network = NetworkService.shared
    let maxCharacters = 350

    struct PublicDepartment: Codable, Identifiable, Hashable {
        let id: String
        let departmentName: String

        enum CodingKeys: String, CodingKey {
            case id
            case departmentName = "department_name"
        }
    }

    func loadDepartments() async {
        do {
            departments = try await network.request(
                "GET",
                path: "/public/departments",
                requiresAuth: false
            )
        } catch {
            // Departments are optional
        }
    }

    func submitFeedback() async {
        guard !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSubmitting = true
        errorMessage = nil

        do {
            struct FeedbackPayload: Codable {
                let text: String
                let email: String?
                let source: String
                let departmentId: String?

                enum CodingKeys: String, CodingKey {
                    case text, email, source
                    case departmentId = "department_id"
                }
            }

            let response: PublicFeedbackResponse = try await network.request(
                "POST",
                path: "/public/customer-feedback",
                body: FeedbackPayload(
                    text: feedbackText,
                    email: email.isEmpty ? nil : email,
                    source: "mobile_app",
                    departmentId: selectedDepartment
                ),
                requiresAuth: false
            )

            referenceNumber = response.referenceNumber
            submitted = true

            if !email.isEmpty, let feedbackId = response.feedbackId {
                try? await network.request(
                    "POST",
                    path: "/public/feedback-confirmation",
                    body: ["email": email, "feedback_id": feedbackId],
                    requiresAuth: false
                ) as [String: AnyCodable]
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func transcribeAudio(data: Data) async {
        isTranscribing = true

        do {
            guard let url = URL(string: Configuration.apiBaseURL + "/public/transcribe") else { return }

            let boundary = UUID().uuidString
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".utf8))
            body.append(Data("Content-Type: audio/m4a\r\n\r\n".utf8))
            body.append(data)
            body.append(Data("\r\n--\(boundary)--\r\n".utf8))

            let (responseData, _) = try await URLSession.shared.upload(for: request, from: body)

            struct TranscribeResponse: Codable {
                let text: String
                let language: String?
            }

            let result = try JSONDecoder().decode(TranscribeResponse.self, from: responseData)
            feedbackText = result.text
        } catch {
            errorMessage = "Transcription failed"
        }

        isTranscribing = false
    }

    func proofread() async {
        guard !feedbackText.isEmpty else { return }
        isProofreading = true

        do {
            struct ProofreadResponse: Codable {
                let text: String
            }

            let result: ProofreadResponse = try await network.request(
                "POST",
                path: "/public/proofread",
                body: ["text": feedbackText],
                requiresAuth: false
            )
            feedbackText = result.text
        } catch {
            // Proofread is best-effort
        }

        isProofreading = false
    }

    func reset() {
        feedbackText = ""
        email = ""
        selectedDepartment = nil
        submitted = false
        referenceNumber = nil
        errorMessage = nil
    }
}
