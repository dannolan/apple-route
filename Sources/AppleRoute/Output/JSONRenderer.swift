import Foundation

enum JSONRenderer {
    static func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    static func print<T: Encodable>(_ value: T) throws {
        Swift.print(try encode(value))
    }
}
