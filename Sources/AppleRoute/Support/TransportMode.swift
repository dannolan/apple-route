import Foundation
import MapKit

enum TransportMode: String, Codable, CaseIterable {
    case driving, walking, transit, cycling

    static func parse(_ value: String) throws -> Self {
        guard let mode = Self(rawValue: value.lowercased()) else {
            throw AppleRouteError.unsupportedMode(
                "Unsupported mode '\(value)'; use driving, walking, transit, or cycling"
            )
        }
        if mode == .cycling, #unavailable(macOS 11) {
            throw AppleRouteError.unsupportedMode("Cycling requires macOS 11 or newer")
        }
        return mode
    }

    var mapKit: MKDirectionsTransportType {
        switch self {
        case .driving: .automobile
        case .walking: .walking
        case .transit: .transit
        case .cycling: .cycling
        }
    }
}
