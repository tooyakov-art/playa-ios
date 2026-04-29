import SwiftUI

struct MatchesListView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()
                EmptyStateView(
                    title: "Чатов пока нет",
                    message: "Когда вы запишетесь на событие, тут появится групповой чат участников."
                )
            }
            .navigationTitle("Чаты")
        }
    }
}
