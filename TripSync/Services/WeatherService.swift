//
//  WeatherService.swift
//  TripSync
//
//  Created by Tien Tran on 6/11/2025.
//

import Foundation
import CoreLocation

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    // OpenWeatherMap API Configuration
    private let baseURL = "https://api.openweathermap.org/data/2.5/forecast"
    private var apiKey: String {
        return Constants.Weather.apiKey
    }
    
    // Cache to avoid redundant API calls
    private var weatherCache: [String: (weather: DayWeather, fetchTime: Date)] = [:]
    private let cacheValidityHours: TimeInterval = Constants.Weather.cacheValiditySeconds
    
    // Maximum days in future for forecast (OpenWeatherMap free tier: 5 days)
    let maxForecastDays = Constants.Weather.maxForecastDays
    
    // MARK: - Public API
    
    /// Fetch weather forecast for a specific location and date
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - date: Target date for weather
    ///   - completion: Returns DayWeather or error
    func fetchWeather(latitude: Double, longitude: Double, for date: Date, completion: @escaping (Result<DayWeather, Error>) -> Void) {
        
        // Check if date is too far in future
        let daysUntilTrip = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysUntilTrip > maxForecastDays {
            print("⚠️ [WEATHER] Date is \(daysUntilTrip) days away (max forecast: \(maxForecastDays) days)")
            completion(.failure(WeatherError.dateOutOfRange(daysUntilTrip: daysUntilTrip)))
            return
        }
        
        if daysUntilTrip < 0 {
            print("⚠️ [WEATHER] Date is in the past")
            completion(.failure(WeatherError.dateInPast))
            return
        }
        
        // Check cache first
        let cacheKey = cacheKey(lat: latitude, lon: longitude, date: date)
        if let cached = weatherCache[cacheKey], isCacheValid(fetchTime: cached.fetchTime) {
            print("✅ [WEATHER] Using cached weather for \(date)")
            completion(.success(cached.weather))
            return
        }
        
        // Check if API key is set
        guard apiKey != "YOUR_API_KEY_HERE" && !apiKey.isEmpty else {
            print("⚠️ [WEATHER] API key not configured")
            completion(.failure(WeatherError.apiKeyNotConfigured))
            return
        }
        
        // Fetch from API
        fetchWeatherFromAPI(latitude: latitude, longitude: longitude, targetDate: date, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func fetchWeatherFromAPI(latitude: Double, longitude: Double, targetDate: Date, completion: @escaping (Result<DayWeather, Error>) -> Void) {
        
        // Build URL
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),  // Always fetch in Celsius, convert later
            URLQueryItem(name: "cnt", value: "40")  // 5 days × 8 intervals (3-hour)
        ]
        
        guard let url = components?.url else {
            completion(.failure(WeatherError.invalidURL))
            return
        }
        
        print("🌐 [WEATHER] Fetching weather from API...")
        print("   📍 Location: \(latitude), \(longitude)")
        print("   📅 Target Date: \(targetDate)")
        
        // Make API request
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [WEATHER] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(WeatherError.noData))
                return
            }
            
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [WEATHER] API Response: \(jsonString.prefix(200))...")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(OpenWeatherResponse.self, from: data)
                
                print("✅ [WEATHER] Parsed \(response.list.count) forecast items")
                
                // Convert to our model and filter for target date
                let dayWeather = self.convertToDayWeather(response: response, targetDate: targetDate)
                
                // Cache the result
                let cacheKey = self.cacheKey(lat: latitude, lon: longitude, date: targetDate)
                self.weatherCache[cacheKey] = (dayWeather, Date())
                
                print("✅ [WEATHER] Successfully fetched weather with \(dayWeather.hourlyForecasts.count) hourly forecasts")
                
                completion(.success(dayWeather))
                
            } catch {
                print("❌ [WEATHER] Parsing error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func convertToDayWeather(response: OpenWeatherResponse, targetDate: Date) -> DayWeather {
        let calendar = Calendar.current
        let targetDayComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        
        // Filter forecasts for the target date
        let forecasts = response.list.compactMap { item -> WeatherForecast? in
            let forecastDate = Date(timeIntervalSince1970: item.dt)
            let forecastDayComponents = calendar.dateComponents([.year, .month, .day], from: forecastDate)
            
            // Check if this forecast is for our target date
            guard targetDayComponents.year == forecastDayComponents.year,
                  targetDayComponents.month == forecastDayComponents.month,
                  targetDayComponents.day == forecastDayComponents.day else {
                return nil
            }
            
            guard let weatherCondition = item.weather.first else { return nil }
            
            return WeatherForecast(
                timestamp: forecastDate,
                temperature: item.main.temp,
                feelsLike: item.main.feelsLike,
                tempMin: item.main.tempMin,
                tempMax: item.main.tempMax,
                condition: weatherCondition.main,
                description: weatherCondition.description,
                icon: weatherCondition.icon,
                humidity: item.main.humidity,
                windSpeed: item.wind.speed,
                pressure: item.main.pressure,
                cloudiness: item.clouds.all
            )
        }
        
        return DayWeather(date: targetDate, hourlyForecasts: forecasts)
    }
    
    private func cacheKey(lat: Double, lon: Double, date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(lat),\(lon)_\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
    
    private func isCacheValid(fetchTime: Date) -> Bool {
        return Date().timeIntervalSince(fetchTime) < cacheValidityHours
    }
    
    /// Clear weather cache (useful for testing or forced refresh)
    func clearCache() {
        weatherCache.removeAll()
        print("🗑️ [WEATHER] Cache cleared")
    }
}

// MARK: - Weather Errors

enum WeatherError: Error, LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case noData
    case dateOutOfRange(daysUntilTrip: Int)
    case dateInPast
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Weather API key not configured. Please add your OpenWeatherMap API key."
        case .invalidURL:
            return "Invalid weather API URL"
        case .noData:
            return "No weather data received"
        case .dateOutOfRange(let days):
            return "Weather forecast only available \(WeatherService.shared.maxForecastDays) days ahead (trip is in \(days) days)"
        case .dateInPast:
            return "Cannot fetch weather for past dates"
        }
    }
}
