import CoreLocation
import Foundation
import MapKit

@MainActor
final class TripPlannerViewModel: NSObject, ObservableObject {
    @Published var stops: [Stop] = []
    @Published var segments: [TripSegment] = []
    @Published var kmPerLiterInput: String = "12"
    @Published var fuelPriceInput: String = "1300"
    @Published var selectedFuelType: FuelType = .octane95
    @Published var searchText: String = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var errorMessage: String?
    @Published var cameraPosition: MapCameraPosition = .automatic

    private let routeService: RouteServicing
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()

    init(routeService: RouteServicing = RouteService()) {
        self.routeService = routeService
        super.init()
        locationManager.delegate = self
    }

    var kmPerLiter: Double { Double(kmPerLiterInput.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    var fuelPrice: Double { Double(fuelPriceInput.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var summary: TripSummary {
        let distance = segments.reduce(0) { $0 + $1.distanceMeters }
        let liters = segments.reduce(0) { $0 + $1.liters(consumption: kmPerLiter) }
        let cost = segments.reduce(0) { $0 + $1.cost(consumption: kmPerLiter, pricePerLiter: fuelPrice) }
        let duration = segments.reduce(0) { $0 + $1.expectedTravelTime }
        return TripSummary(totalDistanceMeters: distance, totalLiters: liters, totalCost: cost, totalDuration: duration)
    }

    var inputValidationMessage: String? {
        if kmPerLiter <= 0 { return "Ingresa un rendimiento mayor a 0 km/L." }
        if fuelPrice <= 0 { return "Ingresa un precio por litro mayor a 0." }
        return nil
    }

    func requestCurrentLocationAsStart() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func addStop(at coordinate: CLLocationCoordinate2D, name: String = "Parada") {
        let stop = Stop(name: name, coordinate: coordinate)
        stops.append(stop)
        cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)))
        Task { await reverseGeocode(stopID: stop.id) }
        Task { await refreshRoutes() }
    }

    func addStop(from mapItem: MKMapItem) {
        let name = mapItem.name?.isEmpty == false ? mapItem.name! : "Parada"
        addStop(at: mapItem.placemark.coordinate, name: name)
    }

    func removeStops(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
        Task { await refreshRoutes() }
    }

    func moveStop(from source: IndexSet, to destination: Int) {
        stops.move(fromOffsets: source, toOffset: destination)
        Task { await refreshRoutes() }
    }

    func clearRoute() {
        stops.removeAll()
        segments.removeAll()
        searchText = ""
        searchResults.removeAll()
    }

    func searchPlaces() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if case let .region(region) = cameraPosition {
            request.region = region
        }

        Task {
            do {
                let response = try await MKLocalSearch(request: request).start()
                await MainActor.run {
                    self.searchResults = response.mapItems
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "No se pudo buscar lugares en este momento."
                }
            }
        }
    }

    func refreshRoutes() async {
        guard stops.count >= 2 else {
            segments = []
            return
        }

        var newSegments: [TripSegment] = []
        for pair in zip(stops, stops.dropFirst()) {
            let segment = await routeService.buildSegment(from: pair.0, to: pair.1)
            newSegments.append(segment)
        }
        segments = newSegments
    }

    private func reverseGeocode(stopID: UUID) async {
        guard let index = stops.firstIndex(where: { $0.id == stopID }) else { return }
        let location = CLLocation(latitude: stops[index].coordinate.latitude, longitude: stops[index].coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let name = [placemark.name, placemark.locality].compactMap { $0 }.joined(separator: " · ")
                if !name.isEmpty {
                    stops[index].name = name
                }
            }
        } catch {
            // keep default name
        }
    }
}

extension TripPlannerViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            let stop = Stop(name: "Ubicación actual", coordinate: location.coordinate)
            if self.stops.isEmpty {
                self.stops.insert(stop, at: 0)
            } else {
                self.stops[0] = stop
            }
            self.cameraPosition = .region(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)))
            await self.refreshRoutes()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "No se pudo obtener la ubicación actual."
        }
    }
}

enum FuelType: String, CaseIterable, Identifiable {
    case octane93 = "93"
    case octane95 = "95"
    case octane97 = "97"

    var id: String { rawValue }
    var label: String { "Bencina \(rawValue)" }
}
