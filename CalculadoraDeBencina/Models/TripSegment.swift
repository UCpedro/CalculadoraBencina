import Foundation
import MapKit

struct TripSegment: Identifiable {
    let id = UUID()
    let from: Stop
    let to: Stop
    let distanceMeters: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let polyline: MKPolyline?

    func liters(consumption kmPerLiter: Double) -> Double {
        guard kmPerLiter > 0 else { return 0 }
        return (distanceMeters / 1000) / kmPerLiter
    }

    func cost(consumption kmPerLiter: Double, pricePerLiter: Double) -> Double {
        liters(consumption: kmPerLiter) * max(0, pricePerLiter)
    }
}
