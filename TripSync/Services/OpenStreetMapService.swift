//
//  OpenStreetMapService.swift
//  TripSync
//
//  Created on 7/11/2025.
//  OpenStreetMap Nominatim API service for reverse geocoding and search
//

import Foundation
import CoreLocation

/// OpenStreetMap Nominatim API service
/// Free tier: 1 request/second, no API key required
/// Attribution required: "© OpenStreetMap contributors"
class OpenStreetMapService {
    static let shared = OpenStreetMapService()
    
    private let baseURL = "https://nominatim.openstreetmap.org"
    private let session: URLSession
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0 // Nominatim requires 1 req/sec max
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        // Required: Include User-Agent for Nominatim
        config.httpAdditionalHeaders = [
            "User-Agent": "TripSync/1.0 (iOS Trip Planning App)"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Models
    
    struct SearchResult: Codable {
        let placeId: Int
        let licence: String
        let osmType: String
        let osmId: Int
        let lat: String
        let lon: String
        let displayName: String
        let address: Address?
        let importance: Double
        
        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case licence
            case osmType = "osm_type"
            case osmId = "osm_id"
            case lat, lon
            case displayName = "display_name"
            case address
            case importance
        }
        
        struct Address: Codable {
            let road: String?
            let suburb: String?
            let city: String?
            let state: String?
            let country: String?
            let countryCode: String?
            
            enum CodingKeys: String, CodingKey {
                case road, suburb, city, state, country
                case countryCode = "country_code"
            }
        }
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: Double(lat) ?? 0,
                longitude: Double(lon) ?? 0
            )
        }
    }
    
    enum OSMError: LocalizedError {
        case rateLimitExceeded
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .rateLimitExceeded:
                return "Please wait a moment before searching again"
            case .invalidURL:
                return "Invalid search request"
            case .noData:
                return "No results found"
            case .decodingError(let error):
                return "Failed to parse results: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Rate Limiting
    
    private func enforceRateLimit() async throws {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRequestInterval {
                let waitTime = minimumRequestInterval - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    // MARK: - Reverse Geocoding
    
    /// Reverse geocode coordinates to get place name and address
    /// - Parameters:
    ///   - coordinate: Location to reverse geocode
    ///   - zoom: Detail level (3=country, 10=city, 18=building)
    /// - Returns: Search result with place information
    func reverseGeocode(
        coordinate: CLLocationCoordinate2D,
        zoom: Int = 18
    ) async throws -> SearchResult {
        try await enforceRateLimit()
        
        var components = URLComponents(string: "\(baseURL)/reverse")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            URLQueryItem(name: "zoom", value: String(zoom)),
            URLQueryItem(name: "addressdetails", value: "1")
        ]
        
        guard let url = components?.url else {
            throw OSMError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            return result
        } catch let error as DecodingError {
            throw OSMError.decodingError(error)
        } catch {
            throw OSMError.networkError(error)
        }
    }
    
    // MARK: - Search / Autocomplete
    
    /// Search for places by query (autocomplete)
    /// - Parameters:
    ///   - query: Search text
    ///   - countryCode: Optional country filter (e.g., "vn", "au")
    ///   - viewBox: Optional bounding box to prioritize results (minLon, minLat, maxLon, maxLat)
    ///   - limit: Maximum results (default 10)
    /// - Returns: Array of search results
    func search(
        query: String,
        countryCode: String? = nil,
        viewBox: (minLon: Double, minLat: Double, maxLon: Double, maxLat: Double)? = nil,
        limit: Int = 10
    ) async throws -> [SearchResult] {
        guard !query.isEmpty else {
            return []
        }
        
        try await enforceRateLimit()
        
        var components = URLComponents(string: "\(baseURL)/search")
        var queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let countryCode = countryCode {
            queryItems.append(URLQueryItem(name: "countrycodes", value: countryCode))
        }
        
        if let viewBox = viewBox {
            let viewBoxString = "\(viewBox.minLon),\(viewBox.minLat),\(viewBox.maxLon),\(viewBox.maxLat)"
            queryItems.append(URLQueryItem(name: "viewbox", value: viewBoxString))
            queryItems.append(URLQueryItem(name: "bounded", value: "1"))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw OSMError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let results = try JSONDecoder().decode([SearchResult].self, from: data)
            return results
        } catch let error as DecodingError {
            throw OSMError.decodingError(error)
        } catch {
            throw OSMError.networkError(error)
        }
    }
    
    // MARK: - Nearby Search
    
    /// Search for places near a coordinate
    /// - Parameters:
    ///   - coordinate: Center point
    ///   - radius: Search radius in meters (converted to bounding box)
    ///   - query: Optional search term (e.g., "restaurant", "hotel")
    ///   - limit: Maximum results
    /// - Returns: Array of search results
    func searchNearby(
        coordinate: CLLocationCoordinate2D,
        radius: Double = 1000,
        query: String? = nil,
        limit: Int = 20
    ) async throws -> [SearchResult] {
        // Convert radius to bounding box (approximate)
        let latDelta = radius / 111320.0 // 1 degree latitude ≈ 111.32 km
        let lonDelta = radius / (111320.0 * cos(coordinate.latitude * .pi / 180.0))
        
        let viewBox = (
            minLon: coordinate.longitude - lonDelta,
            minLat: coordinate.latitude - latDelta,
            maxLon: coordinate.longitude + lonDelta,
            maxLat: coordinate.latitude + latDelta
        )
        
        let searchQuery = query ?? "point of interest"
        
        return try await search(
            query: searchQuery,
            viewBox: viewBox,
            limit: limit
        )
    }
    
    // MARK: - Helper Methods
    
    /// Format address from search result
    func formatAddress(_ result: SearchResult) -> String {
        guard let address = result.address else {
            return result.displayName
        }
        
        var components: [String] = []
        
        if let road = address.road {
            components.append(road)
        }
        if let suburb = address.suburb {
            components.append(suburb)
        }
        if let city = address.city {
            components.append(city)
        }
        if let state = address.state {
            components.append(state)
        }
        if let country = address.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Get short name from search result (e.g., city or suburb)
    func getShortName(_ result: SearchResult) -> String {
        if let address = result.address {
            return address.suburb ?? address.city ?? address.state ?? result.displayName
        }
        return result.displayName.components(separatedBy: ",").first ?? result.displayName
    }
}
