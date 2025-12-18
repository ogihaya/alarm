import Foundation
import Combine
import UserNotifications

/// アラームのローカル通知を扱うシンプルなスケジューラ
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var authorizationGranted = false
    @Published var pendingAlarmId: UUID?
    
    // 通知から起動したアラームIDを保持するためのコールバック
    var onNotificationReceived: ((UUID) -> Void)?
    
    // アラーム情報を取得するためのコールバック（次の通知をスケジュールするために使用）
    var getAlarmById: ((UUID) -> Alarm?)?
    
    // 繰り返し通知の設定
    private let repeatingInterval: TimeInterval = 5.0 // 5秒ごとに通知を送る
    private let maxRepeatingDuration: TimeInterval = 30 * 60 // 最大30分間繰り返す
    private var repeatingAlarmIds: Set<UUID> = [] // 現在繰り返し通知を送っているアラームID

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
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
        
        // 繰り返し通知をスケジュール（アラーム時刻から最大30分間、5秒ごとに通知を送る）
        scheduleRepeatingNotifications(for: alarm)
    }
    
    /// 繰り返し通知をスケジュールする（アラーム時刻から一定時間、短い間隔で通知を送り続ける）
    private func scheduleRepeatingNotifications(for alarm: Alarm) {
        let alarmTime = alarm.time
        let now = Date()
        
        // アラーム時刻が過去の場合はスケジュールしない
        guard alarmTime > now else { return }
        
        // アラーム時刻から最大30分間、5秒ごとに通知を送る
        // iOSのローカル通知は一度に64個まで登録できる制限があるため、
        // 最大で約5分間（5秒×64=320秒）の通知を事前にスケジュールする
        let maxNotifications = min(64, Int(maxRepeatingDuration / repeatingInterval))
        
        for i in 0..<maxNotifications {
            let notificationTime = alarmTime.addingTimeInterval(Double(i) * repeatingInterval)
            
            // 現在時刻より未来の通知のみスケジュール
            guard notificationTime > now else { continue }
            
            let content = createNotificationContent(for: alarm)
            let timeInterval = notificationTime.timeIntervalSinceNow
            
            // 時間間隔トリガーを使用（アラーム時刻からi回目の通知）
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            
            // 各通知に一意の識別子を付ける（アラームID + 通知番号）
            let identifier = "\(alarm.notificationIdentifier)_repeat_\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("繰り返し通知の登録に失敗: \(error.localizedDescription)")
                }
            }
        }
        
        // 繰り返し通知を送っているアラームIDを記録
        repeatingAlarmIds.insert(alarm.id)
        
        print("アラーム「\(alarm.name)」の繰り返し通知を\(maxNotifications)個スケジュールしました")
    }
    
    /// 通知コンテンツを作成する
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.name
        content.body = "目的地に到着したら停止してください"
        
        // カスタム音源を通知音として設定
        // iOSのローカル通知では拡張子込みのファイル名が必須
        if let _ = Bundle.main.url(forResource: "Clock-Alarm04-01_Mid_", withExtension: "caf") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("Clock-Alarm04-01_Mid_.caf"))
        } else {
            content.sound = .default
        }
        
        // アラームIDをuserInfoに含める
        content.userInfo = ["alarmId": alarm.id.uuidString, "isRepeating": true]
        
        return content
    }
    
    /// 次の通知をスケジュールする（通知を受信したときに呼び出す）
    func scheduleNextNotification(for alarm: Alarm) {
        // アラームが停止されている場合は何もしない
        guard repeatingAlarmIds.contains(alarm.id) else { return }
        
        let content = createNotificationContent(for: alarm)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: repeatingInterval, repeats: false)
        
        // 一意の識別子を生成（タイムスタンプを使用）
        let identifier = "\(alarm.notificationIdentifier)_next_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("次の通知の登録に失敗: \(error.localizedDescription)")
            }
        }
    }

    func cancel(alarm: Alarm) {
        // 繰り返し通知を停止
        repeatingAlarmIds.remove(alarm.id)
        
        // 該当するアラームのすべての通知をキャンセル
        // 識別子のパターンに基づいてキャンセルする
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { request in
                    // アラームIDが一致する通知をすべて取得
                    if let alarmIdString = request.content.userInfo["alarmId"] as? String,
                       let alarmId = UUID(uuidString: alarmIdString),
                       alarmId == alarm.id {
                        return true
                    }
                    // 識別子がアラームの通知識別子で始まる場合も含める
                    if request.identifier.hasPrefix(alarm.notificationIdentifier) {
                        return true
                    }
                    return false
                }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
            print("アラーム「\(alarm.name)」の通知を\(identifiersToCancel.count)個キャンセルしました")
        }
    }

    func reschedule(alarms: [Alarm]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for alarm in alarms where alarm.enabled {
            schedule(alarm: alarm)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // アプリがフォアグラウンドの時に通知を受信した場合
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでも通知を表示し、アラーム音を再生
        completionHandler([.banner, .sound, .badge])
        handleNotification(notification)
        
        // 繰り返し通知の場合、次の通知をスケジュール
        scheduleNextIfRepeating(notification: notification)
    }
    
    // ユーザーが通知をタップした場合
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotification(response.notification)
        
        // 繰り返し通知の場合、次の通知をスケジュール
        scheduleNextIfRepeating(notification: response.notification)
        
        completionHandler()
    }
    
    /// 繰り返し通知の場合、次の通知をスケジュールする
    private func scheduleNextIfRepeating(notification: UNNotification) {
        guard let isRepeating = notification.request.content.userInfo["isRepeating"] as? Bool,
              isRepeating,
              let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else {
            return
        }
        
        // コールバックを使ってアラーム情報を取得
        if let alarm = getAlarmById?(alarmId) {
            // アラームが有効で、まだ繰り返し通知を送っている場合のみ次の通知をスケジュール
            if alarm.enabled && repeatingAlarmIds.contains(alarm.id) {
                scheduleNextNotification(for: alarm)
            }
        }
    }
    
    private func handleNotification(_ notification: UNNotification) {
        guard let alarmIdString = notification.request.content.userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else {
            print("通知にアラームIDが含まれていません")
            return
        }
        
        DispatchQueue.main.async {
            self.pendingAlarmId = alarmId
            self.onNotificationReceived?(alarmId)
        }
    }
}
