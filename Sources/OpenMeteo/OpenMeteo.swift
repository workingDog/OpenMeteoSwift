import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenMeteo: Sendable {
    public var latitude: Double
    public var longitude: Double
    public var apiKey: String?
    public var contexts: Contexts
    public var client: OpenMeteoClient

    public init(
        latitude: Double,
        longitude: Double,
        apiKey: String? = nil,
        contexts: Contexts = .default,
        client: OpenMeteoClient = .shared
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.apiKey = apiKey
        self.contexts = contexts
        self.client = client
    }

    public init(location name: String, language: String? = nil, apiKey: String? = nil, client: OpenMeteoClient = .shared) async throws {
        let result = try await Geocoding.Search.first(name: name, language: language, apiKey: apiKey, client: client)
        self.init(latitude: result.latitude, longitude: result.longitude, apiKey: apiKey, client: client)
    }

    public init(geocodingID id: Int, language: String? = nil, apiKey: String? = nil, client: OpenMeteoClient = .shared) async throws {
        let result = try await Geocoding.Get.fetch(id: id, language: language, apiKey: apiKey, client: client)
        self.init(latitude: result.latitude, longitude: result.longitude, apiKey: apiKey, client: client)
    }

    public func forecast(_ configure: (inout Forecast.Query) -> Void = { _ in }) async throws -> WeatherResponse {
        var query = Forecast.Query(latitude: latitude, longitude: longitude, apiKey: apiKey)
        configure(&query)
        return try await Forecast.fetch(query, context: contexts.forecast, client: client)
    }

    public func historical(startDate: DateOnly, endDate: DateOnly, _ configure: (inout Historical.Query) -> Void = { _ in }) async throws -> WeatherResponse {
        var query = Historical.Query(latitude: latitude, longitude: longitude, startDate: startDate, endDate: endDate, apiKey: apiKey)
        configure(&query)
        return try await Historical.fetch(query, context: contexts.historical, client: client)
    }

    public func airQuality(_ configure: (inout AirQuality.Query) -> Void = { _ in }) async throws -> HourlyResponse {
        var query = AirQuality.Query(latitude: latitude, longitude: longitude, apiKey: apiKey)
        configure(&query)
        return try await AirQuality.fetch(query, context: contexts.airQuality, client: client)
    }

    public func ensemble(_ configure: (inout Ensemble.Query) -> Void = { _ in }) async throws -> HourlyResponse {
        var query = Ensemble.Query(latitude: latitude, longitude: longitude, apiKey: apiKey)
        configure(&query)
        return try await Ensemble.fetch(query, context: contexts.ensemble, client: client)
    }

    public func marine(_ configure: (inout Marine.Query) -> Void = { _ in }) async throws -> WeatherResponse {
        var query = Marine.Query(latitude: latitude, longitude: longitude, apiKey: apiKey)
        configure(&query)
        return try await Marine.fetch(query, context: contexts.marine, client: client)
    }

    public func flood(_ configure: (inout Flood.Query) -> Void = { _ in }) async throws -> DailyResponse {
        var query = Flood.Query(latitude: latitude, longitude: longitude, apiKey: apiKey)
        configure(&query)
        return try await Flood.fetch(query, context: contexts.flood, client: client)
    }

    public func elevation() async throws -> Elevation.Response {
        try await Elevation.fetch(latitude: latitude, longitude: longitude, apiKey: apiKey, context: contexts.elevation, client: client)
    }

    public struct Contexts: Sendable {
        public var airQuality: URL
        public var climateChange: URL
        public var elevation: URL
        public var ensemble: URL
        public var flood: URL
        public var forecast: URL
        public var geocodingGet: URL
        public var geocodingSearch: URL
        public var historical: URL
        public var marine: URL

        public static let `default` = Contexts()

        public init(
            airQuality: URL = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!,
            climateChange: URL = URL(string: "https://climate-api.open-meteo.com/v1/climate")!,
            elevation: URL = URL(string: "https://api.open-meteo.com/v1/elevation")!,
            ensemble: URL = URL(string: "https://ensemble-api.open-meteo.com/v1/ensemble")!,
            flood: URL = URL(string: "https://flood-api.open-meteo.com/v1/flood")!,
            forecast: URL = URL(string: "https://api.open-meteo.com/v1/forecast")!,
            geocodingGet: URL = URL(string: "https://geocoding-api.open-meteo.com/v1/get")!,
            geocodingSearch: URL = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!,
            historical: URL = URL(string: "https://archive-api.open-meteo.com/v1/archive")!,
            marine: URL = URL(string: "https://marine-api.open-meteo.com/v1/marine")!
        ) {
            self.airQuality = airQuality
            self.climateChange = climateChange
            self.elevation = elevation
            self.ensemble = ensemble
            self.flood = flood
            self.forecast = forecast
            self.geocodingGet = geocodingGet
            self.geocodingSearch = geocodingSearch
            self.historical = historical
            self.marine = marine
        }
    }
}

