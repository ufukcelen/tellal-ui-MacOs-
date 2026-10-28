//
//  TellalViewModel.swift
//  Tellal
//

import SwiftUI
import AppKit
import Combine

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Genel Bakış"
    case schedule = "Yayın Takvimi"
    case chat = "Ekip Sohbeti"
    case uykusuzTosba = "Uykusuz Tosba"
    case radioMocas = "Radio Mocas"
    case console = "Terminal & Render"
    case settings = "Ayarlar & Ekip"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .schedule: return "calendar.badge.clock"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .uykusuzTosba: return "sportscourt.fill"
        case .radioMocas: return "mic.fill"
        case .console: return "terminal.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
final class TellalViewModel: ObservableObject {
    @Published var selectedTab: SidebarItem = .dashboard
    @Published var currentUser: UserProfile = .ufuk
    @Published var broadcasts: [BroadcastItem] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var chatInputText: String = ""

    @Published var isSyncingCalendar: Bool = false
    @Published var isSyncingChat: Bool = false
    @Published var isProcessRunning: Bool = false

    @Published var logs: [LogEntry] = []
    @Published var alertMessage: String?
    @Published var showAlert: Bool = false

    private var chatPollingTimer: Timer?

    init() {
        loadUserIdentity()
        loadLocalData()
        Task {
            await syncAll()
        }
        startChatPolling()
    }

    deinit {
        chatPollingTimer?.invalidate()
    }

    // MARK: - Kullanıcı Kimliği

    func loadUserIdentity() {
        let userFile = TellalConfig.shared.userFileURL
        if let data = try? String(contentsOf: userFile, encoding: .utf8) {
            let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
            self.currentUser = UserProfile.from(id: trimmed)
        } else if let savedId = UserDefaults.standard.string(forKey: "tellal_user_id") {
            self.currentUser = UserProfile.from(id: savedId)
        } else {
            self.currentUser = .ufuk
        }
    }

    func switchUser(to user: UserProfile) {
        self.currentUser = user
        UserDefaults.standard.set(user.id, forKey: "tellal_user_id")
        let userFile = TellalConfig.shared.userFileURL
        try? user.id.write(to: userFile, atomically: true, encoding: .utf8)
        appendLog("Aktif kullanıcı değiştirildi: \(user.displayName)", type: .standard)
    }

    // MARK: - Yerel Veri Yükleme

    func loadLocalData() {
        loadLocalCalendar()
        loadLocalChat()
    }

    private func loadLocalCalendar() {
        let calFile = TellalConfig.shared.calendarFileURL
        guard let content = try? String(contentsOf: calFile, encoding: .utf8) else { return }

        let rawLines = content.components(separatedBy: .newlines)
        var items: [BroadcastItem] = []
        var fallbackIdx = 1

        for line in rawLines {
            if let item = BroadcastItem.parse(from: line, defaultIndex: fallbackIdx) {
                items.append(item)
                fallbackIdx += 1
            }
        }
        self.broadcasts = items
    }

    private func loadLocalChat() {
        let chatFile = TellalConfig.shared.chatFileURL
        guard let content = try? String(contentsOf: chatFile, encoding: .utf8) else { return }

        let rawLines = content.components(separatedBy: .newlines)
        self.chatMessages = rawLines.compactMap { ChatMessage.parse(from: $0) }
    }

    // MARK: - Senkronizasyon (Firebase + Ntfy)

    func syncAll() async {
        await syncCalendar()
        await syncChat()
    }

    func syncCalendar() async {
        isSyncingCalendar = true
        defer { isSyncingCalendar = false }

        do {
            let lines = try await FirebaseService.shared.fetchCalendar()
            if !lines.isEmpty {
                var items: [BroadcastItem] = []
                var fallbackIdx = 1
                for line in lines {
                    if let item = BroadcastItem.parse(from: line, defaultIndex: fallbackIdx) {
                        items.append(item)
                        fallbackIdx += 1
                    }
                }
                self.broadcasts = items
                saveCalendarLocally(lines: lines)
            }
        } catch {
            appendLog("Takvim bulut senkronizasyonu atlandı: \(error.localizedDescription)", type: .warning)
        }
    }

    func syncChat() async {
        isSyncingChat = true
        defer { isSyncingChat = false }

        do {
            let lines = try await FirebaseService.shared.fetchChat()
            if !lines.isEmpty {
                let parsed = lines.compactMap { ChatMessage.parse(from: $0) }
                if parsed != self.chatMessages {
                    self.chatMessages = parsed
                    saveChatLocally(messages: lines)
                }
            }
        } catch {
            // sessizce geç
        }
    }

