import Foundation
import UserNotifications

/// アラームのローカル通知を扱うシンプルなスケジューラ
final class NotificationService: ObservableObject {
    @Published var authorizationGranted = false

    init() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.authorizationGranted = granted
            }
        }
    }

    func schedule(alarm: Alarm) {
        guard authorizationGranted else { return }
        let content = UNMutableNotificationContent()
        content.title = alarm.name
        content.body = "目的地に到着したら停止してください"
        content.sound = UNNotificationSound.default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: alarm.notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知の登録に失敗: \(error.localizedDescription)")
            }
        }
    }

    func cancel(alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.notificationIdentifier])
    }

    func reschedule(alarms: [Alarm]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for alarm in alarms where alarm.enabled {
            schedule(alarm: alarm)
        }
    }
}
