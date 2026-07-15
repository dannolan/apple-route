import CoreLocation
import Foundation
import MapKit

struct PlaceResolver {
    func search(query: String, near: CLLocationCoordinate2D?, limit: Int) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let near {
            request.region = MKCoordinateRegion(
                center: near,
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            )
        }
        do {
            let response = try await MKLocalSearch(request: request).start()
            return Array(response.mapItems.prefix(limit))
        } catch {
            throw AppleRouteError.mapKitFailure("MapKit search failed: \(error.localizedDescription)")
        }
    }

    func resolve(_ input: String, near: CLLocationCoordinate2D?) async throws -> MKMapItem {
        if let coordinate = try CoordinateParser.parseIfCoordinate(input) {
            return mapItem(coordinate: coordinate)
        }

        let results = try await search(query: input, near: near, limit: 10)
        guard !results.isEmpty else {
            throw AppleRouteError.placeNotFound("No place found for '\(input)'")
        }

        let normalized = normalize(input)
        if let exact = results.first(where: {
            guard let name = $0.name else { return false }
            return normalize(name) == normalized
        }) {
            return exact
        }

        let strong = results.filter { item in
            let fields = [item.name, address(item)].compactMap { $0 }.map(normalize)
            return fields.contains { $0.contains(normalized) || normalized.contains($0) }
        }
        if strong.count == 1, let match = strong.first { return match }

        // MKLocalSearch ranks by relevance. Accept its first result only when the
        // query terms substantially overlap the returned name/address.
        if let first = results.first, score(input: normalized, item: first) >= 0.5 {
            return first
        }

        let names = results.prefix(3).compactMap(\.name).joined(separator: ", ")
        throw AppleRouteError.ambiguousPlace(
            "Could not confidently resolve '\(input)'\(names.isEmpty ? "" : "; top results: \(names)")"
        )
    }

    private func mapItem(coordinate: CLLocationCoordinate2D) -> MKMapItem {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if #available(macOS 26, *) {
            let item = MKMapItem(location: location, address: nil)
            item.name = "\(coordinate.latitude),\(coordinate.longitude)"
            return item
        }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = "\(coordinate.latitude),\(coordinate.longitude)"
        return item
    }

    private func address(_ item: MKMapItem) -> String? {
        if #available(macOS 26, *) { return item.address?.fullAddress }
        return item.placemark.title
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func score(input: String, item: MKMapItem) -> Double {
        let queryWords = Set(input.split(separator: " ").map(String.init))
        guard !queryWords.isEmpty else { return 0 }
        let candidate = normalize([item.name, address(item)].compactMap { $0 }.joined(separator: " "))
        let candidateWords = Set(candidate.split(separator: " ").map(String.init))
        return Double(queryWords.intersection(candidateWords).count) / Double(queryWords.count)
    }
}
