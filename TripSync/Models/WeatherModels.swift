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
    
    // Helper to get SF Symbol name based on weather condition
    var sfSymbolName: String {
        switch condition.lowercased() {
        case "clear":
            return icon.contains("d") ? "sun.max.fill" : "moon.stars.fill"
        case "clouds":
            if cloudiness > 75 {
                return "cloud.fill"
            } else {
                return icon.contains("d") ? "cloud.sun.fill" : "cloud.moon.fill"
            }
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.fill"
        }
    }
    
    // Helper to format temperature based on unit preference
    func formattedTemperature(unit: TemperatureUnit) -> String {
        let temp: Double
        let symbol: String
        
        switch unit {
        case .celsius:
            temp = temperature
            symbol = "°C"
        case .fahrenheit:
            temp = (temperature * 9/5) + 32
            symbol = "°F"
        }
        
        return String(format: "%.0f%@", temp, symbol)
    }
}

struct DayWeather: Codable {
    let date: Date
    let hourlyForecasts: [WeatherForecast]  // 3-hour intervals
    
    // Get weather closest to a specific hour
    func weatherAt(hour: Int) -> WeatherForecast? {
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard var targetDate = calendar.date(from: targetComponents) else {
            return hourlyForecasts.first
        }
        
        targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) ?? targetDate
        
        // Find closest forecast to target time
        let closest = hourlyForecasts.min { forecast1, forecast2 in
            abs(forecast1.timestamp.timeIntervalSince(targetDate)) <
            abs(forecast2.timestamp.timeIntervalSince(targetDate))
        }
        
        return closest
    }
    
    // Get average temperature for the day
    var averageTemperature: Double {
        guard !hourlyForecasts.isEmpty else { return 0 }
        let sum = hourlyForecasts.reduce(0.0) { $0 + $1.temperature }
        return sum / Double(hourlyForecasts.count)
    }
    
    // Most common weather condition for the day
    var dominantCondition: String {
        let conditions = hourlyForecasts.map { $0.condition }
        let counted = conditions.reduce(into: [:]) { counts, condition in
            counts[condition, default: 0] += 1
        }
        return counted.max(by: { $0.value < $1.value })?.key ?? "Clear"
    }
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
