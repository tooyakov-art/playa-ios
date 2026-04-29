import SwiftUI

struct FeedScreen: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()
                EmptyStateView(
                    title: "Лента появится скоро",
                    message: "Здесь будут публикации от организаторов и сообществ Playa."
                )
            }
            .navigationTitle("Лента")
        }
    }
}
