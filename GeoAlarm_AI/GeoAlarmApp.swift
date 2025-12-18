import SwiftUI

@main//@mainがエントリーポイント、これを認識にてまずはここから実行される
struct GeoAlarmApp: App {
    //ここで各サービスを起動している。@StateObjectで初期起動。
    @StateObject private var store = AlarmStore()
    @StateObject private var locationService = LocationService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var soundService = SoundService()

    var body: some Scene {
        WindowGroup {
            AlarmListView()
                .environmentObject(store)
                .environmentObject(locationService)
                .environmentObject(notificationService)
                .environmentObject(soundService)
        }
    }
}
