import SwiftUI
import CoreLocation

struct AlarmStopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var soundService: SoundService
    @EnvironmentObject private var notificationService: NotificationService

    let alarm: Alarm
    let onStopped: (Alarm) -> Void

    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(alarm.name)
                    .font(.title)
                    .bold()
                Text(alarm.timeLabel)
                    .font(.title3)
                if let address = alarm.addressHint {
                    Label(address, systemImage: "mappin")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                if let distance = locationService.distance(to: alarm.coordinate) {
                    Text("目的地まで約\(Int(distance))m")
                        .font(.headline)
                    Text(isWithinRange ? "停止可能: 半径\(Int(locationService.requiredRadius))m以内です" : "停止不可: 目的地に近づいてください")
                        .foregroundStyle(isWithinRange ? .green : .red)
                        .font(.subheadline)
                } else {
                    Text("現在地を取得中... 位置情報を許可してください")
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                stopAlarm()
            } label: {
                Label("アラームを停止", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isWithinRange ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!isWithinRange)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("アラーム停止")
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdates()
            soundService.startLoop()
        }
        .onDisappear {
            locationService.stopUpdates()
            soundService.stop()
        }
    }

    private var isWithinRange: Bool {
        locationService.isWithinRange(of: alarm.coordinate) ?? false
    }

    private func stopAlarm() {
        guard isWithinRange else {
            statusMessage = "この場所に到着していないため、アラームを停止できません"
            return
        }
        onStopped(alarm)
        soundService.stop()
        notificationService.cancel(alarm: alarm)
        statusMessage = "アラームを停止しました"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