public struct OpenMeteoClient: Sendable {
    public static let shared = OpenMeteoClient()

    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    public var decoder: JSONDecoder

    public init(
        decoder: JSONDecoder = OpenMeteoClient.makeDecoder(),
        transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = { request in
            try await URLSession.shared.data(for: request)
        }
    ) {
        self.decoder = decoder
        self.transport = transport
    }

    public func fetch<Response: Decodable>(_ type: Response.Type = Response.self, endpoint: URL, query: OpenMeteoQuery) async throws -> Response {
        let url = try endpoint.appending(query: query)
        var request = URLRequest(url: query.usesCommercialHost ? url.withCustomerHostPrefix() : url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenMeteoError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try decoder.decode(Response.self, from: data)
        case 400:
            throw (try? decoder.decode(BadRequest.self, from: data)) ?? OpenMeteoError.httpStatus(httpResponse.statusCode, nil)
        default:
            throw OpenMeteoError.httpStatus(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

public protocol OpenMeteoQuery: Sendable {
    var apiKey: String? { get }
    var forcesUnixTime: Bool { get }
    func queryItems() -> [URLQueryItem]
}

public extension OpenMeteoQuery {
    var forcesUnixTime: Bool { false }
    var usesCommercialHost: Bool { apiKey != nil }

    func baseItems() -> [URLQueryItem] {
        var items = queryItems()
        if forcesUnixTime, !items.contains(where: { $0.name == "timeformat" }) {
            items.append(URLQueryItem(name: "timeformat", value: "unixtime"))
        }
        if let apiKey {
            items.append(URLQueryItem(name: "apikey", value: apiKey))
        }
        return items
    }
}

public enum OpenMeteoError: Error, Equatable, LocalizedError {
    case invalidResponse
    case invalidURL
    case httpStatus(Int, String?)
    case geocodingResultNotFound

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server did not return an HTTP response."
        case .invalidURL:
            "The request URL could not be constructed."
        case let .httpStatus(code, message):
            "Open-Meteo returned HTTP \(code)" + (message.map { ": \($0)" } ?? ".")
        case .geocodingResultNotFound:
            "The geocoding search did not return a result."
        }
    }
}

public struct BadRequest: Error, Decodable, Equatable, Sendable {
    public let error: Bool
    public let reason: String
}

private extension URL {
    func appending(query: OpenMeteoQuery) throws -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            throw OpenMeteoError.invalidURL
        }
        components.queryItems = (components.queryItems ?? []) + query.baseItems()
        guard let url = components.url else {
            throw OpenMeteoError.invalidURL
        }
        return url
    }

    func withCustomerHostPrefix() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let host = components.host,
              !host.hasPrefix("customer-")
        else {
            return self
        }
        components.host = "customer-" + host
        return components.url ?? self
    }
}

public struct DateOnly: Hashable, Codable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var description: String { rawValue }
}

public struct Timezone: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public static let auto = Timezone("auto")
    public var rawValue: String

    public init(_ rawValue: String = "auto") {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var description: String { rawValue }
}

public enum TemperatureUnit: String, Codable, Sendable {
    case celsius
    case fahrenheit
}

public enum WindSpeedUnit: String, Codable, Sendable {
    case kilometresPerHour = "kmh"
    case metresPerSecond = "ms"
    case milesPerHour = "mph"
    case knots = "kn"
}

public enum PrecipitationUnit: String, Codable, Sendable {
    case millimeters = "mm"
    case inches = "inch"
}

public enum LengthUnit: String, Codable, Sendable {
    case metric
    case imperial
}

public enum CellSelection: String, Codable, Sendable {
    case land
    case sea
    case nearest
}

public enum ContentFormat: String, Codable, Sendable {
    case json
    case protobuf
}

extension Unit {
    
