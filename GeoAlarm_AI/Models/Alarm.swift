import Foundation
import CoreLocation

struct Alarm: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var time: Date
    var latitude: Double
    var longitude: Double
    var enabled: Bool = true
    var addressHint: String? = nil

    var notificationIdentifier: String { id.uuidString }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    static func sample() -> Alarm {
        Alarm(
            name: "自宅に帰る",
            time: Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date(),
            latitude: 35.6809591,
            longitude: 139.7673068,
            enabled: true,
            addressHint: "東京駅"
        )
    }
}
