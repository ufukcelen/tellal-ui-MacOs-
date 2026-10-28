//
//  DashboardView.swift
//  Tellal
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: TellalViewModel
    @State private var showingAddBroadcastSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBanner

                statsGrid

                if let nextItem = nextUpcomingBroadcast {
                    nextBroadcastHero(item: nextItem)
                }

                quickActionsSection

                recentChatSection
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAddBroadcastSheet) {
            AddBroadcastSheet(viewModel: viewModel)
        }
    }

    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Tellal")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("v\(TellalConfig.currentVersion)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .foregroundStyle(.orange)
                }

                HStack(spacing: 12) {
                    Label("/uykusuztosba", systemImage: "tv.fill")
                        .font(.subheadline)
                        .foregroundStyle(.cyan)
                    Label("/radiomocas", systemImage: "radio.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
            }

            Spacer()

            Button {
                Task {
                    await viewModel.syncAll()
                }
            } label: {
                Label("Tümünü Eşitle", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSyncingCalendar || viewModel.isSyncingChat)
        }
        .padding(.bottom, 8)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(
                title: "Gelecek Yayınlar",
                value: "\(viewModel.broadcasts.count)",
                icon: "calendar",
                color: .blue
            )
            StatCard(
                title: "Duyurulanlar",
                value: "\(viewModel.broadcasts.filter { $0.isCompleted }.count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatCard(
                title: "İptal Edilenler",
                value: "\(viewModel.broadcasts.filter { $0.isCancelled }.count)",
                icon: "xmark.circle.fill",
                color: .red
            )
            StatCard(
                title: "Sohbet Mesajı",
                value: "\(viewModel.chatMessages.count)",
                icon: "bubble.left.and.bubble.right.fill",
                color: .purple
            )
        }
    }

    private var nextUpcomingBroadcast: BroadcastItem? {
        viewModel.broadcasts.first(where: { !$0.isCancelled })
    }

    private func nextBroadcastHero(item: BroadcastItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sıradaki Canlı Yayın", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
                    .textCase(.uppercase)

                Spacer()

                if item.isCompleted {
                    Text("✅ DUYURULAR YAPILDI")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                } else {
                    Text("⏳ BEKLEMEDE")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
            }

            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.gradient)
                        .frame(width: 54, height: 54)
                    Image(systemName: "play.tv.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title3.bold())

                    HStack(spacing: 16) {
                        Label(item.dateDay, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label(item.time, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let info = item.info, !info.isEmpty {
                        Text("Not: \(info)")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                Button {
                    viewModel.toggleCompleted(item: item)
                } label: {
                    Label(item.isCompleted ? "Geri Al" : "Duyuruldu Yap", systemImage: "checkmark")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı İşlemler")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Yeni Yayın Ekle",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddBroadcastSheet = true
                }

                QuickActionButton(
                    title: "Google Calendar Eşitle",
                    icon: "arrow.triangle.swap",
                    color: .green
                ) {
                    viewModel.syncGoogleCalendarViaPython()
                }

                QuickActionButton(
                    title: "Uykusuz Tosba Menüsü",
                    icon: "sportscourt.fill",
                    color: .cyan
                ) {
                    viewModel.selectedTab = .uykusuzTosba
                }

                QuickActionButton(
                    title: "Radio Mocas Menüsü",
                    icon: "mic.fill",
                    color: .purple
                ) {
                    viewModel.selectedTab = .radioMocas
                }
            }
        }
    }

    private var recentChatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son Ekip Mesajları")
                    .font(.headline)
                Spacer()
                Button("Tümünü Gör") {
                    viewModel.selectedTab = .chat
                }
                .font(.caption)
            }

            VStack(spacing: 8) {
                if viewModel.chatMessages.isEmpty {
                    Text("Henüz sohbet mesajı yok.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(viewModel.chatMessages.suffix(4)) { msg in
                        HStack(alignment: .top, spacing: 10) {
                            Text(msg.senderName)
                                .font(.caption.bold())
                                .foregroundStyle(UserProfile.from(name: msg.senderName).avatarColor)
                                .frame(width: 80, alignment: .leading)

                            Text(msg.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}
