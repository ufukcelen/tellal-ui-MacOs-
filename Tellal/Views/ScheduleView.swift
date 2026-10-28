//
//  ScheduleView.swift
//  Tellal
//

import SwiftUI

struct ScheduleView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all
    @State private var itemToDelete: BroadcastItem? = nil

    enum FilterMode: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case pending = "Bekleyenler"
        case completed = "Duyuruldu"
        case cancelled = "İptal Edilenler"

        var id: String { rawValue }
    }

    var filteredBroadcasts: [BroadcastItem] {
        viewModel.broadcasts.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.dateDay.localizedCaseInsensitiveContains(searchText) ||
                (item.info?.localizedCaseInsensitiveContains(searchText) ?? false)

            switch filterMode {
            case .all:
                return matchesSearch
            case .pending:
                return matchesSearch && !item.isCompleted && !item.isCancelled
            case .completed:
                return matchesSearch && item.isCompleted
            case .cancelled:
                return matchesSearch && item.isCancelled
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            if filteredBroadcasts.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredBroadcasts) { item in
                        BroadcastRow(item: item, viewModel: viewModel, onDelete: {
                            itemToDelete = item
                        })
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBroadcastSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Yayını Sil",
            isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                if let item = itemToDelete {
                    viewModel.deleteBroadcast(item: item)
                }
                itemToDelete = nil
            }
            Button("Vazgeç", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            if let item = itemToDelete {
                Text("'\(item.title)' yayınını takvimden ve buluttan kalıcı olarak silmek istediğinizden emin misiniz?")
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yayın Takvimi")
                        .font(.title2.bold())
                    Text("Canlı yayın planları, duyuru durumları ve bulut eşitlemesi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.syncCalendar()
                    }
                } label: {
                    Label("Bulut Eşitle", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isSyncingCalendar)

                Button {
                    viewModel.syncGoogleCalendarViaPython()
                } label: {
                    Label("Google Takvim", systemImage: "calendar.badge.exclamationmark")
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Yayın Ekle", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Yayın veya gün ara...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))

                Picker("Filtre", selection: $filterMode) {
                    ForEach(FilterMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
            }
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "Planlanmış yayın bulunmuyor" : "Aramaya uygun yayın bulunamadı")
                .font(.headline)
            Text("Yeni bir yayın eklemek için sağ üstteki 'Yayın Ekle' butonuna basabilirsiniz.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showingAddSheet = true
            } label: {
                Label("Yeni Yayın Ekle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct BroadcastRow: View {
    let item: BroadcastItem
    @ObservedObject var viewModel: TellalViewModel
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.isCancelled ? Color.red.opacity(0.15) : (item.isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.15)))
                    .frame(width: 34, height: 34)
                Text("\(item.index)")
                    .font(.subheadline.bold())
                    .foregroundStyle(item.isCancelled ? Color.red : (item.isCompleted ? Color.green : Color.blue))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCancelled, color: .secondary)

                    if item.isCompleted {
                        Label("Duyuruldu", systemImage: "checkmark.seal.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    } else if item.isCancelled {
                        Label("İptal", systemImage: "xmark.seal.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.15)))
                    }
                }

                HStack(spacing: 16) {
                    Label(item.dateDay, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(item.time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let info = item.info, !info.isEmpty {
                        Label(info, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    viewModel.toggleCompleted(item: item)
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help(item.isCompleted ? "Duyuruyu Beklemeye Al" : "Duyurular Yapıldı İşaretle")

                Button {
                    viewModel.cancelBroadcast(item: item)
                } label: {
                    Image(systemName: item.isCancelled ? "xmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(item.isCancelled ? .red : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help(item.isCancelled ? "İptali Kaldır" : "Yayını İptal Et")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Yayını Sil")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct AddBroadcastSheet: View {
    @ObservedObject var viewModel: TellalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProgram: StandardProgram = .canliMacSohbetleri
    @State private var isCustomTitle: Bool = false
    @State private var customTitleText: String = ""
    @State private var selectedDayOption: String = "Bugün"
    @State private var customDayText: String = ""
    @State private var timeText: String = "21:00"
    @State private var infoText: String = ""

    private var dynamicDays: [(label: String, value: String)] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM (EEEE)"

        let shortDayFormatter = DateFormatter()
        shortDayFormatter.locale = Locale(identifier: "tr_TR")
        shortDayFormatter.dateFormat = "EEEE"

        var result: [(label: String, value: String)] = []
        let calendar = Calendar.current
        let today = Date()

        let todayName = shortDayFormatter.string(from: today)
        result.append(("Bugün (\(todayName))", "Bugün (\(todayName))"))

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            let tomorrowName = shortDayFormatter.string(from: tomorrow)
            result.append(("Yarın (\(tomorrowName))", "\(tomorrowName)"))
        }

        for i in 2..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let formatted = formatter.string(from: date)
                let dayName = shortDayFormatter.string(from: date)
                result.append(("\(formatted)", "\(dayName)"))
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Yeni Yayın Planla")
                    .font(.headline)
                Spacer()
                Button("Kapat") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            Form {
                Section("Yayın Bilgisi") {
                    Toggle("Özel Yayın Adı Gir", isOn: $isCustomTitle)

                    if isCustomTitle {
                        TextField("Yayın Adı", text: $customTitleText)
                    } else {
                        Picker("Program", selection: $selectedProgram) {
                            ForEach(StandardProgram.allCases) { prog in
                                Label(prog.rawValue, systemImage: prog.iconName).tag(prog)
                            }
                        }
                    }
                }

                Section("Zamanlama") {
                    Picker("Yayın Günü", selection: $selectedDayOption) {
                        ForEach(dynamicDays, id: \.value) { item in
                            Text(item.label).tag(item.value)
                        }
                        Text("Diğer / Özel Gün").tag("Özel")
                    }

                    if selectedDayOption == "Özel" {
                        TextField("Örn: 29 Ekim (Perşembe)", text: $customDayText)
                    }

                    HStack {
                        TextField("Saat (SS:DD)", text: $timeText)
                            .frame(width: 120)

                        HStack(spacing: 6) {
                            quickTimeButton("20:00")
                            quickTimeButton("21:00")
                            quickTimeButton("21:30")
                            quickTimeButton("22:00")
                            quickTimeButton("22:30")
                        }
                    }
                }

                Section("Ek Not / Açıklama") {
                    TextField("İsteğe bağlı not ekleyin (örn: Konuk: Cem)", text: $infoText)
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                Spacer()
                Button("Vazgeç") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Yayını Ekle") {
                    let finalTitle = isCustomTitle ? customTitleText.trimmingCharacters(in: .whitespaces) : selectedProgram.rawValue
                    let finalDay = selectedDayOption == "Özel" ? customDayText.trimmingCharacters(in: .whitespaces) : selectedDayOption
                    let finalTime = timeText.trimmingCharacters(in: .whitespaces)
                    let finalInfo = infoText.trimmingCharacters(in: .whitespaces)

                    guard !finalTitle.isEmpty else { return }

                    viewModel.addBroadcast(
                        title: finalTitle,
                        day: finalDay.isEmpty ? "Bugün" : finalDay,
                        time: finalTime.isEmpty ? "21:00" : finalTime,
                        info: finalInfo.isEmpty ? nil : finalInfo
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 480, height: 440)
    }

    private func quickTimeButton(_ time: String) -> some View {
        Button(time) {
            timeText = time
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.secondary.opacity(0.15)))
    }
}
