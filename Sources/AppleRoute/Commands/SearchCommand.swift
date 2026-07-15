import ArgumentParser
import Foundation

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for places using MKLocalSearch."
    )

    @Argument(help: "Place name, address, or category to search for.")
    var query: String?

    @Option(name: .long, help: "Bias results near latitude,longitude.")
    var near: String?

    @Option(name: .long, help: "Maximum number of results (1...20).")
    var limit = 10

    @Flag(name: .long, help: "Emit JSON only on stdout.")
    var json = false

    mutating func run() async throws {
        do {
            guard let query, !query.isEmpty else {
                throw AppleRouteError.invalidArguments("Missing search query")
            }
            guard (1...20).contains(limit) else {
                throw AppleRouteError.invalidArguments("--limit must be between 1 and 20")
            }
            let coordinate = try near.map(CoordinateParser.parse)
            let items = try await PlaceResolver().search(query: query, near: coordinate, limit: limit)
            guard !items.isEmpty else {
                throw AppleRouteError.placeNotFound("No places found for '\(query)'")
            }
            let response = SearchEnvelope(results: items.map(PlaceJSON.init))
            if json { try JSONRenderer.print(response) } else { HumanRenderer.search(response) }
        } catch let error as AppleRouteError {
            try CLI.fail(error, command: "search", json: json)
        }
    }
}
