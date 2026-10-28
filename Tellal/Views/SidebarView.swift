//
//  SidebarView.swift
//  Tellal
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: TellalViewModel

    var body: some View {
        List(selection: $viewModel.selectedTab) {
            Section("Ana Menü") {
                NavigationLink(value: SidebarItem.dashboard) {
                    Label(SidebarItem.dashboard.rawValue, systemImage: SidebarItem.dashboard.icon)
                }

                NavigationLink(value: SidebarItem.schedule) {
                    HStack {
                        Label(SidebarItem.schedule.rawValue, systemImage: SidebarItem.schedule.icon)
                        Spacer()
                        if !viewModel.broadcasts.isEmpty {
                            Text("\(viewModel.broadcasts.count)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.2)))
                        }
                    }
                }

                NavigationLink(value: SidebarItem.chat) {
                    HStack {
                        Label(SidebarItem.chat.rawValue, systemImage: SidebarItem.chat.icon)
                        Spacer()
                        if !viewModel.chatMessages.isEmpty {
                            Text("\(viewModel.chatMessages.count)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.2)))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section("Duyuru Sistemleri") {
                NavigationLink(value: SidebarItem.uykusuzTosba) {
                    Label(SidebarItem.uykusuzTosba.rawValue, systemImage: SidebarItem.uykusuzTosba.icon)
                }

                NavigationLink(value: SidebarItem.radioMocas) {
                    Label(SidebarItem.radioMocas.rawValue, systemImage: SidebarItem.radioMocas.icon)
                }
            }

            Section("Sistem") {
                NavigationLink(value: SidebarItem.console) {
                    HStack {
                        Label(SidebarItem.console.rawValue, systemImage: SidebarItem.console.icon)
                        Spacer()
                        if viewModel.isProcessRunning {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }

                NavigationLink(value: SidebarItem.settings) {
                    Label(SidebarItem.settings.rawValue, systemImage: SidebarItem.settings.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            userProfileBar
        }
    }

    private var userProfileBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(viewModel.currentUser.avatarColor.gradient)
                        .frame(width: 32, height: 32)
                    Text(String(viewModel.currentUser.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentUser.displayName)
                        .font(.subheadline.bold())
                    Text("Aktif Kullanıcı")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    ForEach(UserProfile.allCases) { user in
                        Button {
                            viewModel.switchUser(to: user)
                        } label: {
                            HStack {
                                Text(user.displayName)
                                if user == viewModel.currentUser {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(.bar)
    }
}
