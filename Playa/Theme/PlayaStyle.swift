import SwiftUI

/// POSTER v2 design tokens — single source of truth.
/// Colors mirror the web design-system (`--ink`, `--hot`, `--bone`, etc.) and live
/// in `Assets.xcassets` so they pick up the right value automatically.
enum PlayaStyle {
    static let hot      = Color("Hot")
    static let hotDeep  = Color("HotDeep")
    static let bone     = Color("Bone")
    static let ink900   = Color("Ink900")
    static let ink800   = Color("Ink800")
    static let ink700   = Color("Ink700")
    static let cyan     = Color("Cyan")
    static let lime     = Color("Lime")
    static let ember    = Color("Ember")
    static let violet   = Color("Violet")

    /// Hairline border used on poster cards (1px white at 6% — same as web `.ds-poster`).
    static let hairline = Color.white.opacity(0.06)

    /// Standard corner radius for cards/buttons — keeps the editorial, sharp feel.
    static let radiusCard: CGFloat = 18
    static let radiusButton: CGFloat = 14
    static let radiusPill: CGFloat = 999

    static func glassStroke(_ opacity: Double = 0.22) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(opacity),
                Color.white.opacity(0.055),
                hot.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass modifiers

private struct PlayaGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let highlight: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.34))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(min(highlight, 0.08)),
                                Color.white.opacity(0.018),
                                PlayaStyle.hot.opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.055),
                                PlayaStyle.bone.opacity(0.36)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
            .shadow(color: PlayaStyle.hot.opacity(0.16), radius: 12, x: 0, y: 0)
    }
}

private struct PlayaGlassCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.36))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.075),
                                Color.white.opacity(0.018),
                                PlayaStyle.hot.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.055),
                                PlayaStyle.bone.opacity(0.42)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.46), radius: 18, x: 0, y: 8)
            .shadow(color: PlayaStyle.hot.opacity(0.18), radius: 12, x: 0, y: 0)
    }
}

/// Hairline poster card — flat, no glass, just an 1px stroke and subtle fill.
/// Matches `.ds-poster` on the web side.
private struct PlayaPosterModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(PlayaStyle.ink800)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(PlayaStyle.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Premium glass card (ultra-thin material + tinted overlay + double shadow).
    /// Use for hero cards, sheets, prominent buttons.
    func playaGlass(cornerRadius: CGFloat = PlayaStyle.radiusCard, highlight: Double = 0.13) -> some View {
        modifier(PlayaGlassModifier(cornerRadius: cornerRadius, highlight: highlight))
    }

    /// Circular glass — avatars, FAB, icon buttons.
    func playaGlassCircle() -> some View {
        modifier(PlayaGlassCircleModifier())
    }

    /// Flat editorial poster card with hairline border.
    /// Use for grid cells, list items, content surfaces where glass would be too noisy.
    func playaPoster(cornerRadius: CGFloat = PlayaStyle.radiusCard) -> some View {
        modifier(PlayaPosterModifier(cornerRadius: cornerRadius))
    }
}
