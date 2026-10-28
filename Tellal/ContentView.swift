//
//  ContentView.swift
//  Tellal
//
//  Created by Ufuk Celen on 28.10.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TellalViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            Group {
                switch viewModel.selectedTab {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .schedule:
                    ScheduleView(viewModel: viewModel)
                case .chat:
                    ChatView(viewModel: viewModel)
                case .uykusuzTosba:
                    UykusuzTosbaView(viewModel: viewModel)
                case .radioMocas:
                    RadioMocasView(viewModel: viewModel)
                case .console:
                    ConsoleLogView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 680, minHeight: 520)
        }
        .frame(minWidth: 920, minHeight: 620)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text(viewModel.selectedTab.rawValue)
                    .font(.headline)
            }

            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    if viewModel.isProcessRunning {
                        Button {
                            viewModel.selectedTab = .console
                        } label: {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Render / İşlem Aktif")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task {
                            await viewModel.syncAll()
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isSyncingCalendar || viewModel.isSyncingChat)
                    .help("Takvim ve Sohbeti Eşitle")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
