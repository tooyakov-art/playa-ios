import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
    @EnvironmentObject private var auth: Auth
    @State private var errorMessage: String?
    @State private var isGoogleLoading = false
    @State private var showAppleFallback = false
    @State private var showGoogleFallback = false
    @State private var showDiagnostics = false

    var body: some View {
        ZStack {
            PlayaBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                hero
                    .padding(.horizontal, 24)

                Spacer()

                authBlock
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .confirmationDialog(
            "Apple вход не завершён",
            isPresented: $showAppleFallback,
            titleVisibility: .visible
        ) {
            Button("Продолжить на этом устройстве") {
                auth.continueWithLocalAccount(provider: "apple")
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Сейчас вход через Apple не завершился. Можно продолжить и посмотреть приложение без синхронизации.")
        }
        .confirmationDialog(
            "База данных недоступна",
            isPresented: $showGoogleFallback,
            titleVisibility: .visible
        ) {
            Button("Продолжить на этом устройстве") {
                auth.continueWithLocalAccount(provider: "google")
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Сейчас вход через Google недоступен. Можно продолжить и посмотреть приложение без синхронизации.")
        }
        .sheet(isPresented: $showDiagnostics) {
            NavigationStack {
                BackendDiagnosticsView()
            }
        }
    }

    // MARK: - Hero (top half)

    private var hero: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Mono kicker: city / issue
            HStack(spacing: 8) {
                Text("Алматы")
                Text("·")
                Text("Issue 03 / 2026")
            }
            .playaLabel()

            // Editorial display headline with serif-italic flourish.
            // «Город — *это* ты.»
            (
                Text("Город — ")
                    .font(.playaDisplay(46, weight: .black))
                    .foregroundColor(.white)
                +
                Text("это")
                    .font(.playaSerif(50))
                    .italic()
                    .foregroundColor(PlayaStyle.hot)
                +
                Text(" ты.")
                    .font(.playaDisplay(46, weight: .black))
                    .foregroundColor(.white)
            )
            .tracking(-0.6)
            .lineSpacing(-2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Text("Афиша, билеты, чаты — для тех, кто живёт в Алматы и любит выйти ночью.")
                .playaBody()
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Auth (bottom half)

    private var authBlock: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await handleApple(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                Task { await handleGoogle() }
            } label: {
                HStack(spacing: 10) {
                    if isGoogleLoading {
                        ProgressView().tint(PlayaStyle.ink900)
                    } else {
                        Text("G")
                            .font(.playaSans(20, weight: .bold))
                            .foregroundColor(PlayaStyle.ink900)
                    }
                    Text("Войти через Google")
                }
            }
            .buttonStyle(PlayaBoneButton())
            .disabled(isGoogleLoading)

            Button {
                PlayaFeedback.selection()
                auth.continueWithLocalAccount(provider: "guest")
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle")
                    Text("Продолжить без входа")
                }
            }
            .buttonStyle(PlayaGhostButton())

            if let error = errorMessage {
                Text(error)
                    .playaCaption()
                    .foregroundColor(PlayaStyle.hot)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            HStack(spacing: 12) {
                Link("Privacy", destination: PlayaConfig.privacyURL)
                Circle().frame(width: 3, height: 3).foregroundColor(.white.opacity(0.25))
                Link("Terms", destination: PlayaConfig.termsURL)
                Circle().frame(width: 3, height: 3).foregroundColor(.white.opacity(0.25))
                Button("Статус базы") { showDiagnostics = true }
            }
            .playaLabel(color: .white.opacity(0.5))
            .padding(.top, 12)
        }
    }

    // MARK: - Actions

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .success(let authorization):
            do {
                try await auth.signInWithApple(authorization: authorization)
            } catch {
                errorMessage = error.localizedDescription
                showAppleFallback = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showAppleFallback = true
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
            showGoogleFallback = true
        }
    }
}
