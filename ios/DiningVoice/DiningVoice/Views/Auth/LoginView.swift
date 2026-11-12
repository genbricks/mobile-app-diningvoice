import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var otpCode = ""
    @State private var showOTP = false
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var authMode: AuthMode = .password

    enum AuthMode: String, CaseIterable {
        case password = "Password"
        case otp = "Email OTP"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    VStack(spacing: 24) {
                        Picker("Sign in method", selection: $authMode) {
                            ForEach(AuthMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let error = auth.errorMessage {
                            ErrorBanner(message: error) {
                                auth.errorMessage = nil
                            }
                        }

                        switch authMode {
                        case .password:
                            passwordForm
                        case .otp:
                            otpForm
                        }

                        signUpLink
                    }
                    .padding(24)
                }
            }
            .background(
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.05), AppColors.primary.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 60)

            Text("DiningVoice")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)

            Text("Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 32)
    }

    private var passwordForm: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }

            HStack {
                Button("Forgot password?") {
                    showForgotPassword = true
                }
                .font(.caption)
                .foregroundStyle(AppColors.primary)

                Spacer()
            }

            Button {
                Task { await auth.login(email: email, password: password) }
            } label: {
                Group {
                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(email.isEmpty || password.isEmpty || auth.isLoading)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var otpForm: some View {
        VStack(spacing: 16) {
            if !auth.otpSent {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("your@email.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Button {
                    Task { await auth.sendOTP(email: email) }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send OTP")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(email.isEmpty || auth.isLoading)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Enter the 6-digit code sent to \(auth.otpEmail)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("000000", text: $otpCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospaced())
                    .frame(maxWidth: 200)
                    .frame(maxWidth: .infinity)

                Button {
                    Task { await auth.verifyOTP(code: otpCode) }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify & Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(otpCode.count < 6 || auth.isLoading)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Use a different email") {
                    auth.otpSent = false
                    otpCode = ""
                }
                .font(.caption)
                .foregroundStyle(AppColors.primary)
            }
        }
    }

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Sign Up") {
                showRegister = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.primary)
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isValid: Bool {
        !email.isEmpty && !username.isEmpty && password.count >= 8 && passwordsMatch
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let error = auth.errorMessage {
                        ErrorBanner(message: error) { auth.errorMessage = nil }
                    }

                    Group {
                        LabeledTextField(label: "Email", text: $email, placeholder: "your@email.com")
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        LabeledTextField(label: "Username", text: $username, placeholder: "Choose a username")
                            .textContentType(.username)
                            .autocapitalization(.none)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            SecureField("Minimum 8 characters", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)

                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Button {
                        Task {
                            await auth.register(email: email, username: username, password: password)
                            if auth.isAuthenticated { dismiss() }
                        }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .disabled(!isValid || auth.isLoading)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(24)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if sent {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.positive)

                    Text("Check your email")
                        .font(.headline)

                    Text("We've sent password reset instructions to \(email)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                } else {
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    TextField("your@email.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Button {
                        Task {
                            await auth.forgotPassword(email: email)
                            sent = true
                        }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .disabled(email.isEmpty || auth.isLoading)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
