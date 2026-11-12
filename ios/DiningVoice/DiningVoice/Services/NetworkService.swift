import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int, String)
    case decodingError(String)
    case networkFailure(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Data error: \(detail)"
        case .networkFailure(let message):
            return "Network error: \(message)"
        case .noData:
            return "No data received"
        }
    }
}

actor NetworkService {
    static let shared = NetworkService()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Configuration.requestTimeout
        config.timeoutIntervalForResource = Configuration.uploadTimeout
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard var components = URLComponents(string: Configuration.apiBaseURL + path) else {
            throw NetworkError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainService.shared.getToken() {
            request.setValue(token, forHTTPHeaderField: Configuration.authHeaderKey)
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractErrorMessage(from: data)
            throw NetworkError.serverError(httpResponse.statusCode, message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    func uploadAudio(
        path: String,
        audioData: Data,
        filename: String,
        mimeType: String = "audio/m4a"
    ) async throws -> Submission {
        guard let url = URL(string: Configuration.apiBaseURL + path) else {
            throw NetworkError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.timeoutInterval = Configuration.uploadTimeout

        if let token = KeychainService.shared.getToken() {
            request.setValue(token, forHTTPHeaderField: Configuration.authHeaderKey)
        }

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n")

        let (data, response) = try await session.upload(for: request, from: body)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.networkFailure("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractErrorMessage(from: data)
            throw NetworkError.serverError(httpResponse.statusCode, message)
        }

        struct UploadResponse: Codable {
            let submission: Submission
            let message: String
        }

        let decoded = try decoder.decode(UploadResponse.self, from: data)
        return decoded.submission
    }

    func requestRaw(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: Configuration.apiBaseURL + path) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainService.shared.getToken() {
            request.setValue(token, forHTTPHeaderField: Configuration.authHeaderKey)
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.networkFailure("Request failed")
        }

        return data
    }

    private func extractErrorMessage(from data: Data) -> String {
        struct ErrorBody: Codable {
            let detail: String?
            let message: String?
        }
        if let body = try? JSONDecoder().decode(ErrorBody.self, from: data) {
            return body.detail ?? body.message ?? "Unknown error"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
