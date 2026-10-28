//
//  ConsoleLogView.swift
//  Tellal
//

import SwiftUI

struct ConsoleLogView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var filterMode: LogFilter = .all

    enum LogFilter: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case progress = "İlerleme"
        case warnings = "Uyarılar"
        case errors = "Hatalar"

        var id: String { rawValue }
    }

    var filteredLogs: [LogEntry] {
        switch filterMode {
        case .all:
            return viewModel.logs
        case .progress:
            return viewModel.logs.filter { $0.type == .progress }
        case .warnings:
            return viewModel.logs.filter { $0.type == .warning }
        case .errors:
            return viewModel.logs.filter { $0.type == .error }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            logTerminalView
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Terminal & Render Logları")
                            .font(.headline)
                        if viewModel.isProcessRunning {
                            ProgressView()
                                .controlSize(.small)
                            Text("Çalışıyor")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
                        } else {
                            Circle()
                                .fill(.secondary)
                                .frame(width: 8, height: 8)
                            Text("Boşta")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Python motoru ve After Effects render ilerleme akışı")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Picker("", selection: $filterMode) {
                ForEach(LogFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)

            if viewModel.isProcessRunning {
                Button("İşlemi Durdur") {
                    viewModel.stopActiveProcess()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

            Button {
                viewModel.clearLogs()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Logları Temizle")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var logTerminalView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if viewModel.logs.isEmpty {
                        Text("Henüz bir işlem çıktısı veya log kaydı yok.")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        ForEach(filteredLogs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.timestamp, style: .time)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.gray.opacity(0.8))

                                Text(log.message)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(colorForLog(log.type))
                                    .textSelection(.enabled)

                                Spacer()
                            }
                            .id(log.id)
                        }
                    }
                }
                .padding(14)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .onChange(of: viewModel.logs.count) {
                if let lastLog = viewModel.logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func colorForLog(_ type: LogEntry.LogType) -> Color {
        switch type {
        case .standard: return .white
        case .progress: return .cyan
        case .warning: return .yellow
        case .error: return .red
        case .success: return .green
        }
    }
}
