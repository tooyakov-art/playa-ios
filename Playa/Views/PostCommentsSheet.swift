import SwiftUI

struct PostCommentsSheet: View {
    @EnvironmentObject private var appState: AppState

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
        ZStack {
            PlayaBackground()

            VStack(spacing: 0) {
                header
                content
                if let errorMessage {
                    Text(errorMessage)
                        .playaCaption()
                        .foregroundColor(PlayaStyle.hot)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 4)
                }
                composer
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Обсуждение").playaLabel()
                Text("Комментарии")
                    .font(.playaDisplay(20, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                PlayaFeedback.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(PlayaIconButton(size: 38))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Content (states)

    @ViewBuilder
    private var content: some View {
        if isLoading && comments.isEmpty {
            VStack {
                ProgressView().tint(PlayaStyle.hot)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if comments.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                Text("Комментариев нет").playaH3()
                Text("Будь первым, кто ответит на пост.")
                    .playaCaption()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(comments.filter { !appState.isBlocked(userId: $0.authorId) }) { comment in
                        commentRow(comment)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    private func commentRow(_ comment: PostComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(url: comment.author.avatarURL, fallback: String(comment.author.name.prefix(1)))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(comment.author.name)
                    .font(.playaSans(14, weight: .bold))
                    .foregroundColor(.white)
                Text(comment.text)
                    .font(.playaSans(14, weight: .regular))
                    .foregroundColor(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if comment.authorId != currentUserId {
                Menu {
                    Button("Пожаловаться", systemImage: "exclamationmark.bubble") {
                        reportComment(comment)
                    }
                    Button("Заблокировать пользователя", systemImage: "hand.raised.fill", role: .destructive) {
                        blockCommentAuthor(comment)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                }
            }
        }
        .padding(12)
        .playaPoster()
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("", text: $text,
                      prompt: Text("Комментарий").foregroundColor(.white.opacity(0.4)),
                      axis: .vertical)
                .font(.playaSans(15, weight: .regular))
                .foregroundColor(.white)
                .tint(PlayaStyle.hot)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(CommentSendButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(PlayaStyle.ink900.opacity(0.7))
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Data

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
        PlayaFeedback.impact(.light)
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

    private func reportComment(_ comment: PostComment) {
        Task {
            guard let reporterId = currentUserId, !isGuest, !isDemoPost else {
                ToastCenter.shared.success("Жалоба сохранена для модерации")
                return
            }
            do {
                try await service.reportContent(reporterId: reporterId, kind: "comment", targetId: comment.id, reason: "Comment report")
                ToastCenter.shared.success("Жалоба отправлена")
            } catch {
                ToastCenter.shared.error("Не удалось отправить жалобу")
            }
        }
    }

    private func blockCommentAuthor(_ comment: PostComment) {
        appState.blockUser(id: comment.authorId)
        comments.removeAll { $0.authorId == comment.authorId }
        ToastCenter.shared.success("Пользователь заблокирован")
    }
}

private struct CommentSendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy))
            .foregroundColor(.white)
            .frame(width: 46, height: 46)
            .background(
                Circle()
                    .fill(PlayaStyle.hot)
                    .shadow(color: PlayaStyle.hot.opacity(0.34), radius: 12, x: 0, y: 6)
            )
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
