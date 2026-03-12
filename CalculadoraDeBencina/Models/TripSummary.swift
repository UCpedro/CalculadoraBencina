import Foundation

struct TripSummary {
    let totalDistanceMeters: Double
    let totalLiters: Double
    let totalCost: Double
    let totalDuration: TimeInterval

    static let zero = TripSummary(totalDistanceMeters: 0, totalLiters: 0, totalCost: 0, totalDuration: 0)
}
