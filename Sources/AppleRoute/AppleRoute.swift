import ArgumentParser
import Darwin
import Foundation

struct AppleRoute: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apple-route",
        abstract: "Native Apple MapKit search, routing, and ETA from Terminal.",
        version: "0.1.0",
        subcommands: [SearchCommand.self, RouteCommand.self, ETACommand.self]
    )
}

@main
enum AppleRouteMain {
    static func main() async {
        do {
            var command = try AppleRoute.parseAsRoot()
            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            let arguments = CommandLine.arguments.dropFirst()
            let wantsJSON = arguments.contains("--json")
            if wantsJSON, !(error is CleanExit), !(error is ExitCode) {
                let knownCommands = Set(["search", "route", "eta"])
                let command = arguments.first.flatMap { knownCommands.contains($0) ? $0 : nil } ?? "apple-route"
                let appError = AppleRouteError.invalidArguments(AppleRoute.message(for: error))
                if let text = try? JSONRenderer.encode(ErrorEnvelope(command: command, error: appError)) {
                    FileHandle.standardError.write(Data((text + "\n").utf8))
                }
                exit(ExitStatus.invalidArguments.rawValue)
            }
            AppleRoute.exit(withError: error)
        }
    }
}
