import SwiftUI
import MapKit

struct MapPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D

    @State private var camera: MapCameraPosition
    @State private var isFollowingUser = false

    init(coordinate: Binding<CLLocationCoordinate2D>) {
        _coordinate = coordinate
        _camera = State(initialValue: .region(MKCoordinateRegion(center: coordinate.wrappedValue, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $camera, interactionModes: .all, scope: .local) {
                Annotation("目的地", coordinate: coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.25))
                            .frame(width: 30, height: 30)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.red)
                            .imageScale(.large)
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .onTapGesture { location in
                if let newCoordinate = proxy.convert(location, from: .local) {
                    coordinate = newCoordinate
                    camera = .region(MKCoordinateRegion(center: newCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Label("地図をタップして目的地を設定", systemImage: "hand.tap")
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding()
        }
    }
}
