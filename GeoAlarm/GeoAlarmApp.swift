import SwiftUI

@main
struct GeoAlarmApp: App {
    @StateObject private var store = AlarmStore()
    @StateObject private var locationService = LocationService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var soundService = SoundService()
}