//
//  AutomationModels.swift
//  Tellal
//

import Foundation

enum StandardProgram: String, CaseIterable, Identifiable {
    case haftalikProgram = "Haftalık Program"
    case canliMacSohbetleri = "Canlı Maç Sohbetleri"
    case macSonu = "Maç Sonu"
    case tekMactanYatanlar = "Tek Maçtan Yatanlar"
    case fc27Kariyer = "FC27 Kariyer"
    case tosbaLojistik = "Tosba Lojistik (ETS2)"
    case filtresizMemleket = "Filtresiz Memleket Havası"
    case albertVeCem = "Albert ve Cem"
    case mocasBey = "Mocas Bey ve Radyosu"
    case aklimdakiFilmler = "Aklımdaki Filmler"

    var id: String { rawValue }

    var channel: ChannelType {
        switch self {
        case .haftalikProgram, .canliMacSohbetleri, .macSonu, .tekMactanYatanlar, .fc27Kariyer, .tosbaLojistik:
            return .uykusuzTosba
        case .filtresizMemleket, .albertVeCem, .mocasBey, .aklimdakiFilmler:
            return .radioMocas
        }
    }

    var iconName: String {
        switch self {
        case .haftalikProgram: return "calendar.badge.clock"
        case .canliMacSohbetleri: return "sportscourt.fill"
        case .macSonu: return "flag.checkered"
        case .tekMactanYatanlar: return "doc.text.magnifyingglass"
        case .fc27Kariyer: return "gamecontroller.fill"
        case .tosbaLojistik: return "truck.box.fill"
        case .filtresizMemleket: return "mic.fill"
        case .albertVeCem: return "sparkles.tv.fill"
        case .mocasBey: return "radio.fill"
        case .aklimdakiFilmler: return "film.fill"
        }
    }
}

enum ChannelType: String, CaseIterable, Identifiable {
    case uykusuzTosba = "Uykusuz Tosba"
    case radioMocas = "Radio Mocas"

    var id: String { rawValue }

    var colorName: String {
        switch self {
        case .uykusuzTosba: return "cyan"
        case .radioMocas: return "purple"
        }
    }

    var handle: String {
        switch self {
        case .uykusuzTosba: return "/uykusuztosba"
        case .radioMocas: return "/radiomocas"
        }
    }
}

enum FootballLeague: String, CaseIterable, Identifiable {
    case superLig = "Süper Lig"
    case championsLeague = "Şampiyonlar Ligi"
    case europaLeague = "Avrupa Ligi"
    case conferenceLeague = "Konferans Ligi"
    case premierLeague = "Premier Lig"
    case nationsLeague = "Uluslar Ligi"

    var id: String { rawValue }

    var backgroundFile: String {
        switch self {
        case .superLig: return "superligback.png"
        case .championsLeague: return "clback.png"
        case .europaLeague: return "europaback.png"
        case .conferenceLeague: return "confBack.png"
        case .premierLeague: return "superligback.png"
        case .nationsLeague: return "ulusArka.png"
        }
    }

    var borderFile: String {
        switch self {
        case .superLig: return "superlig.png"
        case .championsLeague: return "cl.png"
        case .europaLeague: return "europa.png"
        case .conferenceLeague: return "conferance.png"
        case .premierLeague: return "premier lig.png"
        case .nationsLeague: return "uluslarLigi.png"
        }
    }
}

struct LogEntry: Identifiable, Equatable {
    let id: UUID = UUID()
    let timestamp: Date = Date()
    let message: String
    let type: LogType

    enum LogType {
        case standard
        case progress
        case warning
        case error
        case success
    }
}
