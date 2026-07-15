import CoreLocation
import Foundation
import XCTest
@testable import AppleRoute

final class AppleRouteTests: XCTestCase {
    func testCoordinateParsing() throws {
        let coordinate = try CoordinateParser.parse("-33.8688,151.2093")
        XCTAssertEqual(coordinate.latitude, -33.8688, accuracy: 0.000_001)
        XCTAssertEqual(coordinate.longitude, 151.2093, accuracy: 0.000_001)
    }

    func testCoordinateWhitespace() throws {
        let coordinate = try CoordinateParser.parse(" -33.0, 151.0 ")
        XCTAssertEqual(coordinate.latitude, -33)
        XCTAssertEqual(coordinate.longitude, 151)
    }

    func testInvalidCoordinateRanges() {
        XCTAssertThrowsError(try CoordinateParser.parse("-91,151"))
        XCTAssertThrowsError(try CoordinateParser.parse("-33,181"))
        XCTAssertThrowsError(try CoordinateParser.parse("not,a-coordinate"))
    }

    func testISO8601Parsing() throws {
        XCTAssertNotNil(try DateParser.parse("2026-07-18T10:00:00+10:00"))
        XCTAssertNotNil(try DateParser.parse("2026-07-18T00:00:00.123Z"))
        XCTAssertThrowsError(try DateParser.parse("next Saturday"))
    }

    func testDepartureAndArrivalAreMutuallyExclusive() {
        var options = EndpointOptions()
        options.from = "A"
        options.to = "B"
        options.depart = "2026-07-18T09:00:00+10:00"
        options.arrive = "2026-07-18T10:00:00+10:00"
        XCTAssertThrowsError(try options.validated()) { error in
            XCTAssertEqual(error as? AppleRouteError, .invalidArguments("--depart and --arrive cannot be used together"))
        }
    }

    func testTransportModeParsing() throws {
        XCTAssertEqual(try TransportMode.parse("driving"), .driving)
        XCTAssertEqual(try TransportMode.parse("WALKING"), .walking)
        XCTAssertEqual(try TransportMode.parse("transit"), .transit)
        XCTAssertEqual(try TransportMode.parse("cycling"), .cycling)
        XCTAssertThrowsError(try TransportMode.parse("flying"))
    }

    func testHumanReadableFormatting() {
        XCTAssertEqual(Formatting.distance(120), "120 m")
        XCTAssertEqual(Formatting.distance(2_445), "2.4 km")
        XCTAssertEqual(Formatting.duration(600), "10 min")
        XCTAssertEqual(Formatting.duration(5_400), "1 hr 30 min")
    }

    func testJSONSchemaEncoding() throws {
        let place = PlaceJSON(name: "Sydney", address: "NSW", latitude: -33, longitude: 151)
        let envelope = RouteEnvelope(origin: place, destination: place, routes: [])
        let data = try XCTUnwrap(JSONRenderer.encode(envelope).data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertEqual(object["command"] as? String, "route")
        XCTAssertNotNil(object["routes"] as? [Any])
    }

    func testErrorEncodingAndExitCodeMapping() throws {
        let cases: [(AppleRouteError, ExitStatus)] = [
            (.invalidArguments("bad"), .invalidArguments),
            (.placeNotFound("bad"), .placeNotFound),
            (.ambiguousPlace("bad"), .ambiguousPlace),
            (.routeUnavailable("bad"), .routeUnavailable),
            (.mapKitFailure("bad"), .mapKitFailure),
            (.unsupportedMode("bad"), .unsupportedMode),
        ]
        for (error, expected) in cases {
            XCTAssertEqual(error.status, expected)
        }
        let text = try JSONRenderer.encode(ErrorEnvelope(command: "route", error: .routeUnavailable("No route")))
        let data = try XCTUnwrap(text.data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let detail = try XCTUnwrap(object["error"] as? [String: Any])
        XCTAssertEqual(detail["code"] as? String, "route_unavailable")
        XCTAssertEqual(detail["exitCode"] as? Int, Int(ExitStatus.routeUnavailable.rawValue))
    }
}
