import Foundation
import MapKit

struct RouteService {
    func routes(
        from origin: MKMapItem,
        to destination: MKMapItem,
        mode: TransportMode,
        depart: Date?,
        arrive: Date?,
        alternatives: Bool
    ) async throws -> RouteEnvelope {
        let request = makeRequest(
            from: origin, to: destination, mode: mode,
            depart: depart, arrive: arrive, alternatives: alternatives
        )
        do {
            let response = try await MKDirections(request: request).calculate()
            guard !response.routes.isEmpty else {
                throw AppleRouteError.routeUnavailable("MapKit returned no routes")
            }
            return RouteEnvelope(
                origin: PlaceJSON(mapItem: response.source),
                destination: PlaceJSON(mapItem: response.destination),
                routes: response.routes.map { route in
                    let times = routeTimes(travelTime: route.expectedTravelTime, depart: depart, arrive: arrive)
                    return RouteJSON(
                        name: route.name,
                        distanceMeters: route.distance,
                        distance: Formatting.distance(route.distance),
                        expectedTravelTimeSeconds: route.expectedTravelTime,
                        expectedTravelTime: Formatting.duration(route.expectedTravelTime),
                        expectedDepartureTime: times.departure.map(DateParser.string),
                        expectedArrivalTime: times.arrival.map(DateParser.string),
                        transportMode: mode,
                        advisoryNotices: route.advisoryNotices,
                        steps: route.steps.map {
                            RouteStepJSON(
                                instruction: $0.instructions,
                                distanceMeters: $0.distance,
                                notice: $0.notice
                            )
                        }
                    )
                }
            )
        } catch let error as AppleRouteError {
            throw error
        } catch {
            let classified = classifyDirectionsError(error)
            if mode == .transit, classified.status == .routeUnavailable {
                return try await transitETAFallback(request: request, mode: mode)
            }
            throw classified
        }
    }

    func eta(
        from origin: MKMapItem,
        to destination: MKMapItem,
        mode: TransportMode,
        depart: Date?,
        arrive: Date?
    ) async throws -> ETAEnvelope {
        let request = makeRequest(
            from: origin, to: destination, mode: mode,
            depart: depart, arrive: arrive, alternatives: false
        )
        do {
            let response = try await MKDirections(request: request).calculateETA()
            return ETAEnvelope(
                origin: PlaceJSON(mapItem: response.source),
                destination: PlaceJSON(mapItem: response.destination),
                eta: ETAJSON(
                    distanceMeters: response.distance,
                    distance: Formatting.distance(response.distance),
                    expectedTravelTimeSeconds: response.expectedTravelTime,
                    expectedTravelTime: Formatting.duration(response.expectedTravelTime),
                    expectedDepartureTime: DateParser.string(response.expectedDepartureDate),
                    expectedArrivalTime: DateParser.string(response.expectedArrivalDate),
                    transportMode: mode
                )
            )
        } catch {
            throw classifyDirectionsError(error)
        }
    }

    private func makeRequest(
        from origin: MKMapItem,
        to destination: MKMapItem,
        mode: TransportMode,
        depart: Date?,
        arrive: Date?,
        alternatives: Bool
    ) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = origin
        request.destination = destination
        request.transportType = mode.mapKit
        request.requestsAlternateRoutes = alternatives
        request.departureDate = depart
        request.arrivalDate = arrive
        return request
    }

    private func routeTimes(travelTime: TimeInterval, depart: Date?, arrive: Date?) -> (departure: Date?, arrival: Date?) {
        if let arrive { return (arrive.addingTimeInterval(-travelTime), arrive) }
        let departure = depart ?? Date()
        return (departure, departure.addingTimeInterval(travelTime))
    }

    private func transitETAFallback(request: MKDirections.Request, mode: TransportMode) async throws -> RouteEnvelope {
        do {
            let response = try await MKDirections(request: request).calculateETA()
            let notice = "This macOS MapKit runtime exposes transit through calculateETA(); detailed transit steps and alternatives are unavailable."
            return RouteEnvelope(
                origin: PlaceJSON(mapItem: response.source),
                destination: PlaceJSON(mapItem: response.destination),
                routes: [
                    RouteJSON(
                        name: "Transit ETA",
                        distanceMeters: response.distance,
                        distance: Formatting.distance(response.distance),
                        expectedTravelTimeSeconds: response.expectedTravelTime,
                        expectedTravelTime: Formatting.duration(response.expectedTravelTime),
                        expectedDepartureTime: DateParser.string(response.expectedDepartureDate),
                        expectedArrivalTime: DateParser.string(response.expectedArrivalDate),
                        transportMode: mode,
                        advisoryNotices: [notice],
                        steps: []
                    )
                ]
            )
        } catch {
            throw classifyDirectionsError(error)
        }
    }

    private func classifyDirectionsError(_ error: Error) -> AppleRouteError {
        let nsError = error as NSError
        if nsError.domain == MKError.errorDomain,
           nsError.code == MKError.Code.directionsNotFound.rawValue {
            return .routeUnavailable("No route is available for the requested places and mode")
        }
        return .mapKitFailure("MapKit directions failed: \(error.localizedDescription)")
    }
}
