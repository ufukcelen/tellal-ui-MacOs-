//
//  UykusuzTosbaView.swift
//  Tellal
//

import SwiftUI

enum TosbaSubMenu: String, CaseIterable, Identifiable {
    case canliMac = "Canlı Maç Sohbetleri"
    case macSonu = "Maç Sonu"
    case haftalik = "Haftalık Program"
    case tekMac = "Tek Maçtan Yatanlar"
    case fcKariyer = "FC27 Kariyer"
    case ets2 = "Tosba Lojistik (ETS2)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .canliMac: return "sportscourt.fill"
        case .macSonu: return "flag.checkered"
        case .haftalik: return "calendar.badge.clock"
        case .tekMac: return "doc.text.magnifyingglass"
        case .fcKariyer: return "gamecontroller.fill"
        case .ets2: return "truck.box.fill"
        }
    }
}

struct UykusuzTosbaView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var selectedSubMenu: TosbaSubMenu = .canliMac

    // Canlı Maç & Maç Sonu Parametreleri
    @State private var homeTeam: String = "Galatasaray"
    @State private var awayTeam: String = "Fenerbahçe"
    @State private var selectedLeague: FootballLeague = .superLig
    @State private var broadcastTime: String = "21:00"
    @State private var isLiveBroadcast: Bool = true

    // FC Kariyer
    @State private var fcCareerTeam: String = "Feyenoord"

    // Tek Maç
    @State private var tmyTitle: String = "Kuponlar Masada"

    var body: some View {
        VStack(spacing: 0) {
            topSubMenuSelector

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedSubMenu {
                    case .canliMac:
                        matchAnnouncementSection(isMacSonu: false)
                    case .macSonu:
                        matchAnnouncementSection(isMacSonu: true)
                    case .haftalik:
                        haftalikProgramSection
                    case .tekMac:
                        tekMactanYatanlarSection
                    case .fcKariyer:
                        fcKariyerSection
                    case .ets2:
                        ets2Section
                    }
                }
                .padding(24)
            }
        }
    }

    private var topSubMenuSelector: some View {
        HStack {
            Image(systemName: "tv.fill")
                .font(.title2)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Uykusuz Tosba Duyuru Sistemi")
                    .font(.headline)
                Text("/uykusuztosba YouTube & Kick Duyuru ve Render Otomasyonu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("", selection: $selectedSubMenu) {
                ForEach(TosbaSubMenu.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon).tag(item)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 240)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Canlı Maç & Maç Sonu

    private func matchAnnouncementSection(isMacSonu: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(isMacSonu ? "Maç Sonu Duyuru & Render" : "Canlı Maç Sohbetleri Duyuru & Render")
                    .font(.title3.bold())
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ev Sahibi Takım")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("Ev Sahibi (örn: Galatasaray)", text: $homeTeam)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deplasman Takımı")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("Deplasman (örn: Fenerbahçe)", text: $awayTeam)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lig / Kupa")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Picker("", selection: $selectedLeague) {
                        ForEach(FootballLeague.allCases) { league in
                            Text(league.rawValue).tag(league)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Yayın Saati")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("SS:DD", text: $broadcastTime)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Format")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Toggle("Canlı Yayın", isOn: $isLiveBroadcast)
                        .padding(.top, 4)
                }
            }

            seoPreviewBox(isMacSonu: isMacSonu)

            HStack(spacing: 12) {
                Button {
                    saveYayinSaatiJson(isMacSonu: isMacSonu)
                } label: {
                    Label("JSON Kaydet", systemImage: "doc.badge.gearshape")
                }
                .buttonStyle(.bordered)

                Button {
                    copySeoText(isMacSonu: isMacSonu)
                } label: {
                    Label("SEO Metnini Kopyala", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveYayinSaatiJson(isMacSonu: isMacSonu)
                    let videoName = "\(homeTeam) - \(awayTeam) \(isMacSonu ? "Mac Sonu" : "Canli").mp4"
                    let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let outputPath = desktopUrl.appendingPathComponent(videoName).path

                    viewModel.startAfterEffectsRender(
                        projectPath: TellalConfig.shared.bfuAepURL.path,
                        composition: "mainsahne",
                        outputTemplate: "ygiido",
                        outputPath: outputPath
                    )
                    viewModel.selectedTab = .console
                } label: {
                    Label("After Effects Render Başlat", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    private func generateSeoText(isMacSonu: Bool) -> String {
        let durum = isMacSonu ? "maç sonrasında" : "maç esnasında"
        let evTag = homeTeam.replacingOccurrences(of: " ", with: "")
        let depTag = awayTeam.replacingOccurrences(of: " ", with: "")
        let ligTag = selectedLeague.rawValue.replacingOccurrences(of: " ", with: "")

        return """
        CANLI YAYINDAYIZ! \(homeTeam) - \(awayTeam) \(durum) sohbet edip pozisyonları tartışıyoruz. Yayın saati: \(broadcastTime)
        çayını kahveni hazırla chate gel! 👇

        #\(evTag) #\(depTag) #CanlıYayın #MaçSohbeti #\(ligTag)
        """
    }

    private func seoPreviewBox(isMacSonu: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YouTube / Kick SEO & Açıklama Metni Önizlemesi")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(generateSeoText(isMacSonu: isMacSonu))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
        }
    }

    private func copySeoText(isMacSonu: Bool) {
        let text = generateSeoText(isMacSonu: isMacSonu)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        viewModel.appendLog("SEO metni panoya kopyalandı", type: .success)
    }

    private func saveYayinSaatiJson(isMacSonu: Bool) {
        let jsonUrl = TellalConfig.shared.yayinSaatiJsonURL
        let baslik = "\(homeTeam) - \(awayTeam)"
        let dict: [String: String] = [
            "baslik": baslik,
            "saat": broadcastTime
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            try? data.write(to: jsonUrl)
            viewModel.appendLog("yayin_saati.json güncellendi: \(baslik) \(broadcastTime)", type: .success)
        }
    }

    // MARK: - Haftalık Futbol Programı

    private var haftalikProgramSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Haftalık Futbol Programı (Bermuda Futbol Üçgeni)")
                .font(.title3.bold())

            HStack {
                Text("Yayın Saati:")
                    .font(.subheadline)
                TextField("21:00", text: $broadcastTime)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }

            Text("""
            -Bermuda Futbol Üçgeni Canlı Yayın -
            Bu Akşam Saat \(broadcastTime)'de Tosba Youtube, Twitch ve Kick Kanalında.

            www.youtube.com/uykusuztosba
            www.kick.com/uykusuztosba
            www.twitch.com/uykusuztosba

            #futbol #gündem #canlıyayın #süperlig #futbolgündemi
            """)
            .font(.system(.caption, design: .monospaced))
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))

            HStack {
                Button("SEO Kopyala") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("Bermuda Futbol Üçgeni Saat \(broadcastTime)", forType: .string)
                    viewModel.appendLog("Haftalık program SEO metni kopyalandı", type: .success)
                }

                Spacer()

                Button {
                    let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let outputPath = desktopUrl.appendingPathComponent("Haftalik Futbol Programi.mp4").path

                    viewModel.startAfterEffectsRender(
                        projectPath: TellalConfig.shared.bfuAepURL.path,
                        composition: "mainsahne",
                        outputPath: outputPath
                    )
                    viewModel.selectedTab = .console
                } label: {
                    Label("Haftalık Program Render Başlat", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - Tek Maçtan Yatanlar

    private var tekMactanYatanlarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tek Maçtan Yatanlar")
                .font(.title3.bold())

            TextField("Bölüm / Başlık", text: $tmyTitle)
                .textFieldStyle(.roundedBorder)

            Button("tmy.json Güncelle") {
                let dict = ["baslik": tmyTitle]
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                    try? data.write(to: TellalConfig.shared.tekmacJsonURL)
                    viewModel.appendLog("tmy.json kaydedildi", type: .success)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - FC27 Kariyer

    private var fcKariyerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FC27 Kariyer Modu")
                .font(.title3.bold())

            HStack {
                Text("Kariyer Takımı:")
                TextField("Feyenoord", text: $fcCareerTeam)
                    .textFieldStyle(.roundedBorder)
            }

            Button("kariyer_takim.json Kaydet") {
                let dict = ["takim": fcCareerTeam]
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                    try? data.write(to: TellalConfig.shared.fcKariyerTakimJsonURL)
                    viewModel.appendLog("kariyer_takim.json kaydedildi: \(fcCareerTeam)", type: .success)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - ETS2

    private var ets2Section: some View {
        VStack(spacing: 12) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 40))
                .foregroundStyle(.cyan)
            Text("Tosba Lojistik (ETS2)")
                .font(.headline)
            Text("Bu modül yapım aşamasındadır. Çok yakında konvoy rotaları ve canlı yayın afişleriyle burada!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