    public var foundationUnit: Dimension? {
        return switch self {
            case .celsius: UnitTemperature.celsius
            case .fahrenheit: UnitTemperature.fahrenheit
            case .millimeters: UnitLength.millimeters
            case .centimeters: UnitLength.centimeters
            case .meters: UnitLength.meters
            case .feet: UnitLength.feet
            case .kilometresPerHour: UnitSpeed.kilometersPerHour
            case .metresPerSecond: UnitSpeed.metersPerSecond
            case .milesPerHour: UnitSpeed.milesPerHour
            case .knots: UnitSpeed.knots
            case .hectopascals: UnitPressure.hectopascals
            case .kilopascals: UnitPressure.kilopascals
            case .seconds: UnitDuration.seconds
            case .hours: UnitDuration.hours
            default: nil
        }
    }

    public func measurement(value: Double) -> Measurement<Dimension>? {
        guard let foundationUnit else { return nil }
        return Measurement(value: value, unit: foundationUnit)
    }
    
}

public enum Unit: Hashable, Sendable, CustomStringConvertible {
    case unknown(String)
    case unixTime
    case dimensionless
    case weatherCode
    case percentage
    case decimalDegrees
    case celsius
    case fahrenheit
    case millimeters
    case inches
    case kilometresPerHour
    case metresPerSecond
    case milesPerHour
    case knots
    case centimeters
    case meters
    case feet
    case wattsPerSquareMeter
    case microgramsPerCubicMeter
    case grainsPerCubicMeter
    case seconds
    case hours
    case hectopascals
    case kilopascals
    case joulesPerKilogram
    case cubicMetersPerCubicMeter
    case megajoulesPerSquareMeter
    case geopotentialMeters
    case secondsInverse
    case gramsPerKilogram
    case unitedStatesAirQualityIndex
    case europeanAirQualityIndex
    case cubicMetersPerSecond

    public init(rawValue: String) {
        switch rawValue {
        case "unixtime": self = .unixTime
        case "": self = .dimensionless
        case "wmo code": self = .weatherCode
        case "%": self = .percentage
        case "°": self = .decimalDegrees
        case "°C": self = .celsius
        case "°F": self = .fahrenheit
        case "mm": self = .millimeters
        case "inch": self = .inches
        case "km/h": self = .kilometresPerHour
        case "m/s": self = .metresPerSecond
        case "mph": self = .milesPerHour
        case "kn": self = .knots
        case "cm": self = .centimeters
        case "m": self = .meters
        case "ft": self = .feet
        case "W/m²": self = .wattsPerSquareMeter
        case "μg/m³": self = .microgramsPerCubicMeter
        case "grains/m³": self = .grainsPerCubicMeter
        case "s": self = .seconds
        case "h": self = .hours
        case "hPa": self = .hectopascals
        case "kPa": self = .kilopascals
        case "J/kg": self = .joulesPerKilogram
        case "m³/m³": self = .cubicMetersPerCubicMeter
        case "MJ/m²": self = .megajoulesPerSquareMeter
        case "gpm": self = .geopotentialMeters
        case "s⁻¹": self = .secondsInverse
        case "g/kg": self = .gramsPerKilogram
        case "USAQI": self = .unitedStatesAirQualityIndex
        case "EAQI": self = .europeanAirQualityIndex
        case "m³/s": self = .cubicMetersPerSecond
        default: self = .unknown(rawValue)
        }
    }

    public var description: String {
        switch self {
        case let .unknown(value): value
        case .unixTime: "unixtime"
        case .dimensionless: ""
        case .weatherCode: "wmo code"
        case .percentage: "%"
        case .decimalDegrees: "°"
        case .celsius: "°C"
        case .fahrenheit: "°F"
        case .millimeters: "mm"
        case .inches: "inch"
        case .kilometresPerHour: "km/h"
        case .metresPerSecond: "m/s"
        case .milesPerHour: "mph"
        case .knots: "kn"
        case .centimeters: "cm"
        case .meters: "m"
        case .feet: "ft"
        case .wattsPerSquareMeter: "W/m²"
        case .microgramsPerCubicMeter: "μg/m³"
        case .grainsPerCubicMeter: "grains/m³"
        case .seconds: "s"
        case .hours: "h"
        case .hectopascals: "hPa"
        case .kilopascals: "kPa"
        case .joulesPerKilogram: "J/kg"
        case .cubicMetersPerCubicMeter: "m³/m³"
        case .megajoulesPerSquareMeter: "MJ/m²"
        case .geopotentialMeters: "gpm"
        case .secondsInverse: "s⁻¹"
        case .gramsPerKilogram: "g/kg"
        case .unitedStatesAirQualityIndex: "USAQI"
        case .europeanAirQualityIndex: "EAQI"
        case .cubicMetersPerSecond: "m³/s"
        }
    }
}

