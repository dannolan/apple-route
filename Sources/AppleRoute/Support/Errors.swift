import ArgumentParser
import Foundation

enum ExitStatus: Int32, Codable {
    case invalidArguments = 2
    case placeNotFound = 3
    case ambiguousPlace = 4
    case routeUnavailable = 5
    case mapKitFailure = 6
    case unsupportedMode = 7
}

enum AppleRouteError: Error, Equatable {
    case invalidArguments(String)
    case placeNotFound(String)
    case ambiguousPlace(String)
    case routeUnavailable(String)
    case mapKitFailure(String)
    case unsupportedMode(String)

    var status: ExitStatus {
        switch self {
        case .invalidArguments: .invalidArguments
        case .placeNotFound: .placeNotFound
        case .ambiguousPlace: .ambiguousPlace
        case .routeUnavailable: .routeUnavailable
        case .mapKitFailure: .mapKitFailure
        case .unsupportedMode: .unsupportedMode
        }
    }

    var code: String {
        switch self {
        case .invalidArguments: "invalid_arguments"
        case .placeNotFound: "place_not_found"
        case .ambiguousPlace: "ambiguous_place"
        case .routeUnavailable: "route_unavailable"
        case .mapKitFailure: "mapkit_failure"
        case .unsupportedMode: "unsupported_transport_mode"
        }
    }

    var message: String {
        switch self {
        case let .invalidArguments(message), let .placeNotFound(message),
             let .ambiguousPlace(message), let .routeUnavailable(message),
             let .mapKitFailure(message), let .unsupportedMode(message): message
        }
    }
}

enum CLI {
    static func fail(_ error: AppleRouteError, command: String, json: Bool) throws -> Never {
        let text: String
        if json {
            text = (try? JSONRenderer.encode(ErrorEnvelope(command: command, error: error)))
                ?? #"{"schemaVersion":1,"command":"unknown","error":{"code":"encoding_failure","message":"Could not encode error","exitCode":6}}"#
        } else {
            text = "apple-route: \(error.message)"
        }
        FileHandle.standardError.write(Data((text + "\n").utf8))
        throw ExitCode(error.status.rawValue)
    }
}
