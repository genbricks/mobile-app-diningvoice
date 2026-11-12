import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var otpSent = false
    @Published var otpEmail = ""

    private let network = NetworkService.shared

    init() {
        if let savedUser = KeychainService.shared.getUser(),
           KeychainService.shared.getToken() != nil {
            self.user = savedUser
            self.isAuthenticated = true
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AuthResponse = try await network.request(
                "POST",
                path: "/auth/login-json",
                body: LoginRequest(email: email, password: password),
                requiresAuth: false
            )
            KeychainService.shared.saveToken(response.accessToken)
            KeychainService.shared.saveUser(response.user)
            user = response.user
            isAuthenticated = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register(email: String, username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AuthResponse = try await network.request(
                "POST",
                path: "/auth/register",
                body: RegisterRequest(email: email, username: username, password: password),
                requiresAuth: false
            )
            KeychainService.shared.saveToken(response.accessToken)
            KeychainService.shared.saveUser(response.user)
            user = response.user
            isAuthenticated = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func sendOTP(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let _: [String: String] = try await network.request(
                "POST",
                path: "/auth/send-otp",
                body: ["email": email],
                requiresAuth: false
            )
            otpEmail = email
            otpSent = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyOTP(code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AuthResponse = try await network.request(
                "POST",
                path: "/auth/verify-otp",
                body: ["email": otpEmail, "otp": code],
                requiresAuth: false
            )
            KeychainService.shared.saveToken(response.accessToken)
            KeychainService.shared.saveUser(response.user)
            user = response.user
            isAuthenticated = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func forgotPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let _: [String: String] = try await network.request(
                "POST",
                path: "/auth/forgot-password",
                body: ["email": email],
                requiresAuth: false
            )
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        KeychainService.shared.clearAll()
        user = nil
        isAuthenticated = false
        otpSent = false
        otpEmail = ""
    }

    func refreshUser() async {
        do {
            let updatedUser: User = try await network.request("GET", path: "/auth/me")
            KeychainService.shared.saveUser(updatedUser)
            user = updatedUser
        } catch is NetworkError {
            logout()
        } catch {
            // Ignore transient errors
        }
    }
}
