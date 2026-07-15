import Foundation

enum HumanRenderer {
    static func search(_ response: SearchEnvelope) {
        for (index, place) in response.results.enumerated() {
            if index > 0 { print("") }
            print(place.name ?? "Unnamed place")
            if let address = place.address { print("  \(address)") }
            print("  \(place.latitude),\(place.longitude)")
            if let phone = place.phoneNumber { print("  Phone: \(phone)") }
            if let url = place.url { print("  URL: \(url)") }
            if let category = place.pointOfInterestCategory { print("  Category: \(category)") }
        }
    }

    static func route(_ response: RouteEnvelope) {
        print("From: \(label(response.origin))")
        print("To:   \(label(response.destination))")
        for (index, route) in response.routes.enumerated() {
            print("")
            let prefix = response.routes.count > 1 ? "Route \(index + 1): " : "Route: "
            print("\(prefix)\(route.name)")
            print("  \(route.distance) · \(route.expectedTravelTime) · \(route.transportMode.rawValue)")
            if let departure = route.expectedDepartureTime { print("  Depart: \(departure)") }
            if let arrival = route.expectedArrivalTime { print("  Arrive: \(arrival)") }
            for notice in route.advisoryNotices { print("  Notice: \(notice)") }
            for step in route.steps where !step.instruction.isEmpty {
                print("  - \(step.instruction) (\(Formatting.distance(step.distanceMeters)))")
                if let notice = step.notice { print("    Notice: \(notice)") }
            }
        }
    }

    static func eta(_ response: ETAEnvelope) {
        print("From: \(label(response.origin))")
        print("To:   \(label(response.destination))")
        print("ETA:  \(response.eta.expectedTravelTime) · \(response.eta.distance) · \(response.eta.transportMode.rawValue)")
        print("Depart: \(response.eta.expectedDepartureTime)")
        print("Arrive: \(response.eta.expectedArrivalTime)")
    }

    private static func label(_ place: PlaceJSON) -> String {
        [place.name, place.address].compactMap { $0 }.joined(separator: " — ")
    }
}