extension Unit: Codable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public enum WeatherCode: Int, Codable, Sendable, CustomStringConvertible {
    case unknown = -1
    case clear = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowFallSlight = 71
    case snowFallModerate = 73
    case snowFallHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstormSlight = 95
    case thunderstormSlightHail = 96
    case thunderstormHeavyHail = 99

    public var description: String {
        switch self {
        case .unknown: "Unknown"
        case .clear: "Clear"
        case .mainlyClear: "Mostly clear"
        case .partlyCloudy: "Partly cloudy"
        case .overcast: "Cloudy"
        case .fog: "Fog"
        case .depositingRimeFog: "Freezing fog"
        case .drizzleLight: "Light drizzle"
        case .drizzleModerate: "Drizzle"
        case .drizzleDense: "Heavy drizzle"
        case .freezingDrizzleLight: "Light freezing drizzle"
        case .freezingDrizzleDense: "Freezing drizzle"
        case .rainSlight: "Light rain"
        case .rainModerate: "Heavy rain"
        case .rainHeavy: "Heavy intensity rain"
        case .freezingRainLight: "Light freezing rain"
        case .freezingRainHeavy: "Freezing rain"
        case .snowFallSlight: "Light snow"
        case .snowFallModerate: "Snow"
        case .snowFallHeavy: "Heavy snow"
        case .snowGrains: "Snow grains"
        case .rainShowersSlight: "Slight rain showers"
        case .rainShowersModerate: "Moderate rain showers"
        case .rainShowersViolent: "Violent rain showers"
        case .snowShowersSlight: "Slight snow showers"
        case .snowShowersHeavy: "Heavy snow showers"
        case .thunderstormSlight: "Slight or moderate thunderstorm"
        case .thunderstormSlightHail: "Thunderstorm with slight hail"
        case .thunderstormHeavyHail: "Thunderstorm with heavy hail"
        }
    }
}

public struct CurrentWeather: Decodable, Sendable, Equatable {
    public let time: Date
    public let temperature: Double
    public let windSpeed: Double
    public let windDirection: Double
    public let weatherCode: WeatherCode
    public let isDay: Bool

    private enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case windSpeed = "windspeed"
        case windDirection = "winddirection"
        case weatherCode = "weathercode"
        case isDay
    }
    
    public init (time: Date, temperature: Double, windSpeed: Double, windDirection: Double, weatherCode: WeatherCode, isDay: Bool) {
        self.time = time
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.weatherCode = weatherCode
        self.isDay = isDay
    }
    
    public init () {
        self.time = Date()
        self.temperature = 0.0
        self.windSpeed = 0.0
        self.windDirection = 0.0
        self.weatherCode = WeatherCode.unknown
        self.isDay = true
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Double.self, forKey: .time)
        time = Date(timeIntervalSince1970: seconds)
        temperature = try container.decode(Double.self, forKey: .temperature)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        windDirection = try container.decode(Double.self, forKey: .windDirection)
        let code = try container.decode(Int.self, forKey: .weatherCode)
        weatherCode = WeatherCode(rawValue: code) ?? .unknown
        if let value = try? container.decode(Bool.self, forKey: .isDay) {
            isDay = value
        } else {
            isDay = try container.decode(Int.self, forKey: .isDay) != 0
        }
    }
}

public struct Variable: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var description: String { rawValue }
}

public extension Sequence where Element == Variable {
    var openMeteoValue: String { map(\.rawValue).joined(separator: ",") }
}

public struct UnitTimeSeries: Equatable, Sendable {
    
    public static func == (lhs: UnitTimeSeries, rhs: UnitTimeSeries) -> Bool {
        lhs.values.first?.time == rhs.values.first?.time &&
        lhs.values.first?.value == rhs.values.first?.value
    }
    
    public var unit: Unit
    public var values: [(time: Date, value: Double?)]
}

public protocol HasDailySeries {
    var dailyUnits: [String: Unit] { get }
    var dailyValues: [String: [Double?]] { get }
}

public protocol HasHourlySeries {
    var hourlyUnits: [String: Unit] { get }
    var hourlyValues: [String: [Double?]] { get }
}

public extension HasDailySeries {
    var daily: [Variable: UnitTimeSeries] {
        Self.series(units: dailyUnits, values: dailyValues)
    }
}

