import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = auth.user {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let role = user.role {
                                    Text(role.capitalized)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppColors.primary.opacity(0.1))
                                        .foregroundStyle(AppColors.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Appearance") {
                    Button {
                        themeManager.toggle()
                    } label: {
                        HStack {
                            Label("Theme", systemImage: themeManager.iconName)
                            Spacer()
                            Text(themeLabel)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://diningvoice.genbricks.io")!) {
                        Label("DiningVoice Web", systemImage: "globe")
                    }

                    Link(destination: URL(string: "https://genbricks.io")!) {
                        Label("GenBricks", systemImage: "link")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) { auth.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private var themeLabel: String {
        switch themeManager.iconName {
        case "sun.max.fill": return "Light"
        case "moon.fill": return "Dark"
        default: return "System"
        }
    }
}
