import SwiftUI

struct PostCommentsSheet: View {
    let post: PlayaPost
    let service: SocialService
    let currentUserId: String?
    let isGuest: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var comments: [PostComment] = []
    @State private var text = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isDemoPost: Bool {
        post.id.hasPrefix("demo-post-")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading && comments.isEmpty {
                    ProgressView().tint(Color("Hot"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    EmptyStateView(title: "Комментариев нет", message: "Будьте первым, кто ответит на пост.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(comments) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            AvatarView(url: comment.author.avatarURL, fallback: String(comment.author.name.prefix(1)))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.author.name)
                                    .font(.system(size: 14, weight: .bold))
                                Text(comment.text)
                                    .font(.system(size: 15))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                }

                HStack(spacing: 10) {
                    TextField("Комментарий", text: $text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color("Hot"))
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
                .background(.bar)
            }
            .navigationTitle("Комментарии")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Закрыть") { dismiss() }
            }
            .task { await reload() }
        }
        .presentationDetents([.medium, .large])
    }

    private func reload() async {
        if isDemoPost {
            comments = DemoContent.comments(for: post)
            return
        }
        isLoading = true
        do {
            comments = try await service.loadPostComments(postId: post.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func send() async {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if isDemoPost || isGuest {
            comments.append(
                PostComment(
                    id: "\(post.id)-local-\(Date().timeIntervalSince1970)",
                    postId: post.id,
                    authorId: currentUserId ?? "guest",
                    text: value,
                    createdAt: Date(),
                    author: PlayaProfile(id: "me", name: "Вы", username: "me", avatarURL: nil)
                )
            )
            text = ""
            return
        }

        guard let currentUserId else { return }
        do {
            _ = try await service.createPostComment(authorId: currentUserId, postId: post.id, text: value)
            text = ""
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
