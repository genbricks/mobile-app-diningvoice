import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var analytics: AnalyticsData?
    @Published var incidentStats: IncidentStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedDepartment: String?
    @Published var startDate: Date?
    @Published var endDate: Date?
    @Published var departments: [String] = []

    private let network = NetworkService.shared

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let analyticsTask: AnalyticsData = loadAnalytics()
            async let incidentsTask: IncidentStats = network.request("GET", path: "/admin/alerts/incident-stats")
            async let deptTask: [String] = network.request("GET", path: "/analytics/categories")

            let (analyticsResult, incidentsResult, deptResult) = try await (
                analyticsTask, incidentsTask, deptTask
            )

            analytics = analyticsResult
            incidentStats = incidentsResult
            departments = deptResult
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearFilters() {
        selectedDepartment = nil
        startDate = nil
        endDate = nil
        Task { await loadDashboard() }
    }

    private func loadAnalytics() async throws -> AnalyticsData {
        var queryItems: [URLQueryItem] = []

        if let dept = selectedDepartment {
            queryItems.append(URLQueryItem(name: "category", value: dept))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let start = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: formatter.string(from: start)))
        }
        if let end = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: formatter.string(from: end)))
        }

        return try await network.request(
            "GET",
            path: "/analytics/",
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
    }
}
