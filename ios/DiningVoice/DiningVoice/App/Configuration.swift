import Foundation

enum Configuration {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000/api"
    #else
    static let apiBaseURL = "https://diningvoice-api.genbricks.io/api"
    #endif

    static let authHeaderKey = "X-DiningVoice-Auth"
    static let requestTimeout: TimeInterval = 30
    static let uploadTimeout: TimeInterval = 60
    static let maxRecordingDuration: TimeInterval = 300
    static let maxAudioFileSizeMB: Double = 25
}
