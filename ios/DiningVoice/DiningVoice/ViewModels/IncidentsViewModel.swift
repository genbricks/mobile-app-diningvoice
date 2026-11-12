import Foundation

@MainActor
final class IncidentsViewModel: ObservableObject {
    @Published var incidents: [Incident] = []
    @Published var stats: IncidentStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSentiment: SentimentType = .negative

    private let network = NetworkService.shared

    func loadIncidents() async {
        isLoading = true
        errorMessage = nil

        do {
            let queryItems = [
                URLQueryItem(name: "sentiment", value: selectedSentiment.rawValue),
                URLQueryItem(name: "limit", value: "200"),
            ]

            async let incidentsTask: [Incident] = network.request(
                "GET",
                path: "/admin/alerts/incidents",
                queryItems: queryItems
            )
            async let statsTask: IncidentStats = network.request(
                "GET",
                path: "/admin/alerts/incident-stats"
            )

            let (incidentsResult, statsResult) = try await (incidentsTask, statsTask)
            incidents = incidentsResult
            stats = statsResult
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func closeIncident(id: String, notes: String) async -> Bool {
        do {
            let _: [String: String] = try await network.request(
                "POST",
                path: "/admin/alerts/incidents/\(id)/close",
                body: CloseIncidentRequest(resolutionNotes: notes)
            )
            await loadIncidents()
            return true
        } catch {
            errorMessage = "Failed to close incident"
            return false
        }
    }
}
