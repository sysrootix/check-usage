import Foundation

enum HTTPClient {
    static func data(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 20
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CheckUsageError.message("invalid_response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw CheckUsageError.unauthorized
        }
        if http.statusCode == 429 {
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw CheckUsageError.rateLimited(retryAfter: retry)
        }
        if !(200..<300).contains(http.statusCode) {
            throw CheckUsageError.unexpectedStatus(http.statusCode)
        }
        return (data, http)
    }

    static func jsonObject(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> JSONValue {
        let (data, _) = try await data(url: url, method: method, headers: headers, body: body)
        return try JSONValue.parse(data)
    }
}

enum JSONValue: Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    static func parse(_ data: Data) throws -> JSONValue {
        let raw = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return wrap(raw)
    }

    private static func wrap(_ raw: Any) -> JSONValue {
        if raw is NSNull { return .null }
        if let value = raw as? String { return .string(value) }
        if let value = raw as? Bool { return .bool(value) }
        if let value = raw as? NSNumber {
            let objCType = String(cString: value.objCType)
            if objCType == "c" || objCType == "B" {
                return .bool(value.boolValue)
            }
            return .number(value.doubleValue)
        }
        if let value = raw as? [String: Any] {
            return .object(value.mapValues { wrap($0) })
        }
        if let value = raw as? [Any] {
            return .array(value.map { wrap($0) })
        }
        return .null
    }

    subscript(_ key: String) -> JSONValue? {
        if case .object(let object) = self { return object[key] }
        return nil
    }

    subscript(index: Int) -> JSONValue? {
        if case .array(let array) = self, array.indices.contains(index) { return array[index] }
        return nil
    }

    var object: [String: JSONValue]? {
        if case .object(let object) = self { return object }
        return nil
    }

    var array: [JSONValue]? {
        if case .array(let array) = self { return array }
        return nil
    }

    var string: String? {
        switch self {
        case .string(let value): value
        case .number(let value): String(value)
        default: nil
        }
    }

    var double: Double? {
        switch self {
        case .number(let value): value
        case .string(let value): Double(value)
        default: nil
        }
    }

    var int: Int? {
        double.map { Int($0) }
    }

    var bool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    func path(_ keys: String...) -> JSONValue? {
        var current: JSONValue? = self
        for key in keys {
            current = current?[key]
        }
        return current
    }
}

enum DateParser {
    static func parse(_ raw: JSONValue?) -> Date? {
        guard let raw else { return nil }
        if let number = raw.double {
            return fromEpoch(number)
        }
        if let string = raw.string {
            if let number = Double(string) {
                return fromEpoch(number)
            }
            return iso(string)
        }
        return nil
    }

    static func fromEpoch(_ value: Double) -> Date {
        if value > 1_000_000_000_000 {
            return Date(timeIntervalSince1970: value / 1000)
        }
        return Date(timeIntervalSince1970: value)
    }

    static func iso(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: string)
    }
}
