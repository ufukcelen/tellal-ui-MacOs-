//
//  FirebaseService.swift
//  Tellal
//

import Foundation

final class FirebaseService {
    static let shared = FirebaseService()

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 4.0
        configuration.timeoutIntervalForResource = 8.0
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Takvim (Calendar)

    func fetchCalendar() async throws -> [String] {
        guard let url = URL(string: "\(TellalConfig.firebaseDatabaseURL)/takvim.json") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Firebase returns either {"bos_mu": true} or {"satirlar": [...]} or raw array
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let isBos = jsonObject["bos_mu"] as? Bool, isBos {
                return []
            }
            if let satirlar = jsonObject["satirlar"] as? [String] {
                return satirlar
            } else if let satirlarDict = jsonObject["satirlar"] as? [String: String] {
                return Array(satirlarDict.values)
            }
        } else if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return jsonArray
        }

        return []
    }

    func saveCalendar(lines: [String], updatedBy: String) async throws {
        guard let url = URL(string: "\(TellalConfig.firebaseDatabaseURL)/takvim.json") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "satirlar": lines,
            "bos_mu": lines.isEmpty,
            "son_guncelleme": Int(Date().timeIntervalSince1970),
            "guncelleyen": updatedBy
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        _ = try await session.data(for: request)

        // Ntfy bildirimi gönder
        await postNtfyCalendar(lines: lines)
    }

    private func postNtfyCalendar(lines: [String]) async {
        guard let url = URL(string: "https://ntfy.sh") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let message = lines.isEmpty ? "__BOS_TAKVIM__" : lines.joined(separator: "\n")
        let payload: [String: Any] = [
            "topic": TellalConfig.ntfyCalendarTopic,
            "title": "Tellal Takvim Güncellemesi",
            "message": message,
            "priority": 3,
            "tags": ["calendar"]
        ]

        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await session.data(for: request)
        }
    }

    // MARK: - Chat (Sohbet)

    func fetchChat() async throws -> [String] {
        guard let url = URL(string: "\(TellalConfig.firebaseDatabaseURL)/chat.json") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let mesajlar = jsonObject["mesajlar"] as? [String] {
                return mesajlar
            } else if let mesajlarDict = jsonObject["mesajlar"] as? [String: String] {
                return Array(mesajlarDict.values)
            }
        } else if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return jsonArray
        }

        return []
    }

    func saveChat(messages: [String]) async throws {
        guard let url = URL(string: "\(TellalConfig.firebaseDatabaseURL)/chat.json") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "mesajlar": messages,
            "son_guncelleme": Int(Date().timeIntervalSince1970)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        _ = try await session.data(for: request)

        // Ntfy bildirimi gönder
        await postNtfyChat(messages: messages)
    }

    private func postNtfyChat(messages: [String]) async {
        guard let url = URL(string: "https://ntfy.sh") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let message = messages.isEmpty ? "__BOS_CHAT__" : messages.joined(separator: "\n")
        let payload: [String: Any] = [
            "topic": TellalConfig.ntfyChatTopic,
            "title": "Tellal Chat Güncellemesi",
            "message": message,
            "priority": 3,
            "tags": ["speech_balloon"]
        ]

        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await session.data(for: request)
        }
    }

    // MARK: - Doğrudan Kullanıcı Bildirimi

    func sendDirectNotification(from sender: UserProfile, message: String) async {
        guard let url = URL(string: "https://ntfy.sh/\(sender.ntfyOutgoingTopic)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Tellal Bildirimi (\(sender.displayName))", forHTTPHeaderField: "Title")
        request.setValue("loudspeaker", forHTTPHeaderField: "Tags")
        request.setValue("high", forHTTPHeaderField: "Priority")
        request.httpBody = message.data(using: .utf8)

        _ = try? await session.data(for: request)
    }
}
