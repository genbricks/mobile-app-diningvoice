import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            RecordFeedbackView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(1)

            SubmissionsView()
                .tabItem {
                    Label("Submissions", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(2)

            if auth.user?.role == "admin" {
                IncidentsView()
                    .tabItem {
                        Label("Incidents", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            } else {
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
        }
        .tint(AppColors.primary)
    }
}
