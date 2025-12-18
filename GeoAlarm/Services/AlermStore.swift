import Foundation
import Combine

final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [Alarm] = []

    private let storageKey = "stored_alarms"
    private let queue = DispatchQueue(label: "AlarmStoreQueue")

    init() {
        load()
    }
}