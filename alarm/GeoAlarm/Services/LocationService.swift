import Foundation
import Combine
import CoreLocation

/// 現在地取得と半径判定を担当するサービス
final class LocationService: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var isUpdating = false
    @Published var lastError: String?
    let requiredRadius: CLLocationDistance = 100

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startUpdates() {
        lastError = nil
        isUpdating = true
        manager.startUpdatingLocation()
    }

    func stopUpdates() {
        isUpdating = false
        manager.stopUpdatingLocation()
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = lastLocation else { return nil }
        let destination = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: destination)
    }

    func isWithinRange(of coordinate: CLLocationCoordinate2D) -> Bool? {
        guard let distance = distance(to: coordinate) else { return nil }
        return distance <= requiredRadius
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var statusDescription: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if let last = lastLocation {
                return "位置情報取得中: lat \(String(format: "%.4f", last.coordinate.latitude)), lon \(String(format: "%.4f", last.coordinate.longitude))"
            }
            return "位置情報を取得中です…"
        case .denied, .restricted:
            return "位置情報の権限がありません。設定アプリで許可してください。"
        case .notDetermined:
            return "位置情報の権限が未許可です。許可をお願いします。"
        @unknown default:
            return "位置情報の権限状態を確認できません。"
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdates()
        default:
            stopUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
        lastError = error.localizedDescription
    }
}
