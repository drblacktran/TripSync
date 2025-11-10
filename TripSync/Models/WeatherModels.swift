//
//  WeatherModels.swift
//  TripSync
//
//  Created by Tien Tran on 6/11/2025.
//

import Foundation

// MARK: - Weather Forecast Models

struct WeatherForecast: Codable {
    let timestamp: Date
    let temperature: Double      // °C
    let feelsLike: Double        // °C
    let tempMin: Double          // °C
    let tempMax: Double          // °C
    let condition: String        // "Clear", "Clouds", "Rain", etc.
    let description: String      // "scattered clouds", "light rain"
    let icon: String             // "04d" for icon code
    let humidity: Int            // %
    let windSpeed: Double        // m/s
    let pressure: Int            // hPa
    let cloudiness: Int          // %
}

struct DayWeather: Codable {
    let date: Date
    let hourlyForecasts: [WeatherForecast]  // 3-hour intervals
}

// MARK: - OpenWeatherMap API Response Models

struct OpenWeatherResponse: Codable {
    let list: [OpenWeatherItem]
    let city: OpenWeatherCity
}

struct OpenWeatherItem: Codable {
    let dt: TimeInterval  // Unix timestamp
    let main: OpenWeatherMain
    let weather: [OpenWeatherCondition]
    let clouds: OpenWeatherClouds
    let wind: OpenWeatherWind
    let sys: OpenWeatherSys
}

struct OpenWeatherMain: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

struct OpenWeatherCondition: Codable {
    let main: String
    let description: String
    let icon: String
}

struct OpenWeatherClouds: Codable {
    let all: Int  // Cloudiness %
}

struct OpenWeatherWind: Codable {
    let speed: Double
}

struct OpenWeatherSys: Codable {
    let pod: String  // Part of day: "d" or "n"
}

struct OpenWeatherCity: Codable {
    let name: String
    let country: String
}

// MARK: - Temperature Unit Enum

enum TemperatureUnit: String, Codable {
    case celsius = "metric"
    case fahrenheit = "imperial"
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}
