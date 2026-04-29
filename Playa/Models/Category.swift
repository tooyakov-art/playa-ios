import SwiftUI

struct PlayaCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let systemIcon: String
    let tint: Color

    static let all: [PlayaCategory] = [
        .init(id: "music",   title: "Музыка",   systemIcon: "music.note",          tint: Color("Hot")),
        .init(id: "movies",  title: "Кино",     systemIcon: "film",                 tint: Color("Cyan")),
        .init(id: "sport",   title: "Спорт",    systemIcon: "figure.run",          tint: Color("Lime")),
        .init(id: "theatre", title: "Театр",    systemIcon: "theatermasks",        tint: Color("Violet")),
        .init(id: "food",    title: "Еда",      systemIcon: "fork.knife",          tint: Color("Ember")),
        .init(id: "art",     title: "Искусство", systemIcon: "paintpalette",       tint: Color("Bone"))
    ]
}