public extension HasHourlySeries {
    var hourly: [Variable: UnitTimeSeries] {
        Self.series(units: hourlyUnits, values: hourlyValues)
    }
}

private extension HasDailySeries {
    static func series(units: [String: Unit], values: [String: [Double?]]) -> [Variable: UnitTimeSeries] {
        let times = (values["time"] ?? []).compactMap { $0 }.map { Date(timeIntervalSince1970: $0) }
        return values.reduce(into: [:]) { result, item in
            guard item.key != "time", let unit = units[item.key] else { return }
            result[Variable(item.key)] = UnitTimeSeries(unit: unit, values: zip(times, item.value).map { ($0.0, $0.1) })
        }
    }
}

private extension HasHourlySeries {
    static func series(units: [String: Unit], values: [String: [Double?]]) -> [Variable: UnitTimeSeries] {
        let times = (values["time"] ?? []).compactMap { $0 }.map { Date(timeIntervalSince1970: $0) }
        return values.reduce(into: [:]) { result, item in
            guard item.key != "time", let unit = units[item.key] else { return }
            result[Variable(item.key)] = UnitTimeSeries(unit: unit, values: zip(times, item.value).map { ($0.0, $0.1) })
        }
    }
}

public struct WeatherResponse: Decodable, Sendable, HasDailySeries, HasHourlySeries {
    public let latitude: Double
    public let longitude: Double
    public let utcOffsetSeconds: Int
    public let timezone: Timezone
    public let timezoneAbbreviation: String
    public let generationtimeMs: Double
    public let elevation: Double?
    public let dailyUnits: [String: Unit]
    public let dailyValues: [String: [Double?]]
    public let hourlyUnits: [String: Unit]
    public let hourlyValues: [String: [Double?]]
    public let currentWeather: CurrentWeather?

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case utcOffsetSeconds
        case timezone
        case timezoneAbbreviation
        case generationtimeMs
        case elevation
        case dailyUnits
        case dailyValues = "daily"
        case hourlyUnits
        case hourlyValues = "hourly"
        case currentWeather
    }
    
    public init(
        latitude: Double = 0,
        longitude: Double = 0,
        utcOffsetSeconds: Int = 0,
        timezone: Timezone = Timezone("gmt"),
        timezoneAbbreviation: String = "",
        generationtimeMs: Double = 0,
        elevation: Double? = nil,
        dailyUnits: [String: Unit] = [:],
        dailyValues: [String: [Double?]] = [:],
        hourlyUnits: [String: Unit] = [:],
        hourlyValues: [String: [Double?]] = [:],
        currentWeather: CurrentWeather? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.utcOffsetSeconds = utcOffsetSeconds
        self.timezone = timezone
        self.timezoneAbbreviation = timezoneAbbreviation
        self.generationtimeMs = generationtimeMs
        self.elevation = elevation
        self.dailyUnits = dailyUnits
        self.dailyValues = dailyValues
        self.hourlyUnits = hourlyUnits
        self.hourlyValues = hourlyValues
        self.currentWeather = currentWeather
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        utcOffsetSeconds = try container.decode(Int.self, forKey: .utcOffsetSeconds)
        timezone = try container.decode(Timezone.self, forKey: .timezone)
        timezoneAbbreviation = try container.decode(String.self, forKey: .timezoneAbbreviation)
        generationtimeMs = try container.decode(Double.self, forKey: .generationtimeMs)
        elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        dailyUnits = try container.decodeIfPresent([String: Unit].self, forKey: .dailyUnits) ?? [:]
        dailyValues = try container.decodeIfPresent([String: [Double?]].self, forKey: .dailyValues) ?? [:]
        hourlyUnits = try container.decodeIfPresent([String: Unit].self, forKey: .hourlyUnits) ?? [:]
        hourlyValues = try container.decodeIfPresent([String: [Double?]].self, forKey: .hourlyValues) ?? [:]
        currentWeather = try container.decodeIfPresent(CurrentWeather.self, forKey: .currentWeather)
    }
}

