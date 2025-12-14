import SwiftUI
import CoreLocation

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService
    @State private var name: String = ""
    @State private var time: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var addressHint: String = ""
    @State private var destination = CLLocationCoordinate2D(latitude: 35.6809591, longitude: 139.7673068)
    @State private var nameValidationMessage: String?

    let onSave: (Alarm) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("アラーム情報") {
                    TextField("アラーム名", text: $name)
                        .onChange(of: name) { _ in nameValidationMessage = nil }
                    if let message = nameValidationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    DatePicker("時刻", selection: $time, displayedComponents: .hourAndMinute)
                    TextField("目的地メモ（任意）", text: $addressHint)
                }

                Section("目的地") {
                    MapPickerView(coordinate: $destination)
                        .frame(height: 280)
                        .listRowInsets(EdgeInsets())
                    locationStatus
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
            }
            .navigationTitle("アラームを追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdates()
            if let current = locationService.lastLocation {
                destination = current.coordinate
            }
        }
        .onDisappear {
            locationService.stopUpdates()
        }
    }

    private var locationStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(locationService.statusDescription)
                .font(.subheadline)
                .foregroundStyle(locationService.isDenied ? .red : .secondary)
            if let error = locationService.lastError {
                Text("位置情報の取得に失敗: \(error)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            nameValidationMessage = "アラーム名を入力してください"
            return
        }
        let hint = addressHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let alarm = Alarm(
            name: trimmedName.isEmpty ? "新しいアラーム" : trimmedName,
            time: time,
            latitude: destination.latitude,
            longitude: destination.longitude,
            enabled: true,
            addressHint: hint.isEmpty ? nil : hint
        )
        onSave(alarm)
        notificationService.schedule(alarm: alarm)
        dismiss()
    }
}
