import XCTest
@testable import OpenMeteo

final class OpenMeteoTests: XCTestCase {
    func testForecastQueryEncodingMatchesKotlinShape() throws {
        var query = Forecast.Query(latitude: 52.3738, longitude: 4.891)
        query.daily = [.init("weathercode"), Forecast.Daily.temperature2mMax]
        query.windSpeedUnit = .knots
        query.timezone = .auto
        query.pastDays = 1

        let items = Dictionary(uniqueKeysWithValues: query.baseItems().map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(items["latitude"], "52.3738")
        XCTAssertEqual(items["longitude"], "4.891")
        XCTAssertEqual(items["daily"], "weathercode,temperature_2m_max")
        XCTAssertEqual(items["windspeed_unit"], "kn")
        XCTAssertEqual(items["timezone"], "auto")
        XCTAssertEqual(items["past_days"], "1")
        XCTAssertEqual(items["timeformat"], "unixtime")
    }

    func testWeatherResponseDecodesDynamicSeries() throws {
        let json = """
        {
          "latitude": 52.36,
          "longitude": 4.90,
          "utc_offset_seconds": 3600,
          "timezone": "Europe/Amsterdam",
          "timezone_abbreviation": "GMT+1",
          "generationtime_ms": 0.12,
          "elevation": 17,
          "daily_units": {
            "time": "unixtime",
            "temperature_2m_max": "°C"
          },
          "daily": {
            "time": [1704067200, 1704153600],
            "temperature_2m_max": [8.5, null]
          }
        }
        """.data(using: .utf8)!

        let response = try OpenMeteoClient.makeDecoder().decode(WeatherResponse.self, from: json)
        let series = try XCTUnwrap(response.daily[Forecast.Daily.temperature2mMax])

        XCTAssertEqual(series.unit, .celsius)
        XCTAssertEqual(series.values.count, 2)
        XCTAssertEqual(series.values[0].value, 8.5)
        XCTAssertNil(series.values[1].value)
    }

    func testGeocodingSearchUsesJsonFormat() {
        let query = Geocoding.Search.Query(name: "Tokyo", count: 1, language: "en")
        let items = Dictionary(uniqueKeysWithValues: query.baseItems().map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(items["name"], "Tokyo")
        XCTAssertEqual(items["count"], "1")
        XCTAssertEqual(items["language"], "en")
        XCTAssertEqual(items["format"], "json")
    }
}
