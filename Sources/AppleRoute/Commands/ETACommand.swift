import ArgumentParser

struct ETACommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "eta",
        abstract: "Calculate an ETA using MKDirections.calculateETA()."
    )

    @OptionGroup var endpoints: EndpointOptions

    @Flag(name: .long, help: "Emit JSON only on stdout.")
    var json = false

    mutating func run() async throws {
        do {
            let options = try endpoints.validated()
            async let origin = PlaceResolver().resolve(options.from, near: options.near)
            async let destination = PlaceResolver().resolve(options.to, near: options.near)
            let response = try await RouteService().eta(
                from: origin, to: destination, mode: options.mode,
                depart: options.depart, arrive: options.arrive
            )
            if json { try JSONRenderer.print(response) } else { HumanRenderer.eta(response) }
        } catch let error as AppleRouteError {
            try CLI.fail(error, command: "eta", json: json)
        }
    }
}
