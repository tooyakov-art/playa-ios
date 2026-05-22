import SwiftUI

/// Apple-style buttons, but tuned to POSTER v2:
/// - height 52pt
/// - RoundedRectangle(cornerRadius: 14, style: .continuous)
/// - subtle scale + opacity on press (no flashy bouncy animations)
/// - distinct semantic variants (hot primary, bone secondary, ghost tertiary, glass icon)

private let kPlayaButtonHeight: CGFloat = 52
private let kPlayaButtonRadius: CGFloat = 14

// MARK: - Primary (hot) — main calls-to-action

struct PlayaPrimaryButton: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.playaSans(16, weight: .bold))
            .foregroundStyle(Color.black)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: kPlayaButtonHeight)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .fill(PlayaStyle.hot)
            )
            .overlay(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: PlayaStyle.hot.opacity(0.36), radius: 18, x: 0, y: 10)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Bone (light) — secondary actions on dark backgrounds

struct PlayaBoneButton: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.playaSans(16, weight: .semibold))
            .foregroundStyle(PlayaStyle.ink900)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: kPlayaButtonHeight)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .fill(PlayaStyle.bone)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Ghost — tertiary, lives on dark bg, low visual weight

struct PlayaGhostButton: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.playaSans(16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: kPlayaButtonHeight)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Ink (almost black) — high-contrast secondary on light/bone backgrounds

struct PlayaInkButton: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.playaSans(16, weight: .semibold))
            .foregroundStyle(PlayaStyle.bone)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: kPlayaButtonHeight)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(
                RoundedRectangle(cornerRadius: kPlayaButtonRadius, style: .continuous)
                    .fill(PlayaStyle.ink900)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Icon (44×44 glass circle) — header back/settings/like buttons

struct PlayaIconButton: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .playaGlassCircle()
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Chip — mono uppercase filter pill

struct PlayaChipButton: ButtonStyle {
    var active: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.playaMono(11, weight: .medium))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(active ? PlayaStyle.ink900 : .white)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                Capsule(style: .continuous)
                    .fill(active ? PlayaStyle.hot : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(active ? .clear : Color.white.opacity(0.14), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
