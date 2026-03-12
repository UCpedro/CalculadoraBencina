import CoreLocation
import Foundation
import MapKit

struct Stop: Identifiable, Equatable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D

    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }

    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        return item
    }
}
