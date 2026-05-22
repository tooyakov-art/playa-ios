import SwiftUI

/// Editorial ink background with controlled hot/violet/cyan halo —
/// the visual signature for full-screen Playa views.
/// Apply with `.playaBackground()` on any root view.
struct PlayaBackground: View {
    var body: some View {
        ZStack {
            PlayaStyle.ink900

            // Hot glow — top center, the brand's heartbeat.
            RadialGradient(
                colors: [
                    PlayaStyle.hot.opacity(0.42),
                    .clear
                ],
                center: .init(x: 0.5, y: -0.05),
                startRadius: 10,
                endRadius: 460
            )

            // Violet wash — left mid, balances the hot.
            RadialGradient(
                colors: [
                    PlayaStyle.violet.opacity(0.26),
                    .clear
                ],
                center: .init(x: -0.06, y: 0.36),
                startRadius: 10,
                endRadius: 360
            )

            // Cyan kick — right top, keeps composition asymmetric.
            RadialGradient(
                colors: [
                    PlayaStyle.cyan.opacity(0.18),
                    .clear
                ],
                center: .init(x: 0.78, y: 0.06),
                startRadius: 4,
                endRadius: 220
            )

            // Bottom vignette — anchors the eye, hides edge artefacts.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.clear,
                    Color.black.opacity(0.36)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Layers `PlayaBackground` underneath the receiver.
    func playaBackground() -> some View {
        ZStack {
            PlayaBackground()
            self
        }
    }
}
