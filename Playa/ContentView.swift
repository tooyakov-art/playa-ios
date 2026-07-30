import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: Auth
    @State private var startupPhase: StartupPhase = .launching

    var body: some View {
        ZStack {
            Group {
                switch startupPhase {
                case .launching:
                    PlayaStartupView(onRetry: nil)
                case .needsRetry:
                    PlayaStartupView(onRetry: {
                        Task { await startApplication() }
                    })
                case .ready:
                    if auth.isAuthenticated {
                        MainTabView()
                    } else {
                        LoginScreen()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.22), value: auth.isAuthenticated)
            .animation(.easeInOut(duration: 0.24), value: startupPhase)

            ToastOverlay()
                .padding(.top, 8)
        }
        .task {
            await startApplication()
        }
    }

    @MainActor
    private func startApplication() async {
        startupPhase = .launching

        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled, startupPhase == .launching else { return }
            startupPhase = .needsRetry
        }

        // Give the first SwiftUI frame time to paint the branded startup surface.
        // Session restoration itself is synchronous and must never keep the user
        // behind an unbounded spinner.
        try? await Task.sleep(nanoseconds: 320_000_000)
        timeoutTask.cancel()

        guard !Task.isCancelled else { return }
        startupPhase = .ready
    }
}

private enum StartupPhase: Equatable {
    case launching
    case needsRetry
    case ready
}

private struct PlayaStartupView: View {
    let onRetry: (() -> Void)?

    var body: some View {
        ZStack {
            PlayaBackground()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(PlayaStyle.hot.opacity(0.18))
                        .frame(width: 92, height: 92)
                    Circle()
                        .stroke(PlayaStyle.hot.opacity(0.55), lineWidth: 1)
                        .frame(width: 92, height: 92)
                    Text("P")
                        .font(.playaDisplay(42, weight: .black))
                        .foregroundColor(.white)
                }

                VStack(spacing: 7) {
                    Text("PLAYA")
                        .font(.playaDisplay(28, weight: .black))
                        .foregroundColor(.white)
                        .tracking(1.2)
                    Text(onRetry == nil ? "Загружаем город" : "Запуск занял дольше обычного")
                        .playaCaption()
                        .foregroundColor(.white.opacity(0.62))
                }

                if let onRetry {
                    Button("Повторить запуск", action: onRetry)
                        .buttonStyle(PlayaPrimaryButton())
                        .frame(maxWidth: 260)
                } else {
                    ProgressView()
                        .tint(PlayaStyle.hot)
                        .accessibilityLabel("Запуск Playa")
                }
            }
            .padding(28)
        }
        .ignoresSafeArea()
    }
}