public struct DailyResponse: Decodable, Sendable, HasDailySeries {
    public let latitude: Double
    public let longitude: Double
    public let utcOffsetSeconds: Int
    public let timezone: Timezone
    public let timezoneAbbreviation: String
    public let generationtimeMs: Double
    public let elevation: Double?
    public let dailyUnits: [String: Unit]
    public let dailyValues: [String: [Double?]]

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case utcOffsetSeconds
        case timezone
        case timezoneAbbreviation
        case generationtimeMs
        case elevation
        case dailyUnits
        case dailyValues = "daily"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        utcOffsetSeconds = try container.decode(Int.self, forKey: .utcOffsetSeconds)
        timezone = try container.decode(Timezone.self, forKey: .timezone)
        timezoneAbbreviation = try container.decode(String.self, forKey: .timezoneAbbreviation)
        generationtimeMs = try container.decode(Double.self, forKey: .generationtimeMs)
        elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        dailyUnits = try container.decodeIfPresent([String: Unit].self, forKey: .dailyUnits) ?? [:]
        dailyValues = try container.decodeIfPresent([String: [Double?]].self, forKey: .dailyValues) ?? [:]
    }
}

public struct HourlyResponse: Decodable, Sendable, HasHourlySeries {
    public let latitude: Double
    public let longitude: Double
    public let utcOffsetSeconds: Int
    public let timezone: Timezone
    public let timezoneAbbreviation: String
    public let generationtimeMs: Double
    public let elevation: Double?
    public let hourlyUnits: [String: Unit]
    public let hourlyValues: [String: [Double?]]

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case utcOffsetSeconds
        case timezone
        case timezoneAbbreviation
        case generationtimeMs
        case elevation
        case hourlyUnits
        case hourlyValues = "hourly"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        utcOffsetSeconds = try container.decode(Int.self, forKey: .utcOffsetSeconds)
        timezone = try container.decode(Timezone.self, forKey: .timezone)
        timezoneAbbreviation = try container.decode(String.self, forKey: .timezoneAbbreviation)
        generationtimeMs = try container.decode(Double.self, forKey: .generationtimeMs)
        elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
        hourlyUnits = try container.decodeIfPresent([String: Unit].self, forKey: .hourlyUnits) ?? [:]
        hourlyValues = try container.decodeIfPresent([String: [Double?]].self, forKey: .hourlyValues) ?? [:]
    }
}

public enum QueryEncoder {
    public static func items(_ pairs: [(String, Any?)]) -> [URLQueryItem] {
        pairs.compactMap { name, value in
            guard let value else { return nil }
            return URLQueryItem(name: name, value: stringify(value))
        }
    }
    
    private static func stringify(_ value: Any) -> String {
        return switch value {
            case let value as Bool: value ? "true" : "false"
            case let value as DateOnly: value.rawValue
            case let value as Timezone: value.rawValue
            case let value as Variable: value.rawValue
            case let value as [Variable]: value.openMeteoValue
            case let value as TemperatureUnit: value.rawValue
            case let value as WindSpeedUnit: value.rawValue
            case let value as PrecipitationUnit: value.rawValue
            case let value as LengthUnit: value.rawValue
            case let value as CellSelection: value.rawValue
            case let value as ContentFormat: value.rawValue
            case let value as [Double]: value.map { String($0) }.joined(separator: ",")
            default:  String(describing: value)
        }
    }

}

public enum Forecast {
    public static let context = URL(string: "https://api.open-meteo.com/v1/forecast")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> WeatherResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var daily: [Variable]?
        public var hourly: [Variable]?
        public var startDate: DateOnly?
        public var endDate: DateOnly?
        public var pastDays: Int?
        public var forecastDays: Int?
        public var currentWeather: Bool?
        public var timezone: Timezone?
        public var temperatureUnit: TemperatureUnit?
        public var windSpeedUnit: WindSpeedUnit?
        public var precipitationUnit: PrecipitationUnit?
        public var elevation: Double?
        public var models: String?
        public var cellSelection: CellSelection?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("daily", daily), ("hourly", hourly),
                ("start_date", startDate), ("end_date", endDate), ("past_days", pastDays), ("forecast_days", forecastDays),
                ("current_weather", currentWeather), ("timezone", timezone), ("temperature_unit", temperatureUnit),
                ("windspeed_unit", windSpeedUnit), ("precipitation_unit", precipitationUnit), ("elevation", elevation),
                ("models", models), ("cell_selection", cellSelection)
            ])
        }
    }
}

public enum Historical {
    public static let context = URL(string: "https://archive-api.open-meteo.com/v1/archive")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> WeatherResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var startDate: DateOnly
        public var endDate: DateOnly
        public var daily: [Variable]?
        public var hourly: [Variable]?
        public var timezone: Timezone?
        public var temperatureUnit: TemperatureUnit?
        public var windSpeedUnit: WindSpeedUnit?
        public var precipitationUnit: PrecipitationUnit?
        public var elevation: Double?
        public var models: String?
        public var cellSelection: CellSelection?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, startDate: DateOnly, endDate: DateOnly, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.startDate = startDate
            self.endDate = endDate
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("start_date", startDate), ("end_date", endDate),
                ("daily", daily), ("hourly", hourly), ("timezone", timezone), ("temperature_unit", temperatureUnit),
                ("windspeed_unit", windSpeedUnit), ("precipitation_unit", precipitationUnit), ("elevation", elevation),
                ("models", models), ("cell_selection", cellSelection)
            ])
        }
    }
}

