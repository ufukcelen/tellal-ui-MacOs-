//
//  ChatView.swift
//  Tellal
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var showingClearConfirmation = false
    @State private var showingNtfyNotificationSheet = false
    @State private var ntfyAlertText = ""

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            Divider()

            messageScrollView

            Divider()

            chatInputBar
        }
        .confirmationDialog(
            "Sohbeti Temizle",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sohbeti Temizle", role: .destructive) {
                viewModel.clearChat()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Tüm ekip için sohbet geçmişi silinecektir. Emin misiniz?")
        }
        .sheet(isPresented: $showingNtfyNotificationSheet) {
            directNotificationSheet
        }
    }

    private var chatHeader: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(viewModel.currentUser.avatarColor.gradient)
                        .frame(width: 32, height: 32)
                    Text(String(viewModel.currentUser.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Ekip Sohbeti")
                            .font(.headline)
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Canlı")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    Text("Kullanıcı: \(viewModel.currentUser.displayName) • Ufuk, Yiğit & Cem")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                showingNtfyNotificationSheet = true
            } label: {
                Label("Sesli Bildirim Gönder", systemImage: "megaphone.fill")
            }
            .buttonStyle(.bordered)
            .help("Karşı tarafa yüksek öncelikli macOS bildirimi gönderir")

            Button {
                Task {
                    await viewModel.syncChat()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isSyncingChat)
            .help("Sohbeti Yenile")

            Button {
                showingClearConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Sohbeti Temizle")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.chatMessages.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Henüz mesaj yok")
                                .font(.headline)
                            Text("Ekip arkadaşlarınızla buradan canlı mesajlaşabilirsiniz.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        ForEach(viewModel.chatMessages) { message in
                            let isCurrentUser = message.senderName.localizedCaseInsensitiveContains(viewModel.currentUser.displayName)
                            ChatBubble(message: message, isCurrentUser: isCurrentUser)
                                .id(message.id)
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.chatMessages.count) {
                if let lastMsg = viewModel.chatMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("Bir mesaj yazın...", text: $viewModel.chatInputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.sendMessage()
                }

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var directNotificationSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Doğrudan Bildirim Gönder")
                    .font(.headline)
                Spacer()
                Button("Kapat") {
                    showingNtfyNotificationSheet = false
                }
            }

            Text("Bu mesaj karşı tarafın Mac bilgisayarında yüksek öncelikli sesli sistem bildirimi olarak belirecektir.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Bildirim mesajınız...", text: $ntfyAlertText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("İptal") {
                    showingNtfyNotificationSheet = false
                }
                Button("Bildirimi Uçur") {
                    let msg = ntfyAlertText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !msg.isEmpty else { return }
                    Task {
                        await FirebaseService.shared.sendDirectNotification(from: viewModel.currentUser, message: msg)
                        viewModel.appendLog("Doğrudan bildirim yollandı: \(msg)", type: .success)
                    }
                    ntfyAlertText = ""
                    showingNtfyNotificationSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(ntfyAlertText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool

    var senderProfile: UserProfile {
        UserProfile.from(name: message.senderName)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 40)
            } else {
                ZStack {
                    Circle()
                        .fill(senderProfile.avatarColor.gradient)
                        .frame(width: 28, height: 28)
                    Text(String(message.senderName.prefix(1)))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption2.bold())
                        .foregroundStyle(senderProfile.avatarColor)
                }

                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isCurrentUser ? Color.blue : Color(nsColor: .controlBackgroundColor))
                    )
            }

            if !isCurrentUser {
                Spacer(minLength: 40)
            }
        }
        .contextMenu {
            Button("Kopyala") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
            }
        }
    }
}