    private func startChatPolling() {
        chatPollingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncChat()
            }
        }
    }

    // MARK: - Yayın Takvimi İşlemleri

    func addBroadcast(title: String, day: String, time: String, info: String?) {
        let nextIndex = broadcasts.count + 1
        let newItem = BroadcastItem(
            index: nextIndex,
            title: title,
            dateDay: day,
            time: time,
            info: info
        )

        broadcasts.append(newItem)
        persistCalendar(actionDescription: "Yayın Eklendi: \(title)")
    }

    func toggleCompleted(item: BroadcastItem) {
        guard let index = broadcasts.firstIndex(where: { $0.id == item.id }) else { return }
        broadcasts[index].isCompleted.toggle()
        if broadcasts[index].isCompleted {
            broadcasts[index].isCancelled = false
        }
        persistCalendar(actionDescription: "Duyuru Durumu Değiştirildi")
    }

    func cancelBroadcast(item: BroadcastItem) {
        guard let index = broadcasts.firstIndex(where: { $0.id == item.id }) else { return }
        broadcasts[index].isCancelled.toggle()
        if broadcasts[index].isCancelled {
            broadcasts[index].isCompleted = false
        }
        persistCalendar(actionDescription: "Yayın İptal Durumu Değiştirildi")
    }

    func deleteBroadcast(item: BroadcastItem) {
        broadcasts.removeAll(where: { $0.id == item.id })
        // Numaralandırmayı yeniden düzenle
        for idx in 0..<broadcasts.count {
            broadcasts[idx].index = idx + 1
        }
        persistCalendar(actionDescription: "Yayın Silindi")
    }

    private func persistCalendar(actionDescription: String) {
        let lines = broadcasts.map { $0.toCalendarLine() }
        saveCalendarLocally(lines: lines)

        Task {
            do {
                try await FirebaseService.shared.saveCalendar(lines: lines, updatedBy: currentUser.displayName)
                appendLog("\(actionDescription) (Bulutla eşitlendi)", type: .success)
            } catch {
                appendLog("Buluta yazılamadı: \(error.localizedDescription)", type: .error)
            }
        }
    }

    private func saveCalendarLocally(lines: [String]) {
        let content = lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")
        let file = TellalConfig.shared.calendarFileURL
        try? content.write(to: file, atomically: true, encoding: .utf8)
    }

    // MARK: - Chat İşlemleri

    func sendMessage() {
        let text = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let newMsg = ChatMessage(senderName: currentUser.displayName, text: text)
        chatMessages.append(newMsg)
        chatInputText = ""

        let lines = chatMessages.map { $0.toChatLine() }
        saveChatLocally(messages: lines)

        Task {
            do {
                try await FirebaseService.shared.saveChat(messages: lines)
            } catch {
                appendLog("Chat buluta iletilemedi: \(error.localizedDescription)", type: .warning)
            }
        }
    }

    func clearChat() {
        chatMessages = []
        saveChatLocally(messages: [])
        Task {
            try? await FirebaseService.shared.saveChat(messages: [])
            appendLog("Sohbet geçmişi temizlendi", type: .standard)
        }
    }

    private func saveChatLocally(messages: [String]) {
        let content = messages.joined(separator: "\n") + (messages.isEmpty ? "" : "\n")
        let file = TellalConfig.shared.chatFileURL
        try? content.write(to: file, atomically: true, encoding: .utf8)
    }

    // MARK: - Log & Console

    func appendLog(_ message: String, type: LogEntry.LogType = .standard) {
        let entry = LogEntry(message: message, type: type)
        logs.append(entry)
    }

    func clearLogs() {
        logs.removeAll()
    }

    func stopActiveProcess() {
        ProcessRunner.shared.stop()
        isProcessRunning = false
        appendLog("İşlem kullanıcı tarafından durduruldu.", type: .warning)
    }

    // MARK: - Otomasyonlar & Render Tetikleme

    func syncGoogleCalendarViaPython() {
        appendLog("Google Calendar eşitlemesi başlatılıyor...", type: .standard)
        isProcessRunning = true

        let script = TellalConfig.shared.cliDirectory.appendingPathComponent("gcalendar_sync.py")
        let workDir = TellalConfig.shared.cliDirectory

        ProcessRunner.shared.runPythonScript(
            arguments: [script.path],
            workingDirectory: workDir,
            onOutput: { [weak self] line, type in
                self?.appendLog(line, type: type)
            },
            onCompletion: { [weak self] success in
                self?.isProcessRunning = false
                if success {
                    self?.appendLog("Google Calendar eşitlemesi tamamlandı.", type: .success)
                } else {
                    self?.appendLog("Google Calendar eşitlemesi hata ile sonuçlandı.", type: .error)
                }
            }
        )
    }

    func startAfterEffectsRender(
        projectPath: String,
        composition: String,
        outputTemplate: String = "ygiido",
        outputPath: String
    ) {
        appendLog("After Effects Render Başlatılıyor: \(composition)", type: .standard)
        isProcessRunning = true

        ProcessRunner.shared.runAfterEffectsRender(
            projectPath: projectPath,
            composition: composition,
            outputTemplate: outputTemplate,
            outputPath: outputPath,
            onOutput: { [weak self] line, type in
                self?.appendLog(line, type: type)
            },
            onCompletion: { [weak self] success in
                self?.isProcessRunning = false
                if success {
                    self?.appendLog("Render Başarıyla Tamamlandı: \(outputPath)", type: .success)
                } else {
                    self?.appendLog("Render tamamlanamadı veya hata oluştu.", type: .error)
                }
            }
        )
    }
}
