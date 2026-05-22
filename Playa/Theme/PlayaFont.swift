import SwiftUI

/// POSTER v2 typography — four font families, four roles.
///
/// - `playaDisplay` — Unbounded (heavy editorial titles, hero numerals)
/// - `playaSerif`   — Instrument Serif Italic (one-word accents inside display lines)
/// - `playaSans`    — Space Grotesk (body, UI text, controls)
/// - `playaMono`    — JetBrains Mono (labels, codes, metadata grids — UPPERCASE)
///
/// If a custom font is not registered (e.g. the asset hasn't been bundled yet),
/// SwiftUI's `Font.custom(_, size:)` silently falls back to the system font,
/// so the UI stays usable even before the fonts ship.
enum PlayaFontName {
    static func display(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy:     return "Unbounded-Black"
        case .bold:              return "Unbounded-Bold"
        case .semibold:          return "Unbounded-SemiBold"
        case .medium:            return "Unbounded-Medium"
        case .light, .thin, .ultraLight: return "Unbounded-Light"
        default:                 return "Unbounded-Regular"
        }
    }

    static let serifItalic = "InstrumentSerif-Italic"

    static func sans(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "SpaceGrotesk-Bold"
        case .semibold:             return "SpaceGrotesk-SemiBold"
        case .medium:               return "SpaceGrotesk-Medium"
        case .light, .thin, .ultraLight: return "SpaceGrotesk-Light"
        default:                    return "SpaceGrotesk-Regular"
        }
    }

    static func mono(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "JetBrainsMono-Bold"
        case .semibold:             return "JetBrainsMono-SemiBold"
        case .medium:               return "JetBrainsMono-Medium"
        default:                    return "JetBrainsMono-Regular"
        }
    }
}

extension Font {
    /// Unbounded — for hero/display titles. Default weight `.black`.
    static func playaDisplay(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .custom(PlayaFontName.display(weight), size: size)
    }

    /// Instrument Serif Italic — used as a one-word flourish inside a display line
    /// (e.g. «Город — *это* ты.»).
    static func playaSerif(_ size: CGFloat) -> Font {
        .custom(PlayaFontName.serifItalic, size: size)
    }

    /// Space Grotesk — primary UI sans for body and controls.
    static func playaSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(PlayaFontName.sans(weight), size: size)
    }

    /// JetBrains Mono — labels, codes, metadata. Pair with `.textCase(.uppercase)`.
    static func playaMono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .custom(PlayaFontName.mono(weight), size: size)
    }
}