public enum AirQuality {
    public static let context = URL(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> HourlyResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var hourly: [Variable]?
        public var startDate: DateOnly?
        public var endDate: DateOnly?
        public var pastDays: Int?
        public var timezone: Timezone?
        public var domains: String?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("hourly", hourly), ("start_date", startDate),
                ("end_date", endDate), ("past_days", pastDays), ("timezone", timezone), ("domains", domains)
            ])
        }
    }

    public enum Domains {
        public static let auto = "auto"
        public static let combine = auto
        public static let camsEurope = "cams_europe"
        public static let camsGlobal = "cams_global"
    }
}

public enum Ensemble {
    public static let context = URL(string: "https://ensemble-api.open-meteo.com/v1/ensemble")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> HourlyResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var hourly: [Variable]?
        public var startDate: DateOnly?
        public var endDate: DateOnly?
        public var pastDays: Int?
        public var forecastDays: Int?
        public var timezone: Timezone?
        public var temperatureUnit: TemperatureUnit?
        public var windSpeedUnit: WindSpeedUnit?
        public var precipitationUnit: PrecipitationUnit?
        public var elevation: Double?
        public var models: String?
        public var cellSelection: CellSelection?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("hourly", hourly), ("start_date", startDate),
                ("end_date", endDate), ("past_days", pastDays), ("forecast_days", forecastDays), ("timezone", timezone),
                ("temperature_unit", temperatureUnit), ("windspeed_unit", windSpeedUnit),
                ("precipitation_unit", precipitationUnit), ("elevation", elevation), ("models", models),
                ("cell_selection", cellSelection)
            ])
        }
    }
}

public enum Marine {
    public static let context = URL(string: "https://marine-api.open-meteo.com/v1/marine")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> WeatherResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var daily: [Variable]?
        public var hourly: [Variable]?
        public var startDate: DateOnly?
        public var endDate: DateOnly?
        public var pastDays: Int?
        public var timezone: Timezone?
        public var cellSelection: CellSelection?
        public var lengthUnit: LengthUnit?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("daily", daily), ("hourly", hourly),
                ("start_date", startDate), ("end_date", endDate), ("past_days", pastDays), ("timezone", timezone),
                ("cell_selection", cellSelection), ("length_unit", lengthUnit)
            ])
        }
    }
}

public enum Flood {
    public static let context = URL(string: "https://flood-api.open-meteo.com/v1/flood")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> DailyResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var daily: [Variable]?
        public var pastDays: Int?
        public var forecastDays: Int?
        public var startDate: DateOnly?
        public var endDate: DateOnly?
        public var ensemble: Bool?
        public var models: String?
        public var cellSelection: CellSelection?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("daily", daily), ("past_days", pastDays),
                ("forecast_days", forecastDays), ("start_date", startDate), ("end_date", endDate),
                ("ensemble", ensemble), ("models", models), ("cell_selection", cellSelection)
            ])
        }
    }
}

public enum ClimateChange {
    public static let context = URL(string: "https://climate-api.open-meteo.com/v1/climate")!

    public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> DailyResponse {
        try await client.fetch(endpoint: context, query: query)
    }

    public struct Query: OpenMeteoQuery {
        public var latitude: Double
        public var longitude: Double
        public var models: String
        public var startDate: DateOnly
        public var endDate: DateOnly
        public var daily: [Variable]?
        public var temperatureUnit: TemperatureUnit?
        public var windSpeedUnit: WindSpeedUnit?
        public var precipitationUnit: PrecipitationUnit?
        public var elevation: Double?
        public var disableBiasCorrection: Bool?
        public var cellSelection: CellSelection?
        public var apiKey: String?

        public init(latitude: Double, longitude: Double, models: String, startDate: DateOnly, endDate: DateOnly, apiKey: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.models = models
            self.startDate = startDate
            self.endDate = endDate
            self.apiKey = apiKey
        }

