import ArgumentParser

struct RouteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "route",
        abstract: "Calculate turn-by-turn routes using MKDirections."
    )

    @OptionGroup var endpoints: EndpointOptions

    @Flag(name: .long, help: "Request alternative routes.")
    var alternatives = false

    @Flag(name: .long, help: "Emit JSON only on stdout.")
    var json = false

    mutating func run() async throws {
        do {
            let options = try endpoints.validated()
            async let origin = PlaceResolver().resolve(options.from, near: options.near)
            async let destination = PlaceResolver().resolve(options.to, near: options.near)
            let response = try await RouteService().routes(
                from: origin, to: destination, mode: options.mode,
                depart: options.depart, arrive: options.arrive, alternatives: alternatives
            )
            if json { try JSONRenderer.print(response) } else { HumanRenderer.route(response) }
        } catch let error as AppleRouteError {
            try CLI.fail(error, command: "route", json: json)
        }
    }
}
