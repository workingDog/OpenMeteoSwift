public extension Forecast {
    enum Daily {
        public static let weatherCode: Variable = "weathercode"
        public static let temperature2mMax: Variable = "temperature_2m_max"
        public static let temperature2mMin: Variable = "temperature_2m_min"
        public static let apparentTemperatureMax: Variable = "apparent_temperature_max"
        public static let apparentTemperatureMin: Variable = "apparent_temperature_min"
        public static let sunrise: Variable = "sunrise"
        public static let sunset: Variable = "sunset"
        public static let uvIndexMax: Variable = "uv_index_max"
        public static let uvIndexClearSkyMax: Variable = "uv_index_clear_sky_max"
        public static let precipitationSum: Variable = "precipitation_sum"
        public static let rainSum: Variable = "rain_sum"
        public static let showersSum: Variable = "showers_sum"
        public static let snowfallSum: Variable = "snowfall_sum"
        public static let precipitationHours: Variable = "precipitation_hours"
        public static let precipitationProbabilityMax: Variable = "precipitation_probability_max"
        public static let windSpeed10mMax: Variable = "windspeed_10m_max"
        public static let windGusts10mMax: Variable = "windgusts_10m_max"
        public static let windDirection10mDominant: Variable = "winddirection_10m_dominant"
        public static let shortwaveRadiationSum: Variable = "shortwave_radiation_sum"
        public static let et0FaoEvapotranspiration: Variable = "et0_fao_evapotranspiration"
    }

    enum Hourly {
        public static let temperature2m: Variable = "temperature_2m"
        public static let relativeHumidity2m: Variable = "relativehumidity_2m"
        public static let dewPoint2m: Variable = "dewpoint_2m"
        public static let apparentTemperature: Variable = "apparent_temperature"
        public static let precipitationProbability: Variable = "precipitation_probability"
        public static let precipitation: Variable = "precipitation"
        public static let rain: Variable = "rain"
        public static let showers: Variable = "showers"
        public static let snowfall: Variable = "snowfall"
        public static let snowDepth: Variable = "snow_depth"
        public static let weatherCode: Variable = "weathercode"
        public static let pressureMsl: Variable = "pressure_msl"
        public static let surfacePressure: Variable = "surface_pressure"
        public static let cloudCover: Variable = "cloudcover"
        public static let cloudCoverLow: Variable = "cloudcover_low"
        public static let cloudCoverMid: Variable = "cloudcover_mid"
        public static let cloudCoverHigh: Variable = "cloudcover_high"
        public static let visibility: Variable = "visibility"
        public static let evapotranspiration: Variable = "evapotranspiration"
        public static let vaporPressureDeficit: Variable = "vapor_pressure_deficit"
        public static let windSpeed10m: Variable = "windspeed_10m"
        public static let windDirection10m: Variable = "winddirection_10m"
        public static let windGusts10m: Variable = "windgusts_10m"
        public static let uvIndex: Variable = "uv_index"
        public static let isDay: Variable = "is_day"
        public static let cape: Variable = "cape"
        public static let shortwaveRadiation: Variable = "shortwave_radiation"
        public static let directRadiation: Variable = "direct_radiation"
        public static let diffuseRadiation: Variable = "diffuse_radiation"
        public static let directNormalIrradiance: Variable = "direct_normal_irradiance"
        public static let terrestrialRadiation: Variable = "terrestrial_radiation"
        public static func pressureLevelTemperature(_ hPa: Int) -> Variable { Variable("temperature_\(hPa)hPa") }
        public static func pressureLevelRelativeHumidity(_ hPa: Int) -> Variable { Variable("relativehumidity_\(hPa)hPa") }
        public static func pressureLevelCloudCover(_ hPa: Int) -> Variable { Variable("cloudcover_\(hPa)hPa") }
    }

    enum Models {
        public static let bestMatch = "best_match"
        public static let ecmwfIfs04 = "ecmwf_ifs04"
        public static let metnoNordic = "metno_nordic"
        public static let gfsSeamless = "gfs_seamless"
        public static let gfsGlobal = "gfs_global"
        public static let gfsHrrr = "gfs_hrrr"
        public static let jmaSeamless = "jma_seamless"
        public static let jmaMsm = "jma_msm"
        public static let jmaGsm = "jma_gsm"
        public static let iconSeamless = "icon_seamless"
        public static let iconGlobal = "icon_global"
        public static let iconEu = "icon_eu"
        public static let iconD2 = "icon_d2"
        public static let gemSeamless = "gem_seamless"
        public static let gemGlobal = "gem_global"
        public static let gemRegional = "gem_regional"
        public static let gemHrdpsContinental = "gem_hrdps_continental"
        public static let meteofranceSeamless = "meteofrance_seamless"
        public static let meteofranceArpegeWorld = "meteofrance_arpege_world"
        public static let meteofranceArpegeEurope = "meteofrance_arpege_europe"
        public static let meteofranceAromeFrance = "meteofrance_arome_france"
        public static let meteofranceAromeFranceHd = "meteofrance_arome_france_hd"
    }
}

