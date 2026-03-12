import Foundation
import MapKit

protocol RouteServicing {
    func buildSegment(from: Stop, to: Stop) async -> TripSegment
}

struct RouteService: RouteServicing {
    func buildSegment(from: Stop, to: Stop) async -> TripSegment {
        let request = MKDirections.Request()
        request.source = from.mapItem
        request.destination = to.mapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                return TripSegment(
                    from: from,
                    to: to,
                    distanceMeters: route.distance,
                    expectedTravelTime: route.expectedTravelTime,
                    polyline: route.polyline
                )
            }
        } catch {
            // fallback below using direct distance
        }

        let start = CLLocation(latitude: from.coordinate.latitude, longitude: from.coordinate.longitude)
        let end = CLLocation(latitude: to.coordinate.latitude, longitude: to.coordinate.longitude)
        return TripSegment(
            from: from,
            to: to,
            distanceMeters: start.distance(from: end),
            expectedTravelTime: 0,
            polyline: nil
        )
    }
}
