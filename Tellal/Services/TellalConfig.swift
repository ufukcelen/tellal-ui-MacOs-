//
//  TellalConfig.swift
//  Tellal
//

import Foundation

final class TellalConfig {
    static let shared = TellalConfig()

    static let currentVersion = "0.0.1"
    static let firebaseDatabaseURL = "https://tellal-otomasyon-default-rtdb.europe-west1.firebasedatabase.app/tellal_db"
    static let ntfyCalendarTopic = "tellal_takvim_sync_u_y_8832"
    static let ntfyChatTopic = "tellal_chat_sync_u_y_8832"

    private let userDefaultsCliKey = "tellal_cli_custom_directory_path"

    var cliDirectory: URL {
        if let customPath = UserDefaults.standard.string(forKey: userDefaultsCliKey),
           FileManager.default.fileExists(atPath: customPath) {
            return URL(fileURLWithPath: customPath)
        }

        // Otomatik arama mantığı
        let fileManager = FileManager.default

        // 1. Çalışma alanı içi ./TellalCLI
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let candidate1 = currentDir.appendingPathComponent("TellalCLI")
        if fileManager.fileExists(atPath: candidate1.path) {
            return candidate1
        }

        // 2. Üst dizin ../TellalCLI
        let candidate2 = currentDir.deletingLastPathComponent().appendingPathComponent("TellalCLI")
        if fileManager.fileExists(atPath: candidate2.path) {
            return candidate2
        }

        // 3. Bilinen sabit geliştirici yolları
        let candidate3 = URL(fileURLWithPath: "/Users/ufukcelen/Desktop/Dev/Tellal Arayüz/Tellal Arayüz/Tellal/TellalCLI")
        if fileManager.fileExists(atPath: candidate3.path) {
            return candidate3
        }

        let candidate4 = URL(fileURLWithPath: "/Users/ufukcelen/Desktop/Dev/Tellal Arayüz/Tellal Arayüz/TellalCLI")
        if fileManager.fileExists(atPath: candidate4.path) {
            return candidate4
        }

        return candidate1
    }

    func setCustomCliDirectory(_ path: String) {
        UserDefaults.standard.set(path, forKey: userDefaultsCliKey)
    }

    var calendarFileURL: URL {
        cliDirectory.appendingPathComponent("takvim.txt")
    }

    var chatFileURL: URL {
        cliDirectory.appendingPathComponent("chat.txt")
    }

    var userFileURL: URL {
        cliDirectory.appendingPathComponent("user.txt")
    }

    var tellalPythonScriptURL: URL {
        cliDirectory.appendingPathComponent("tellal.py")
    }

    var bfuAssetsDirectory: URL {
        cliDirectory.appendingPathComponent("Bfü Duyuru Projesi/Assets")
    }

    var bfuAepURL: URL {
        cliDirectory.appendingPathComponent("Bfü Duyuru Projesi/bfuDuyuru2027.aep")
    }

    var albertDirectory: URL {
        cliDirectory.appendingPathComponent("Albert")
    }

    var albertJsonURL: URL {
        albertDirectory.appendingPathComponent("albert.json")
    }

    var albertAepURL: URL {
        albertDirectory.appendingPathComponent("albert.aep")
    }

    var yayinSaatiJsonURL: URL {
        bfuAssetsDirectory.appendingPathComponent("yayin_saati.json")
    }

    var fcKariyerTakimJsonURL: URL {
        cliDirectory.appendingPathComponent("FC Kariyer Duyuru/kariyer_takim.json")
    }

    var memleketYayinSaatiJsonURL: URL {
        cliDirectory.appendingPathComponent("Memleket Duyuru/mem_yayin_saati.json")
    }

    var tekmacJsonURL: URL {
        cliDirectory.appendingPathComponent("Tekmaç/Assets/tmy.json")
    }

    var soundDoneURL: URL {
        cliDirectory.appendingPathComponent("aeDone.mp3")
    }

    var aerenderPath: String {
        let defaultPath = "/Applications/Adobe After Effects 2026/aerender"
        if FileManager.default.fileExists(atPath: defaultPath) {
            return defaultPath
        }

        let possibleVersions = ["2026", "2025", "2024", "2023", "2022", "CC"]
        for version in possibleVersions {
            let path = "/Applications/Adobe After Effects \(version)/aerender"
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return defaultPath
    }
}
