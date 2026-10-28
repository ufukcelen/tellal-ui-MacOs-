//
//  UserProfile.swift
//  Tellal
//

import SwiftUI

enum UserProfile: String, CaseIterable, Identifiable, Codable {
    case ufuk = "1"
    case yigit = "2"
    case cem = "3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ufuk: return "Ufuk"
        case .yigit: return "Yiğit"
        case .cem: return "Cem Yıldırım"
        }
    }

    var avatarColor: Color {
        switch self {
        case .ufuk: return .blue
        case .yigit: return .purple
        case .cem: return .orange
        }
    }

    var systemImage: String {
        switch self {
        case .ufuk: return "person.crop.circle.fill"
        case .yigit: return "person.crop.circle.fill.badge.checkmark"
        case .cem: return "person.crop.circle.badge.questionmark"
        }
    }

    var ntfyIncomingTopic: String {
        switch self {
        case .ufuk: return "tellal_duyuru_ufuk_yigit_y2u_7294"
        case .yigit: return "tellal_duyuru_ufuk_yigit_u2y_7294"
        case .cem: return "tellal_duyuru_ufuk_yigit_y2u_7294"
        }
    }

    var ntfyOutgoingTopic: String {
        switch self {
        case .ufuk: return "tellal_duyuru_ufuk_yigit_u2y_7294"
        case .yigit: return "tellal_duyuru_ufuk_yigit_y2u_7294"
        case .cem: return "tellal_duyuru_ufuk_yigit_u2y_7294"
        }
    }

    static func from(id: String) -> UserProfile {
        UserProfile(rawValue: id) ?? .ufuk
    }

    static func from(name: String) -> UserProfile {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.contains("yiğit") || trimmed.contains("yigit") {
            return .yigit
        } else if trimmed.contains("cem") {
            return .cem
        } else {
            return .ufuk
        }
    }
}
