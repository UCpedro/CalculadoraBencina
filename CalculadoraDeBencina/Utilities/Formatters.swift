import Foundation

enum Formatters {
    static let distance: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.unitStyle = .medium
        return formatter
    }()

    static func distanceKm(fromMeters meters: Double) -> String {
        let measurement = Measurement(value: meters / 1000, unit: UnitLength.kilometers)
        return distance.string(from: measurement)
    }

    static func liters(_ value: Double) -> String {
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.minimumFractionDigits = 1
        number.maximumFractionDigits = 2
        return "\(number.string(from: NSNumber(value: value)) ?? "0") L"
    }

    static func currency(_ value: Double) -> String {
        let number = NumberFormatter()
        number.numberStyle = .currency
        number.currencyCode = "CLP"
        number.locale = Locale(identifier: "es_CL")
        number.maximumFractionDigits = 0
        return number.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func duration(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: value) ?? "-"
    }
}
