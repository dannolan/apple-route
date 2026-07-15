import ArgumentParser
import CoreLocation

struct EndpointOptions: ParsableArguments {
    @Option(name: .long, help: "Origin place, address, or latitude,longitude.")
    var from: String?

    @Option(name: .long, help: "Destination place, address, or latitude,longitude.")
    var to: String?

    @Option(name: .long, help: "Transport mode: driving, walking, transit, or cycling.")
    var mode = "driving"

    @Option(name: .long, help: "ISO-8601 departure time.")
    var depart: String?

    @Option(name: .long, help: "ISO-8601 arrival time.")
    var arrive: String?

    @Option(name: .long, help: "Bias place resolution near latitude,longitude.")
    var near: String?

    func validated() throws -> (from: String, to: String, mode: TransportMode, depart: Date?, arrive: Date?, near: CLLocationCoordinate2D?) {
        guard let from, !from.isEmpty else {
            throw AppleRouteError.invalidArguments("Missing required option --from")
        }
        guard let to, !to.isEmpty else {
            throw AppleRouteError.invalidArguments("Missing required option --to")
        }
        guard depart == nil || arrive == nil else {
            throw AppleRouteError.invalidArguments("--depart and --arrive cannot be used together")
        }
        return (
            from, to, try TransportMode.parse(mode),
            try depart.map(DateParser.parse),
            try arrive.map(DateParser.parse),
            try near.map(CoordinateParser.parse)
        )
    }
}