        public var forcesUnixTime: Bool { true }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([
                ("latitude", latitude), ("longitude", longitude), ("models", models), ("start_date", startDate),
                ("end_date", endDate), ("daily", daily), ("temperature_unit", temperatureUnit),
                ("windspeed_unit", windSpeedUnit), ("precipitation_unit", precipitationUnit), ("elevation", elevation),
                ("disable_bias_correction", disableBiasCorrection), ("cell_selection", cellSelection)
            ])
        }
    }
}

public enum Elevation {
    public static let context = URL(string: "https://api.open-meteo.com/v1/elevation")!

    public static func fetch(latitude: Double, longitude: Double, apiKey: String? = nil, context: URL = context, client: OpenMeteoClient = .shared) async throws -> Response {
        try await fetch(latitudes: [latitude], longitudes: [longitude], apiKey: apiKey, context: context, client: client)
    }

    public static func fetch(latitudes: [Double], longitudes: [Double], apiKey: String? = nil, context: URL = context, client: OpenMeteoClient = .shared) async throws -> Response {
        try await client.fetch(endpoint: context, query: Query(latitudes: latitudes, longitudes: longitudes, apiKey: apiKey))
    }

    public struct Query: OpenMeteoQuery {
        public var latitudes: [Double]
        public var longitudes: [Double]
        public var apiKey: String?

        public init(latitudes: [Double], longitudes: [Double], apiKey: String? = nil) {
            self.latitudes = latitudes
            self.longitudes = longitudes
            self.apiKey = apiKey
        }

        public func queryItems() -> [URLQueryItem] {
            QueryEncoder.items([("latitude", latitudes), ("longitude", longitudes)])
        }
    }

    public struct Response: Decodable, Sendable, Equatable {
        public let elevation: [Double]
    }
}

public enum Geocoding {
    public enum Search {
        public static let context = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

        public static func fetch(_ query: Query, context: URL = context, client: OpenMeteoClient = .shared) async throws -> Response {
            try await client.fetch(endpoint: context, query: query)
        }

        public static func first(name: String, language: String? = nil, apiKey: String? = nil, context: URL = context, client: OpenMeteoClient = .shared) async throws -> Geocoding.Place {
            var query = Query(name: name, apiKey: apiKey)
            query.count = 1
            query.language = language
            let response = try await fetch(query, context: context, client: client)
            guard let place = response.results.first else {
                throw OpenMeteoError.geocodingResultNotFound
            }
            return place
        }

        public struct Query: OpenMeteoQuery {
            public var name: String
            public var count: Int?
            public var language: String?
            public var apiKey: String?

            public init(name: String, count: Int? = nil, language: String? = nil, apiKey: String? = nil) {
                precondition(name.count > 1, "Open-Meteo geocoding search names must contain at least two characters.")
                self.name = name
                self.count = count
                self.language = language
                self.apiKey = apiKey
            }

            public func queryItems() -> [URLQueryItem] {
                QueryEncoder.items([("name", name), ("count", count), ("language", language), ("format", ContentFormat.json)])
            }
        }

        public struct Response: Decodable, Sendable {
            public let results: [Geocoding.Place]
            public let generationtimeMs: Double
        }
    }

    public enum Get {
        public static let context = URL(string: "https://geocoding-api.open-meteo.com/v1/get")!

        public static func fetch(id: Int, language: String? = nil, apiKey: String? = nil, context: URL = context, client: OpenMeteoClient = .shared) async throws -> Geocoding.Place {
            try await client.fetch(endpoint: context, query: Query(id: id, language: language, apiKey: apiKey))
        }

        public struct Query: OpenMeteoQuery {
            public var id: Int
            public var language: String?
            public var apiKey: String?

            public init(id: Int, language: String? = nil, apiKey: String? = nil) {
                self.id = id
                self.language = language
                self.apiKey = apiKey
            }

            public func queryItems() -> [URLQueryItem] {
                QueryEncoder.items([("id", id), ("language", language), ("format", ContentFormat.json)])
            }
        }
    }

    public struct Place: Decodable, Sendable, Equatable {
        public let id: Int
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let ranking: Double?
        public let elevation: Double?
        public let featureCode: String?
        public let countryCode: String?
        public let admin1Id: Int?
        public let admin2Id: Int?
        public let admin3Id: Int?
        public let admin4Id: Int?
        public let timezone: Timezone?
        public let population: Int?
        public let postcodes: [String]?
        public let countryId: Int?
        public let country: String?
        public let admin1: String?
        public let admin2: String?
        public let admin3: String?
        public let admin4: String?
    }
}
