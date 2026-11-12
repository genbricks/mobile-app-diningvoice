import Foundation

@MainActor
class FeatureStatusViewModel: ObservableObject {
    @Published var features: TenantFeatures?
    @Published var error: String?

    func loadFeatures() async {
        do {
            features = try await NetworkService.shared.request("GET", path: "/features")
        } catch {
            self.error = error.localizedDescription
        }
    }
}
