# OpenMeteoSwift

A Swift Package for the [Open-Meteo](https://open-meteo.com/) APIs.

**Open-Meteo** is an open-source weather API and offers free access for non-commercial use. No API key is required. You can use it immediately!


## Design

- Async/await transport built on `URLSession`.
- Endpoint-specific query structs for forecast, historical, air quality, ensemble, marine, flood, climate, elevation, and geocoding.
- Shared query encoding.
- Commercial API key handling with the `customer-` host prefix used by Open-Meteo.
- Dynamic daily/hourly response tables that glue units and timestamped values into `UnitTimeSeries`.
- Field catalogs such as `Forecast.Hourly.temperature2m` and `Marine.Daily.waveHeightMax`, while still allowing custom `Variable("...")` values.

## Example

```swift
import OpenMeteo

let openMeteo = OpenMeteo(latitude: 52.3738, longitude: 4.8910)
let forecast = try await openMeteo.forecast {
    $0.daily = [
        Forecast.Daily.weatherCode,
        Forecast.Daily.temperature2mMax,
        Forecast.Daily.temperature2mMin
    ]
    $0.windSpeedUnit = .knots
    $0.timezone = .auto
    $0.pastDays = 1
}

if let maxTemperature = forecast.daily[Forecast.Daily.temperature2mMax] {
    print(maxTemperature.unit)
    print(maxTemperature.values)
}
```

## Geocoding

```swift
let place = try await Geocoding.Search.first(name: "Tokyo", language: "en")
let openMeteo = OpenMeteo(latitude: place.latitude, longitude: place.longitude)
```

## Reference

-   [Open-Meteo](https://open-meteo.com/), "Free weather forecast and historical weather API — 30+ models, historical weather from 1940, no API key required."
