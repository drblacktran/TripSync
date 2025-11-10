//
//  WeatherFormatter.swift
//  TripSync
//
//  Utility class for formatting and processing weather data
//

import Foundation

class WeatherFormatter {
    
    // MARK: - SF Symbol Icons
    
    /// Get SF Symbol name for weather condition
    static func sfSymbolName(for forecast: WeatherForecast) -> String {
        switch forecast.condition.lowercased() {
        case "clear":
            return forecast.icon.contains("d") ? "sun.max.fill" : "moon.stars.fill"
        case "clouds":
            if forecast.cloudiness > 75 {
                return "cloud.fill"
            } else {
                return forecast.icon.contains("d") ? "cloud.sun.fill" : "cloud.moon.fill"
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
    
    // MARK: - Temperature Formatting
    
    /// Format temperature with unit conversion
    static func formattedTemperature(_ celsius: Double, unit: TemperatureUnit) -> String {
        let temp: Double
        let symbol: String
        
        switch unit {
        case .celsius:
            temp = celsius
            symbol = "°C"
        case .fahrenheit:
            temp = (celsius * 9/5) + 32
            symbol = "°F"
        }
        
        return String(format: "%.0f%@", temp, symbol)
    }
    
    // MARK: - DayWeather Utilities
    
    /// Get weather forecast closest to a specific hour
    static func weatherAt(hour: Int, in dayWeather: DayWeather) -> WeatherForecast? {
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: dayWeather.date)
        
        guard var targetDate = calendar.date(from: targetComponents) else {
            return dayWeather.hourlyForecasts.first
        }
        
        targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) ?? targetDate
        
        // Find closest forecast to target time
        let closest = dayWeather.hourlyForecasts.min { forecast1, forecast2 in
            abs(forecast1.timestamp.timeIntervalSince(targetDate)) <
            abs(forecast2.timestamp.timeIntervalSince(targetDate))
        }
        
        return closest
    }
    
    /// Get average temperature for the day
    static func averageTemperature(for dayWeather: DayWeather) -> Double {
        guard !dayWeather.hourlyForecasts.isEmpty else { return 0 }
        let sum = dayWeather.hourlyForecasts.reduce(0.0) { $0 + $1.temperature }
        return sum / Double(dayWeather.hourlyForecasts.count)
    }
    
    /// Get most common weather condition for the day
    static func dominantCondition(for dayWeather: DayWeather) -> String {
        let conditions = dayWeather.hourlyForecasts.map { $0.condition }
        let counted = conditions.reduce(into: [:]) { counts, condition in
            counts[condition, default: 0] += 1
        }
        return counted.max(by: { $0.value < $1.value })?.key ?? "Clear"
    }
    
    /// Get temperature range for the day
    static func temperatureRange(for dayWeather: DayWeather, unit: TemperatureUnit) -> String {
        guard !dayWeather.hourlyForecasts.isEmpty else { return "N/A" }
        
        let temps = dayWeather.hourlyForecasts.map { $0.temperature }
        let min = temps.min() ?? 0
        let max = temps.max() ?? 0
        
        let minFormatted = formattedTemperature(min, unit: unit)
        let maxFormatted = formattedTemperature(max, unit: unit)
        
        return "\(minFormatted) - \(maxFormatted)"
    }
}