public extension Historical {
    enum Daily {
        public static let weatherCode: Variable = "weathercode"
        public static let temperature2mMax: Variable = "temperature_2m_max"
        public static let temperature2mMin: Variable = "temperature_2m_min"
        public static let temperature2mMean: Variable = "temperature_2m_mean"
        public static let apparentTemperatureMax: Variable = "apparent_temperature_max"
        public static let apparentTemperatureMin: Variable = "apparent_temperature_min"
        public static let apparentTemperatureMean: Variable = "apparent_temperature_mean"
        public static let sunrise: Variable = "sunrise"
        public static let sunset: Variable = "sunset"
        public static let shortwaveRadiationSum: Variable = "shortwave_radiation_sum"
        public static let precipitationSum: Variable = "precipitation_sum"
        public static let rainSum: Variable = "rain_sum"
        public static let snowfallSum: Variable = "snowfall_sum"
        public static let precipitationHours: Variable = "precipitation_hours"
        public static let windSpeed10mMax: Variable = "windspeed_10m_max"
        public static let windGusts10mMax: Variable = "windgusts_10m_max"
        public static let windDirection10mDominant: Variable = "winddirection_10m_dominant"
        public static let et0FaoEvapotranspiration: Variable = "et0_fao_evapotranspiration"
    }

    enum Hourly {
        public static let temperature2m: Variable = "temperature_2m"
        public static let relativeHumidity2m: Variable = "relativehumidity_2m"
        public static let dewPoint2m: Variable = "dewpoint_2m"
        public static let apparentTemperature: Variable = "apparent_temperature"
        public static let pressureMsl: Variable = "pressure_msl"
        public static let surfacePressure: Variable = "surface_pressure"
        public static let precipitation: Variable = "precipitation"
        public static let rain: Variable = "rain"
        public static let snowfall: Variable = "snowfall"
        public static let weatherCode: Variable = "weathercode"
        public static let cloudCover: Variable = "cloudcover"
        public static let shortwaveRadiation: Variable = "shortwave_radiation"
        public static let directRadiation: Variable = "direct_radiation"
        public static let diffuseRadiation: Variable = "diffuse_radiation"
        public static let windSpeed10m: Variable = "windspeed_10m"
        public static let windSpeed100m: Variable = "windspeed_100m"
        public static let windDirection10m: Variable = "winddirection_10m"
        public static let windDirection100m: Variable = "winddirection_100m"
        public static let windGusts10m: Variable = "windgusts_10m"
    }

    enum Models {
        public static let bestMatch = "best_match"
        public static let era5 = "era5"
        public static let era5Land = "era5_land"
        public static let cerra = "cerra"
        public static let ecmwfIfs = "ecmwf_ifs"
    }
}

public extension AirQuality {
    enum Hourly {
        public static let pm10: Variable = "pm10"
        public static let pm25: Variable = "pm2_5"
        public static let carbonMonoxide: Variable = "carbon_monoxide"
        public static let nitrogenDioxide: Variable = "nitrogen_dioxide"
        public static let sulphurDioxide: Variable = "sulphur_dioxide"
        public static let ozone: Variable = "ozone"
        public static let aerosolOpticalDepth: Variable = "aerosol_optical_depth"
        public static let dust: Variable = "dust"
        public static let uvIndex: Variable = "uv_index"
        public static let uvIndexClearSky: Variable = "uv_index_clear_sky"
        public static let ammonia: Variable = "ammonia"
        public static let alderPollen: Variable = "alder_pollen"
        public static let birchPollen: Variable = "birch_pollen"
        public static let grassPollen: Variable = "grass_pollen"
        public static let mugwortPollen: Variable = "mugwort_pollen"
        public static let olivePollen: Variable = "olive_pollen"
        public static let ragweedPollen: Variable = "ragweed_pollen"
        public static let europeanAqi: Variable = "european_aqi"
        public static let europeanAqiPm25: Variable = "european_aqi_pm2_5"
        public static let europeanAqiPm10: Variable = "european_aqi_pm10"
        public static let usAqi: Variable = "us_aqi"
        public static let usAqiPm25: Variable = "us_aqi_pm2_5"
        public static let usAqiPm10: Variable = "us_aqi_pm10"
    }
}

public extension Marine {
    enum Hourly {
        public static let waveHeight: Variable = "wave_height"
        public static let waveDirection: Variable = "wave_direction"
        public static let wavePeriod: Variable = "wave_period"
        public static let windWaveHeight: Variable = "wind_wave_height"
        public static let windWaveDirection: Variable = "wind_wave_direction"
        public static let windWavePeriod: Variable = "wind_wave_period"
        public static let windWavePeakPeriod: Variable = "wind_wave_peak_period"
        public static let swellWaveHeight: Variable = "swell_wave_height"
        public static let swellWaveDirection: Variable = "swell_wave_direction"
        public static let swellWavePeriod: Variable = "swell_wave_period"
        public static let swellWavePeakPeriod: Variable = "swell_wave_peak_period"
    }

