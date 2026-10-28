//
//  ChatMessage.swift
//  Tellal
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Hashable {
    let id: UUID
    var senderName: String
    var text: String
    var timestamp: Date

    init(id: UUID = UUID(), senderName: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
    }

    /// Satırdan parse: "Ufuk: Merhaba" veya "Mustafa Yiğit Kızılel: Selam"
    static func parse(from rawLine: String) -> ChatMessage? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Gemini AI mesajlarını chat kutusundan ayıkla
        if trimmed.lowercased().contains("gemini ai") {
            return nil
        }

        if let colonIndex = trimmed.firstIndex(of: ":") {
            let sender = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let messageText = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            return ChatMessage(senderName: sender, text: messageText)
        } else {
            return ChatMessage(senderName: "Bilinmeyen", text: trimmed)
        }
    }

    func toChatLine() -> String {
        return "\(senderName): \(text)"
    }
}
