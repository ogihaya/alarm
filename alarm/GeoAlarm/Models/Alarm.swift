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
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: time)
    }
}