    enum Daily {
        public static let waveHeightMax: Variable = "wave_height_max"
        public static let waveDirectionDominant: Variable = "wave_direction_dominant"
        public static let wavePeriodMax: Variable = "wave_period_max"
        public static let windWaveHeightMax: Variable = "wind_wave_height_max"
        public static let windWaveDirectionDominant: Variable = "wind_wave_direction_dominant"
        public static let windWavePeriodMax: Variable = "wind_wave_period_max"
        public static let windWavePeakPeriodMax: Variable = "wind_wave_peak_period_max"
        public static let swellWaveHeightMax: Variable = "swell_wave_height_max"
        public static let swellWaveDirectionDominant: Variable = "swell_wave_direction_dominant"
        public static let swellWavePeriodMax: Variable = "swell_wave_period_max"
        public static let swellWavePeakPeriodMax: Variable = "swell_wave_peak_period_max"
    }
}

public extension Flood {
    enum Daily {
        public static let riverDischarge: Variable = "river_discharge"
        public static let riverDischargeMean: Variable = "river_discharge_mean"
        public static let riverDischargeMedian: Variable = "river_discharge_median"
        public static let riverDischargeMax: Variable = "river_discharge_max"
        public static let riverDischargeMin: Variable = "river_discharge_min"
        public static let riverDischargeP25: Variable = "river_discharge_p25"
        public static let riverDischargeP75: Variable = "river_discharge_p75"
    }

    enum Models {
        public static let seamlessV3 = "seamless_v3"
        public static let forecastV3 = "forecast_v3"
        public static let consolidatedV3 = "consolidated_v3"
    }
}

public extension Ensemble {
    enum Hourly {
        public static let temperature2m: Variable = "temperature_2m"
        public static let relativeHumidity2m: Variable = "relativehumidity_2m"
        public static let dewPoint2m: Variable = "dewpoint_2m"
        public static let apparentTemperature: Variable = "apparent_temperature"
        public static let precipitation: Variable = "precipitation"
        public static let rain: Variable = "rain"
        public static let snowfall: Variable = "snowfall"
        public static let snowDepth: Variable = "snow_depth"
        public static let weatherCode: Variable = "weathercode"
        public static let pressureMsl: Variable = "pressure_msl"
        public static let surfacePressure: Variable = "surface_pressure"
        public static let cloudCover: Variable = "cloudcover"
        public static let visibility: Variable = "visibility"
        public static let windSpeed10m: Variable = "windspeed_10m"
        public static let windDirection10m: Variable = "winddirection_10m"
        public static let windGusts10m: Variable = "windgusts_10m"
    }

    enum Models {
        public static let iconSeamless = "icon_seamless"
        public static let iconGlobal = "icon_global"
        public static let iconEu = "icon_eu"
        public static let iconD2 = "icon_d2"
        public static let gfsSeamless = "gfs_seamless"
        public static let gfs025 = "gfs025"
        public static let gfs05 = "gfs05"
        public static let ecmwfIfs04 = "ecmwf_ifs04"
        public static let gemGlobal = "gem_global"
    }
}

public extension ClimateChange {
    enum Daily {
        public static let temperature2mMean: Variable = "temperature_2m_mean"
        public static let temperature2mMax: Variable = "temperature_2m_max"
        public static let temperature2mMin: Variable = "temperature_2m_min"
        public static let windSpeed10mMean: Variable = "windspeed_10m_mean"
        public static let windSpeed10mMax: Variable = "windspeed_10m_max"
        public static let cloudCoverMean: Variable = "cloudcover_mean"
        public static let shortwaveRadiationSum: Variable = "shortwave_radiation_sum"
        public static let relativeHumidity2mMean: Variable = "relative_humidity_2m_mean"
        public static let dewPoint2mMean: Variable = "dewpoint_2m_mean"
        public static let precipitationSum: Variable = "precipitation_sum"
        public static let rainSum: Variable = "rain_sum"
        public static let snowfallSum: Variable = "snowfall_sum"
        public static let pressureMslMean: Variable = "pressure_msl_mean"
        public static let et0FaoEvapotranspirationSum: Variable = "et0_fao_evapotranspiration_sum"
        public static let vaporPressureDeficitMean: Variable = "vapor_pressure_deficit_mean"
    }

    enum Models {
        public static let CMCCCM2VHR4 = "CMCC_CM2_VHR4"
        public static let FGOALSF3H = "FGOALS_f3_H"
        public static let HiRAMSITHR = "HiRAM_SIT_HR"
        public static let MRIAGCM32S = "MRI_AGCM3_2_S"
        public static let ECEarth3PHR = "EC_Earth3P_HR"
        public static let MPIESM12XR = "MPI_ESM1_2_XR"
        public static let NICAM168S = "NICAM16_8S"
    }
}
