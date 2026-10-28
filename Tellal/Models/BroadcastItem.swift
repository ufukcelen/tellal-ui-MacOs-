//
//  BroadcastItem.swift
//  Tellal
//

import Foundation

struct BroadcastItem: Identifiable, Equatable, Hashable {
    let id: UUID
    var index: Int
    var title: String
    var dateDay: String
    var time: String
    var info: String?
    var isCompleted: Bool
    var isCancelled: Bool

    init(
        id: UUID = UUID(),
        index: Int,
        title: String,
        dateDay: String,
        time: String,
        info: String? = nil,
        isCompleted: Bool = false,
        isCancelled: Bool = false
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.dateDay = dateDay
        self.time = time
        self.info = info
        self.isCompleted = isCompleted
        self.isCancelled = isCancelled
    }

    /// Satırı takvim.txt formatına dönüştürür:
    /// örn: "1-) Filtresiz Memleket Havası - 28 Ekim (Çarşamba) - 22:00"
    func toCalendarLine() -> String {
        var baseTitle = title
        if isCompleted && !baseTitle.contains("✅") {
            baseTitle += " ✅"
        }
        if isCancelled && !baseTitle.contains("❌") {
            baseTitle = "[❌ İPTAL] " + baseTitle
        }

        var line = "\(index)-) \(baseTitle) - \(dateDay) - \(time)"
        if let info = info, !info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            line += " | Bilgi: \(info)"
        }
        return line
    }

    /// Bir takvim.txt satırını çözer
    static func parse(from rawLine: String, defaultIndex: Int) -> BroadcastItem? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Gemini AI veya bot filtreleme
        if trimmed.contains("Gemini AI") || trimmed.contains("[Gemini AI]") {
            return nil
        }

        var line = trimmed
        var parsedIndex = defaultIndex

        if let parenRange = line.range(of: "-)") {
            let indexPart = String(line[..<parenRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            if let idx = Int(indexPart) {
                parsedIndex = idx
            }
            line = String(line[parenRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        var info: String? = nil
        if let infoRange = line.range(of: " | Bilgi: ") {
            info = String(line[infoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            line = String(line[..<infoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        let isCompleted = line.contains("✅")
        let isCancelled = line.contains("❌")

        var cleaned = line.replacingOccurrences(of: "✅", with: "")
            .replacingOccurrences(of: "❌", with: "")
            .replacingOccurrences(of: "[❌ İPTAL]", with: "")
            .replacingOccurrences(of: "[❌]", with: "")
            .trimmingCharacters(in: .whitespaces)

        // tire ile ayrılmış parçaları ayıkla: Başlık - Gün - Saat
        let parts = cleaned.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespaces) }

        let title: String
        let dateDay: String
        let time: String

        if parts.count >= 3 {
            // Son parça saat, sondan bir önceki gün, öncesi başlık (başlıkta tire olabilir)
            time = parts.last ?? "21:00"
            dateDay = parts[parts.count - 2]
            title = parts[0..<(parts.count - 2)].joined(separator: " - ")
        } else if parts.count == 2 {
            title = parts[0]
            dateDay = parts[1]
            time = "21:00"
        } else {
            title = cleaned
            dateDay = "Bugün"
            time = "21:00"
        }

        return BroadcastItem(
            index: parsedIndex,
            title: title.isEmpty ? "Canlı Yayın" : title,
            dateDay: dateDay,
            time: time,
            info: info,
            isCompleted: isCompleted,
            isCancelled: isCancelled
        )
    }
}
