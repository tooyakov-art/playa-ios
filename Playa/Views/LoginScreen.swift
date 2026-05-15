import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
    @EnvironmentObject private var auth: Auth
    @State private var errorMessage: String?
    @State private var isGoogleLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color("Hot"), Color("HotDeep"), Color("Cyan").opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                        .shadow(color: Color("Hot").opacity(0.45), radius: 22, y: 10)
                    Text("P")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Playa")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                    Text("Вход нужен, чтобы лайкать, сохранять события и писать в чаты.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.66))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await handleApple(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                Button {
                    Task { await handleGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        if isGoogleLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                        Text("Войти через Google")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .disabled(isGoogleLoading)

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    Link("Privacy", destination: PlayaConfig.privacyURL)
                    Text("·").foregroundColor(.white.opacity(0.3))
                    Link("Terms", destination: PlayaConfig.termsURL)
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color("Ink900")
                RemoteImage(url: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80"))
                    .opacity(0.16)
                    .blur(radius: 1)
            }
            .ignoresSafeArea()
        )
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .success(let authorization):
            do {
                try await auth.signInWithApple(authorization: authorization)
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error as NSError):
            if error.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple: \(error.localizedDescription)"
            }
        }
    }

    private func handleGoogle() async {
        errorMessage = nil
        isGoogleLoading = true
        defer { isGoogleLoading = false }
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = "Google: \(error.localizedDescription)"
        }
    }
}
