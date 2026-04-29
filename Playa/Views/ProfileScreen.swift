import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var auth: Auth

    @State private var deleteStage: DeleteStage = .idle
    @State private var errorMessage: String?

    private enum DeleteStage {
        case idle
        case firstConfirm
        case finalConfirm
        case deleting
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Аккаунт") {
                    if auth.isGuest {
                        HStack {
                            Text("Режим")
                            Spacer()
                            Text("Гость").foregroundColor(.secondary)
                        }
                    } else if let email = auth.userEmail {
                        LabeledContent("Email", value: email)
                    }
                    if let uid = auth.userId, !auth.isGuest {
                        LabeledContent("ID") {
                            Text(uid.prefix(8) + "…")
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button("Выйти") {
                        Task { await auth.signOut() }
                    }
                }

                if !auth.isGuest {
                    Section {
                        Button(role: .destructive) {
                            deleteStage = .firstConfirm
                        } label: {
                            if deleteStage == .deleting {
                                HStack {
                                    ProgressView()
                                    Text("Удаление…")
                                }
                            } else {
                                Text("Удалить аккаунт")
                            }
                        }
                        .disabled(deleteStage == .deleting)
                    } header: {
                        Text("Опасная зона")
                    } footer: {
                        Text("Аккаунт и все связанные данные будут удалены без возможности восстановления.")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }

                Section {
                    Link("Политика конфиденциальности", destination: PlayaConfig.privacyURL)
                    Link("Условия использования", destination: PlayaConfig.termsURL)
                    Link("Поддержка", destination: URL(string: "mailto:\(PlayaConfig.supportEmail)")!)
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Playa · v\(PlayaConfig.appVersion)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Удалить аккаунт?",
                isPresented: Binding(
                    get: { deleteStage == .firstConfirm },
                    set: { if !$0 { deleteStage = .idle } }
                ),
                titleVisibility: .visible
            ) {
                Button("Продолжить", role: .destructive) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        deleteStage = .finalConfirm
                    }
                }
                Button("Отмена", role: .cancel) { deleteStage = .idle }
            } message: {
                Text("Аккаунт и все данные будут удалены навсегда. Восстановить будет невозможно.")
            }
            .confirmationDialog(
                "Точно удалить?",
                isPresented: Binding(
                    get: { deleteStage == .finalConfirm },
                    set: { if !$0 { deleteStage = .idle } }
                ),
                titleVisibility: .visible
            ) {
                Button("Удалить навсегда", role: .destructive) {
                    Task { await runDelete() }
                }
                Button("Отмена", role: .cancel) { deleteStage = .idle }
            } message: {
                Text("После удаления аккаунт восстановить нельзя.")
            }
        }
    }

    private func runDelete() async {
        deleteStage = .deleting
        errorMessage = nil
        do {
            try await auth.deleteAccount()
            await MainActor.run { deleteStage = .idle }
        } catch {
            await MainActor.run {
                deleteStage = .idle
                errorMessage = "Ошибка удаления: \(error.localizedDescription)"
            }
        }
    }
}
