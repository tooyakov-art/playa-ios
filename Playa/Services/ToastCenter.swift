import SwiftUI

/// App-wide toast notifications. Mount `ToastOverlay()` once at the root
/// (next to `LoginScreen` / `MainTabView`) and call `ToastCenter.shared.show(...)`
/// from anywhere — services, view-models, button handlers.
@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published var current: ToastMessage?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ text: String, kind: ToastKind = .info, duration: TimeInterval = 3.0) {
        dismissTask?.cancel()
        current = ToastMessage(id: UUID(), text: text, kind: kind)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run { self?.dismissIfMatches(id: self?.current?.id) }
        }

        switch kind {
        case .success: PlayaFeedback.success()
        case .warning: PlayaFeedback.warning()
        case .error:   PlayaFeedback.error()
        case .info:    PlayaFeedback.selection()
        }
    }

    func success(_ text: String) { show(text, kind: .success) }
    func warning(_ text: String) { show(text, kind: .warning) }
    func error(_ text: String)   { show(text, kind: .error) }
    func info(_ text: String)    { show(text, kind: .info) }

    private func dismissIfMatches(id: UUID?) {
        guard let id, current?.id == id else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            current = nil
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let kind: ToastKind
}

enum ToastKind {
    case info, success, warning, error

    var icon: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:    return PlayaStyle.cyan
        case .success: return PlayaStyle.lime
        case .warning: return PlayaStyle.ember
        case .error:   return PlayaStyle.hot
        }
    }
}

// MARK: - Overlay view

struct ToastOverlay: View {
    @StateObject private var center = ToastCenter.shared

    var body: some View {
        VStack {
            if let toast = center.current {
                HStack(spacing: 12) {
                    Image(systemName: toast.kind.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(toast.kind.tint)

                    Text(toast.text.uppercased())
                        .font(.playaMono(12, weight: .semibold))
                        .tracking(1.4)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .playaGlass(cornerRadius: 14)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: center.current?.id)
        .allowsHitTesting(false)
    }
}
