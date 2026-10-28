//
//  SettingsView.swift
//  Tellal
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var customCliPath: String = TellalConfig.shared.cliDirectory.path
    @State private var isTestingFirebase: Bool = false
    @State private var firebaseStatusMessage: String?
    @State private var isFirebaseOk: Bool?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView

                userProfileSection

                cliPathSection

                servicesStatusSection

                aboutSection
            }
            .padding(24)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ayarlar & Ekip Yapılandırması")
                .font(.title2.bold())
            Text("Kullanıcı kimliği, dosya dizinleri ve bulut servis bağlantıları")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Kullanıcı Kimliği

    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Aktif Kullanıcı Kimliği")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(UserProfile.allCases) { user in
                    let isSelected = user == viewModel.currentUser

                    Button {
                        viewModel.switchUser(to: user)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(user.avatarColor.gradient)
                                    .frame(width: 36, height: 36)
                                Text(String(user.displayName.prefix(1)))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.subheadline.bold())
                                Text(isSelected ? "Seçili Kullanıcı" : "Geçiş Yap")
                                    .font(.caption2)
                                    .foregroundStyle(isSelected ? user.avatarColor : .secondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(user.avatarColor)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? user.avatarColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? user.avatarColor : Color.clear, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - CLI Dizin Yolu

    private var cliPathSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TellalCLI Dizin Yolu")
                .font(.headline)

            Text("Otomasyon şablonları, takvim.txt ve After Effects projelerinin bulunduğu klasör:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("TellalCLI Yolu", text: $customCliPath)
                    .textFieldStyle(.roundedBorder)

                Button("Klasör Seç...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        customCliPath = url.path
                        TellalConfig.shared.setCustomCliDirectory(url.path)
                        viewModel.loadLocalData()
                    }
                }

                Button("Varsayılana Sıfırla") {
                    UserDefaults.standard.removeObject(forKey: "tellal_cli_custom_directory_path")
                    customCliPath = TellalConfig.shared.cliDirectory.path
                    viewModel.loadLocalData()
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - Servis Durumları

    private var servicesStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Bağlantı & Servis Durumu")
                    .font(.headline)
                Spacer()
                Button("Bağlantıyı Test Et") {
                    testFirebaseConnection()
                }
                .disabled(isTestingFirebase)
            }

            VStack(spacing: 10) {
                StatusRow(
                    name: "Firebase Realtime Database",
                    detail: "tellal-otomasyon-default-rtdb (Europe-West1)",
                    isOk: isFirebaseOk ?? true
                )

                StatusRow(
                    name: "Ntfy Anlık Bildirim Kanalı",
                    detail: "ntfy.sh/\(TellalConfig.ntfyChatTopic)",
                    isOk: true
                )

                let aeFound = FileManager.default.fileExists(atPath: TellalConfig.shared.aerenderPath)
                StatusRow(
                    name: "Adobe After Effects aerender",
                    detail: aeFound ? TellalConfig.shared.aerenderPath : "aerender bulunamadı",
                    isOk: aeFound
                )

                let pyScriptFound = FileManager.default.fileExists(atPath: TellalConfig.shared.tellalPythonScriptURL.path)
                StatusRow(
                    name: "Tellal Python Motoru",
                    detail: pyScriptFound ? TellalConfig.shared.tellalPythonScriptURL.path : "tellal.py bulunamadı",
                    isOk: pyScriptFound
                )
            }

            if let message = firebaseStatusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(isFirebaseOk == true ? .green : .red)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    private func testFirebaseConnection() {
        isTestingFirebase = true
        firebaseStatusMessage = "Bağlantı kontrol ediliyor..."
        Task {
            do {
                _ = try await FirebaseService.shared.fetchCalendar()
                isFirebaseOk = true
                firebaseStatusMessage = "Firebase veritabanı ile bağlantı başarılı!"
            } catch {
                isFirebaseOk = false
                firebaseStatusMessage = "Bağlantı hatası: \(error.localizedDescription)"
            }
            isTestingFirebase = false
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tellal macOS")
                .font(.headline)
            Text("Sürüm: \(TellalConfig.currentVersion) • Uykusuz Tosba & Radio Mocas Duyuru ve Yayın Otomasyonu")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Geliştirici: Ufuk Çelen & Yiğit Kızılel")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
}

struct StatusRow: View {
    let name: String
    let detail: String
    let isOk: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isOk ? Color.green : Color.red)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(isOk ? "Bağlı / Aktif" : "Ulaşılamadı")
                .font(.caption.bold())
                .foregroundStyle(isOk ? .green : .red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor).opacity(0.5)))
    }
}
