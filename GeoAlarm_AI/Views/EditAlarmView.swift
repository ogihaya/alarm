import SwiftUI
import CoreLocation

struct EditAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService

    let alarm: Alarm
    let onSave: (Alarm) -> Void
    let onDelete: (Alarm) -> Void

    @State private var name: String
    @State private var time: Date
    @State private var addressHint: String
    @State private var destination: CLLocationCoordinate2D
    @State private var enabled: Bool
    @State private var showingDeleteAlert = false
    @State private var nameValidationMessage: String?

    init(alarm: Alarm, onSave: @escaping (Alarm) -> Void, onDelete: @escaping (Alarm) -> Void) {
        self.alarm = alarm
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: alarm.name)
        _time = State(initialValue: alarm.time)
        _addressHint = State(initialValue: alarm.addressHint ?? "")
        _destination = State(initialValue: alarm.coordinate)
        _enabled = State(initialValue: alarm.enabled)
    }

    var body: some View {
        Form {
            Section("アラーム情報") {
                TextField("アラーム名", text: $name)
                    .onChange(of: name) { _ in nameValidationMessage = nil }
                DatePicker("時刻", selection: $time, displayedComponents: .hourAndMinute)
                Toggle("有効", isOn: $enabled)
                TextField("目的地メモ（任意）", text: $addressHint)
                if let message = nameValidationMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("目的地") {
                MapPickerView(coordinate: $destination)
                    .frame(height: 260)
                    .listRowInsets(EdgeInsets())

                statusRow
                Button {
                    if let current = locationService.lastLocation {
                        destination = current.coordinate
                    } else {
                        locationService.requestAuthorization()
                    }
                } label: {
                    Label("現在地を目的地に設定", systemImage: "location.fill")
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("このアラームを削除", systemImage: "trash")
                }
                .disabled(isOperationDenied)
            }
        }
        .navigationTitle("アラーム編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
                    .disabled(isOperationDenied)
            }
        }
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdates()
        }
        .onDisappear {
            locationService.stopUpdates()
        }
        .alert("削除の確認", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive, action: delete)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("目的地の半径\(Int(locationService.requiredRadius))m以内にいる場合のみ削除できます。")
        }
    }

    private var statusRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let distance = locationService.distance(to: destination) {
                Text("現在地からの距離: 約\(Int(distance))m")
                    .font(.subheadline)
                Text(isWithinRange ? "範囲内です。編集/削除が可能です。" : "範囲外です。目的地に近づいてください。")
                    .font(.footnote)
                    .foregroundStyle(isWithinRange ? .green : .red)
            } else {
                Text("現在地を取得中... 位置情報を許可してください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var isWithinRange: Bool {
        locationService.isWithinRange(of: destination) ?? false
    }

    private var isOperationDenied: Bool {
        !(locationService.isWithinRange(of: destination) ?? false)
    }

    private func save() {
        guard !isOperationDenied else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            nameValidationMessage = "アラーム名を入力してください"
            return
        }
        let updated = Alarm(
            id: alarm.id,
            name: trimmedName.isEmpty ? alarm.name : trimmedName,
            time: time,
            latitude: destination.latitude,
            longitude: destination.longitude,
            enabled: enabled,
            addressHint: addressHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : addressHint
        )
        onSave(updated)
        if updated.enabled {
            notificationService.schedule(alarm: updated)
        } else {
            notificationService.cancel(alarm: updated)
        }
        dismiss()
    }

    private func delete() {
        guard !isOperationDenied else { return }
        onDelete(alarm)
        notificationService.cancel(alarm: alarm)
        dismiss()
    }
}
