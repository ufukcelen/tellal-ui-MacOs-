//
//  RadioMocasView.swift
//  Tellal
//

import SwiftUI

enum MocasSubMenu: String, CaseIterable, Identifiable {
    case filtresizMemleket = "Filtresiz Memleket Havası"
    case albertVeCem = "Albert ve Cem"
    case mocasBey = "Mocas Bey ve Radyosu"
    case aklimdakiFilmler = "Aklımdaki Filmler"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .filtresizMemleket: return "mic.fill"
        case .albertVeCem: return "sparkles.tv.fill"
        case .mocasBey: return "radio.fill"
        case .aklimdakiFilmler: return "film.fill"
        }
    }
}

struct RadioMocasView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var selectedSubMenu: MocasSubMenu = .filtresizMemleket

    // Filtresiz Memleket
    @State private var memleketTime: String = "22:00"

    // Albert ve Cem
    @State private var albertTitle: String = "BU AKŞAM"
    @State private var albertTime: String = "22:00"

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedSubMenu {
                    case .filtresizMemleket:
                        filtresizMemleketSection
                    case .albertVeCem:
                        albertVeCemSection
                    case .mocasBey:
                        underConstructionSection(title: "Mocas Bey ve Radyosu", icon: "radio.fill")
                    case .aklimdakiFilmler:
                        underConstructionSection(title: "Aklımdaki Filmler", icon: "film.fill")
                    }
                }
                .padding(24)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "radio.fill")
                .font(.title2)
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Radio Mocas Duyuru Sistemi")
                    .font(.headline)
                Text("/radiomocas Canlı Yayın & Podcast Otomasyonları")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("", selection: $selectedSubMenu) {
                ForEach(MocasSubMenu.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon).tag(item)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 250)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Filtresiz Memleket Havası

    private var filtresizMemleketSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Filtresiz Memleket Havası Duyuru & Render")
                .font(.title3.bold())

            HStack {
                Text("Yayın Saati:")
                    .font(.subheadline.bold())
                TextField("22:00", text: $memleketTime)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SEO Metni Önizlemesi")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("""
                “Yok artık!” dedirten anları, sokağın filtresiz gerçekleri... Cem ve Burhan’la kaos, kahkaha ve dram başlıyor! 🇹🇷🎭

                “Bu olsa olsa ancak bizim memlekette olur” dediğimiz ne varsa, bu akşam \(memleketTime) YouTube, Kick ve Twitch ortak yayınında masada!

                youtube.com/radiomocas
                kick.com/uykusuztosba
                twitch.com/radiomocas

                #FiltresizMemleketHavası #kaos #sohbet #mizah #CanlıYayın
                """)
                .font(.system(.caption, design: .monospaced))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
            }

            HStack(spacing: 12) {
                Button("SEO Kopyala") {
                    let text = """
                    “Yok artık!” dedirten anları, sokağın filtresiz gerçekleri... Cem ve Burhan’la kaos, kahkaha ve dram başlıyor! 🇹🇷🎭
                    Bu akşam \(memleketTime) YouTube, Kick ve Twitch ortak yayınında masada!
                    """
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    viewModel.appendLog("Memleket Havası SEO kopyalandı", type: .success)
                }

                Button("JSON Kaydet") {
                    let dict = ["baslik": "BU AKŞAM", "saat": memleketTime]
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                        try? data.write(to: TellalConfig.shared.memleketYayinSaatiJsonURL)
                        viewModel.appendLog("mem_yayin_saati.json güncellendi: \(memleketTime)", type: .success)
                    }
                }

                Spacer()

                Button {
                    let dict = ["baslik": "BU AKŞAM", "saat": memleketTime]
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                        try? data.write(to: TellalConfig.shared.memleketYayinSaatiJsonURL)
                    }

                    let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let outputPath = desktopUrl.appendingPathComponent("Filtresiz Memleket Havasi.mp4").path

                    let memAep = TellalConfig.shared.cliDirectory.appendingPathComponent("Memleket Duyuru/Assets/memleket.aep")
                    viewModel.startAfterEffectsRender(
                        projectPath: memAep.path,
                        composition: "mainsahne",
                        outputPath: outputPath
                    )
                    viewModel.selectedTab = .console
                } label: {
                    Label("Render Başlat", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    // MARK: - Albert ve Cem

    private var albertVeCemSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Albert ve Cem Canlı Yayın Otomasyonu")
                .font(.title3.bold())

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Başlık Metni")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("BU AKŞAM", text: $albertTitle)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Yayın Saati")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("22:00", text: $albertTime)
                        .textFieldStyle(.roundedBorder)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("albert.json İçeriği:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("""
                {
                  "baslik": "\(albertTitle)",
                  "saat": "\(albertTime)"
                }
                """)
                .font(.system(.caption, design: .monospaced))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
            }

            HStack(spacing: 12) {
                Button("albert.json Kaydet") {
                    saveAlbertJson()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveAlbertJson()

                    let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let outputPath = desktopUrl.appendingPathComponent("Albert ve Cem \(albertTime).mp4").path

                    viewModel.startAfterEffectsRender(
                        projectPath: TellalConfig.shared.albertAepURL.path,
                        composition: "albertSahne",
                        outputPath: outputPath
                    )
                    viewModel.selectedTab = .console
                } label: {
                    Label("Albert Render Başlat", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }

    private func saveAlbertJson() {
        let dict = ["baslik": albertTitle, "saat": albertTime]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            try? data.write(to: TellalConfig.shared.albertJsonURL)
            viewModel.appendLog("albert.json güncellendi: \(albertTitle) \(albertTime)", type: .success)
        }
    }

    private func underConstructionSection(title: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.purple)
            Text(title)
                .font(.headline)
            Text("Bu program formatı yapım aşamasındadır.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
