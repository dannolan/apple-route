import Foundation
import MapKit

struct PlaceJSON: Codable, Equatable {
    let name: String?
    let address: String?
    let latitude: Double
    let longitude: Double
    let phoneNumber: String?
    let url: String?
    let pointOfInterestCategory: String?

    init(mapItem: MKMapItem) {
        name = mapItem.name
        if #available(macOS 26, *) {
            address = mapItem.address?.fullAddress
            latitude = mapItem.location.coordinate.latitude
            longitude = mapItem.location.coordinate.longitude
        } else {
            address = mapItem.placemark.title
            latitude = mapItem.placemark.coordinate.latitude
            longitude = mapItem.placemark.coordinate.longitude
        }
        phoneNumber = mapItem.phoneNumber
        url = mapItem.url?.absoluteString
        pointOfInterestCategory = mapItem.pointOfInterestCategory?.rawValue
    }

    init(name: String?, address: String?, latitude: Double, longitude: Double,
         phoneNumber: String? = nil, url: String? = nil, pointOfInterestCategory: String? = nil) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.url = url
        self.pointOfInterestCategory = pointOfInterestCategory
    }
}

struct SearchEnvelope: Codable, Equatable {
    let schemaVersion: Int
    let command: String
    let results: [PlaceJSON]

    init(results: [PlaceJSON]) {
        schemaVersion = 1
        command = "search"
        self.results = results
    }
}

struct RouteStepJSON: Codable, Equatable {
    let instruction: String
    let distanceMeters: Double
    let notice: String?
}

struct RouteJSON: Codable, Equatable {
    let name: String
    let distanceMeters: Double
    let distance: String
    let expectedTravelTimeSeconds: Double
    let expectedTravelTime: String
    let expectedDepartureTime: String?
    let expectedArrivalTime: String?
    let transportMode: TransportMode
    let advisoryNotices: [String]
    let steps: [RouteStepJSON]
}

struct RouteEnvelope: Codable, Equatable {
    let schemaVersion: Int
    let command: String
    let origin: PlaceJSON
    let destination: PlaceJSON
    let routes: [RouteJSON]

    init(origin: PlaceJSON, destination: PlaceJSON, routes: [RouteJSON]) {
        schemaVersion = 1
        command = "route"
        self.origin = origin
        self.destination = destination
        self.routes = routes
    }
}

struct ETAJSON: Codable, Equatable {
    let distanceMeters: Double
    let distance: String
    let expectedTravelTimeSeconds: Double
    let expectedTravelTime: String
    let expectedDepartureTime: String
    let expectedArrivalTime: String
    let transportMode: TransportMode
}

struct ETAEnvelope: Codable, Equatable {
    let schemaVersion: Int
    let command: String
    let origin: PlaceJSON
    let destination: PlaceJSON
    let eta: ETAJSON

    init(origin: PlaceJSON, destination: PlaceJSON, eta: ETAJSON) {
        schemaVersion = 1
        command = "eta"
        self.origin = origin
        self.destination = destination
        self.eta = eta
    }
}

struct ErrorDetail: Codable, Equatable {
    let code: String
    let message: String
    let exitCode: Int32
}

struct ErrorEnvelope: Codable, Equatable {
    let schemaVersion: Int
    let command: String
    let error: ErrorDetail

    init(command: String, error: AppleRouteError) {
        schemaVersion = 1
        self.command = command
        self.error = ErrorDetail(code: error.code, message: error.message, exitCode: error.status.rawValue)
    }
}
