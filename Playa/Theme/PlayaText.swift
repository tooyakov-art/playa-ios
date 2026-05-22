import SwiftUI

// MARK: - Typographic modifiers

private struct PlayaHeroModifier: ViewModifier {
    let size: CGFloat
    func body(content: Content) -> some View {
        content
            .font(.playaDisplay(size, weight: .black))
            .foregroundColor(.white)
            .tracking(-0.5)
            .lineSpacing(-2)
    }
}

private struct PlayaH1Modifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.playaDisplay(40, weight: .black))
            .foregroundColor(.white)
            .tracking(-0.4)
    }
}

private struct PlayaH2Modifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.playaDisplay(28, weight: .bold))
            .foregroundColor(.white)
    }
}

private struct PlayaH3Modifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.playaSans(20, weight: .semibold))
            .foregroundColor(.white)
    }
}

private struct PlayaBodyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.playaSans(15, weight: .regular))
            .foregroundColor(.white.opacity(0.92))
    }
}

private struct PlayaCaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.playaSans(13, weight: .regular))
            .foregroundColor(.white.opacity(0.62))
    }
}

private struct PlayaLabelModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .font(.playaMono(11, weight: .medium))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundColor(color)
    }
}

private struct PlayaSerifModifier: ViewModifier {
    let size: CGFloat
    let color: Color
    func body(content: Content) -> some View {
        content
            .font(.playaSerif(size))
            .italic()
            .foregroundColor(color)
    }
}

// MARK: - Text-friendly aliases

extension View {
    /// Big editorial title (default 56pt, Unbounded Black).
    func playaHero(_ size: CGFloat = 56) -> some View { modifier(PlayaHeroModifier(size: size)) }
    func playaH1() -> some View      { modifier(PlayaH1Modifier()) }
    func playaH2() -> some View      { modifier(PlayaH2Modifier()) }
    func playaH3() -> some View      { modifier(PlayaH3Modifier()) }
    func playaBody() -> some View    { modifier(PlayaBodyModifier()) }
    func playaCaption() -> some View { modifier(PlayaCaptionModifier()) }

    /// Mono uppercase label (city/time/category tags). Default colour: bone @ 70%.
    func playaLabel(color: Color = PlayaStyle.bone.opacity(0.70)) -> some View {
        modifier(PlayaLabelModifier(color: color))
    }

    /// Instrument Serif Italic flourish — use sparingly as a single-word accent
    /// inside an Unbounded display line.
    func playaSerif(_ size: CGFloat = 56, color: Color = .white) -> some View {
        modifier(PlayaSerifModifier(size: size, color: color))
    }
}
