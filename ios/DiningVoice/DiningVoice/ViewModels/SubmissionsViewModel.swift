import Foundation

@MainActor
final class SubmissionsViewModel: ObservableObject {
    @Published var submissions: [Submission] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalCount = 0

    private var currentPage = 1
    private let pageSize = 20
    private var hasMore = true
    private let network = NetworkService.shared

    var filterCategory: String?
    var filterSentiment: String?

    func loadSubmissions(reset: Bool = true) async {
        if reset {
            currentPage = 1
            hasMore = true
            submissions = []
        }

        guard hasMore, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(currentPage)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
                URLQueryItem(name: "include_transcription", value: "true"),
            ]

            if let cat = filterCategory {
                queryItems.append(URLQueryItem(name: "category", value: cat))
            }

            if let sentiment = filterSentiment {
                queryItems.append(URLQueryItem(name: "status_filter", value: sentiment))
            }

            struct PagedResponse: Codable {
                let items: [Submission]
                let total: Int
                let page: Int
                let pageSize: Int
                let totalPages: Int

                enum CodingKeys: String, CodingKey {
                    case items, total, page
                    case pageSize = "page_size"
                    case totalPages = "total_pages"
                }
            }

            let response: PagedResponse = try await network.request(
                "GET",
                path: "/submissions/",
                queryItems: queryItems
            )

            if reset {
                submissions = response.items
            } else {
                submissions.append(contentsOf: response.items)
            }

            totalCount = response.total
            hasMore = currentPage < response.totalPages
            currentPage += 1
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        await loadSubmissions(reset: false)
    }

    func deleteSubmission(id: String) async -> Bool {
        do {
            let _: Data = try await network.requestRaw("DELETE", path: "/submissions/\(id)")
            submissions.removeAll { $0.id == id }
            totalCount -= 1
            return true
        } catch {
            errorMessage = "Failed to delete submission"
            return false
        }
    }
}
