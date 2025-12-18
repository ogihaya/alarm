import SwiftUI
import MapKit

struct AlarmListView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var soundService: SoundService
    @State private var showingAddSheet = false
    @State private var stopTarget: Alarm?
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if store.alarms.isEmpty {
                    VStack(spacing: 12) {
                        headerStatus
                        ContentUnavailableView("アラームがありません", systemImage: "bell.slash", description: Text("右上の＋からアラームを追加してください"))
                    }
                    .padding(.horizontal)
                } else {
                    List {
                        Section {
                            headerStatus
                                .listRowInsets(EdgeInsets())
                        }
                        .listRowBackground(Color.clear)

                        ForEach(store.alarms) { alarm in
                            NavigationLink {
                                EditAlarmView(alarm: alarm) { updated in
                                    store.update(updated)
                                    if updated.enabled {
                                        notificationService.schedule(alarm: updated)
                                    } else {
                                        notificationService.cancel(alarm: updated)
                                    }
                                } onDelete: { toDelete in
                                    store.remove(toDelete)
                                    notificationService.cancel(alarm: toDelete)
                                }
                            } label: {
                                AlarmRowView(alarm: alarm) {
                                    store.toggleEnabled(for: alarm)
                                    if let updated = store.alarms.first(where: { $0.id == alarm.id }) {
                                        if updated.enabled {
                                            notificationService.schedule(alarm: updated)
                                        } else {
                                            notificationService.cancel(alarm: updated)
                                        }
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    attemptDelete(alarm)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                Button {
                                    stopTarget = alarm
                                } label: {
                                    Label("停止", systemImage: "stop.circle")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("アラーム一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAlarmView { alarm in
                store.add(alarm)
                notificationService.schedule(alarm: alarm)
            }
            .environmentObject(locationService)
            .environmentObject(notificationService)
        }
        .sheet(item: $stopTarget) { alarm in
            NavigationStack {
                AlarmStopView(alarm: alarm) { stopped in
                    // 停止後は無効化しておく
                    if let idx = store.alarms.firstIndex(of: stopped) {
                        var updated = stopped
                        updated.enabled = false
                        store.update(updated)
                        notificationService.cancel(alarm: updated)
                    }
                }
            }
            .environmentObject(locationService)
            .environmentObject(soundService)
            .environmentObject(notificationService)
        }
        .alert("位置情報が必要です", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdates()
            notificationService.requestAuthorization()
            notificationService.reschedule(alarms: store.alarms)
        }
        .onDisappear {
            locationService.stopUpdates()
        }
    }

    private func attemptDelete(_ alarm: Alarm) {
        guard let withinRange = locationService.isWithinRange(of: alarm.coordinate) else {
            alertMessage = "現在地を取得できません。位置情報を許可してください。"
            return
        }
        guard withinRange else {
            alertMessage = "この場所に到着していないため、削除できません。"
            return
        }
        store.remove(alarm)
        notificationService.cancel(alarm: alarm)
    }

    @ViewBuilder
    private var headerStatus: some View {
        VStack(spacing: 12) {
            InfoBanner(
                style: locationService.isDenied ? .warning : .info,
                title: "位置情報",
                message: locationService.statusDescription,
                actionTitle: locationService.isDenied ? "設定で許可を確認" : nil,
                action: locationService.isDenied ? { locationService.requestAuthorization() } : nil
            )

            if !notificationService.authorizationGranted {
                InfoBanner(
                    style: .warning,
                    title: "通知が無効です",
                    message: "アラームを鳴らすには通知を許可してください。",
                    actionTitle: "通知を許可",
                    action: { notificationService.requestAuthorization() }
                )
            } else {
                InfoBanner(
                    style: .success,
                    title: "通知は有効です",
                    message: "設定した時刻に通知を鳴らします。"
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AlarmRowView: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.name)
                        .font(.headline)
                    Text(alarm.timeLabel)
                        .font(.title2)
                        .bold()
                }
                Spacer()
                Toggle(isOn: Binding(get: { alarm.enabled }, set: { _ in onToggle() })) {
                    Text(alarm.enabled ? "有効" : "無効")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .labelsHidden()
            }

            if let address = alarm.addressHint, !address.isEmpty {
                Label(address, systemImage: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Map {
                Marker(alarm.name, coordinate: alarm.coordinate)
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 6)
    }
}
