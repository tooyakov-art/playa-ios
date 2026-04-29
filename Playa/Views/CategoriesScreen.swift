import SwiftUI

struct CategoriesScreen: View {
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(PlayaCategory.all) { category in
                            CategoryCard(category: category)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Категории")
        }
    }
}

private struct CategoryCard: View {
    let category: PlayaCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.systemIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(category.tint)
                .frame(width: 56, height: 56)
                .background(category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            Text(category.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 140)
        .background(Color("Ink800"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
