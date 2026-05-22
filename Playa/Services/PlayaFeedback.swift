import UIKit

/// Centralised haptic feedback — keep buttons, tab switches and like toggles
/// feeling alive. iOS preheats the generator on first use to remove latency.
enum PlayaFeedback {
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
