import CoreLocation
import Foundation

enum CoordinateParser {
    static func parse(_ value: String) throws -> CLLocationCoordinate2D {
        let parts = value.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            throw AppleRouteError.invalidArguments("Expected coordinates as latitude,longitude")
        }
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw AppleRouteError.invalidArguments("Coordinates are outside valid latitude/longitude ranges")
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func parseIfCoordinate(_ value: String) throws -> CLLocationCoordinate2D? {
        guard value.contains(",") else { return nil }
        let parts = value.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              Double(parts[0].trimmingCharacters(in: .whitespaces)) != nil,
              Double(parts[1].trimmingCharacters(in: .whitespaces)) != nil else {
            return nil
        }
        return try parse(value)
    }
}
