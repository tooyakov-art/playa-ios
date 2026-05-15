import SwiftUI

struct FeedScreen: View {
    @EnvironmentObject private var auth: Auth

    @State private var posts: [PlayaPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isComposing = false
    @State private var composeText = ""
    @State private var selectedPost: PlayaPost?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Ink900").ignoresSafeArea()

                if isLoading && posts.isEmpty {
                    ProgressView().tint(Color("Hot"))
                } else if posts.isEmpty {
                    EmptyStateView(
                        title: "Лента скоро оживет",
                        message: errorMessage ?? "Первые посты появятся здесь. Авторизуйтесь, чтобы написать первым."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(posts) { post in
                                PostCard(
                                    post: post,
                                    onComments: { selectedPost = post },
                                    onReport: { Task { await report(post: post) } }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .refreshable { await reload() }
                }
            }
            .navigationTitle("Лента")
            .toolbar {
                Button {
                    isComposing = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(auth.isGuest)
            }
            .task { await reload() }
            .sheet(isPresented: $isComposing) {
                ComposePostSheet(
                    text: $composeText,
                    isGuest: auth.isGuest,
                    onCancel: {
                        composeText = ""
                        isComposing = false
                    },
                    onSubmit: {
                        Task { await createPost() }
                    }
                )
            }
            .sheet(item: $selectedPost) { post in
                PostCommentsSheet(post: post, service: SocialService(supabase: auth.supabase), currentUserId: auth.userId, isGuest: auth.isGuest)
            }
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await SocialService(supabase: auth.supabase).loadPosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func createPost() async {
        guard let userId = auth.userId, !auth.isGuest else { return }
        let text = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            _ = try await SocialService(supabase: auth.supabase).createPost(authorId: userId, text: text)
            composeText = ""
            isComposing = false
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func report(post: PlayaPost) async {
        guard let userId = auth.userId, !auth.isGuest else { return }
        await SocialService(supabase: auth.supabase).reportContent(reporterId: userId, kind: "post", targetId: post.id)
    }
}

private struct PostCard: View {
    let post: PlayaPost
    let onComments: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(url: post.author.avatarURL, fallback: String(post.author.name.prefix(1)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(post.author.username.map { "@\($0)" } ?? post.createdText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Menu {
                    Button("Пожаловаться", role: .destructive, action: onReport)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                }
            }

            Text(post.text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if let imageURL = post.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color("Ink700")
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 18) {
                Label("\(post.likesCount)", systemImage: "heart")
                Button(action: onComments) {
                    Label("\(post.commentsCount)", systemImage: "bubble.right")
                }
                Spacer()
                if !post.createdText.isEmpty {
                    Text(post.createdText)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.65))
        }
        .padding(14)
        .background(Color("Ink800"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct ComposePostSheet: View {
    @Binding var text: String
    let isGuest: Bool
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if isGuest {
                    Text("Гость может читать ленту. Для публикации войдите через Apple.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                TextEditor(text: $text)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(isGuest)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Новый пост")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Опубликовать", action: onSubmit)
                        .disabled(isGuest || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct AvatarView: View {
    let url: URL?
    let fallback: String

    var body: some View {
        ZStack {
            Circle().fill(Color("Hot").opacity(0.25))
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Text(fallback.uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text(fallback.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
    }
}
