//
//  GooglePlacesService.swift
//  TripSync
//
//  Google Places API wrapper with free tier optimization and local caching
//

import Foundation
import CoreLocation

/// Google Places API Service
/// Free tier: $200/month credit = ~11,700 Autocomplete requests or 40,000 Place Details requests
/// Strategy: Cache aggressively, minimize API calls, store results locally
class GooglePlacesService {
    
    static let shared = GooglePlacesService()
    
    // MARK: - Configuration
    
    private let apiKey: String
    private let baseURL = "https://places.googleapis.com/v1"
    private let session = URLSession.shared
    
    // Free tier quotas (conservative estimates)
    private let maxAutocompletePerDay = 300      // ~9000/month = well under free tier
    private let maxPlaceDetailsPerDay = 1000     // ~30000/month = under free tier
    
    // MARK: - Local Cache
    
    private let cacheManager = PlaceCacheManager.shared
    private var requestCount: [String: Int] = [:]  // Track daily usage
    
    init() {
        // Load API key from Constants or Info.plist
        if let key = Constants.googlePlacesAPIKey {
            self.apiKey = key
        } else if let key = Bundle.main.infoDictionary?["GOOGLE_PLACES_API_KEY"] as? String {
            self.apiKey = key
        } else {
            self.apiKey = ""
            print("⚠️ [GOOGLE PLACES] API Key not found!")
        }
    }
    
    // MARK: - Autocomplete Search
    
    /// Search for places with autocomplete (NEW API v1)
    /// - Parameters:
    ///   - query: Search query
    ///   - types: Place types filter (e.g., ["(cities)", "(regions)"])
    ///   - country: Country code to restrict results (e.g., "vn")
    ///   - completion: Results callback
    func autocomplete(
        query: String,
        types: [String] = [],
        country: String? = "vn",
        completion: @escaping (Result<[GooglePlaceResult], Error>) -> Void
    ) {
        // Check cache first
        if let cached = cacheManager.getCachedAutocomplete(query: query) {
            print("✅ [GOOGLE PLACES] Cache hit for: \(query)")
            completion(.success(cached))
            return
        }
        
        // Check rate limit
        guard checkRateLimit(endpoint: "autocomplete") else {
            print("⚠️ [GOOGLE PLACES] Rate limit exceeded for autocomplete")
            completion(.failure(PlacesError.rateLimitExceeded))
            return
        }
        
        // NEW API: POST to /places:autocomplete
        guard let url = URL(string: "\(baseURL)/places:autocomplete") else {
            completion(.failure(PlacesError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        // Build JSON body
        var body: [String: Any] = ["input": query]
        
        // Add location restriction for Vietnam
        if let country = country, country.lowercased() == "vn" {
            body["locationRestriction"] = [
                "rectangle": [
                    "low": ["latitude": 8.0, "longitude": 102.0],
                    "high": ["latitude": 24.0, "longitude": 110.0]
                ]
            ]
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        print("🌐 [GOOGLE PLACES] Autocomplete (v1): \(query)")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(PlacesError.noData))
                return
            }
            
            // Debug: print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [DEBUG] Response: \(jsonString.prefix(500))")
            }
            
            do {
                let response = try JSONDecoder().decode(NewAutocompleteResponse.self, from: data)
                
                // NEW API: Check for suggestions array instead of status
                guard !response.suggestions.isEmpty else {
                    print("⚠️ [GOOGLE PLACES] No suggestions found")
                    completion(.success([]))
                    return
                }
                
                // Convert to GooglePlaceResult
                let results = response.suggestions.compactMap { suggestion -> GooglePlaceResult? in
                    guard let prediction = suggestion.placePrediction else { return nil }
                    
                    return GooglePlaceResult(
                        placeId: prediction.placeId ?? "",
                        name: prediction.text.text,
                        formattedAddress: prediction.structuredFormat?.mainText.text ?? prediction.text.text,
                        coordinates: Coordinate(latitude: 0, longitude: 0),
                        types: prediction.types ?? [],
                        vicinity: prediction.structuredFormat?.secondaryText?.text,
                        administrativeArea: nil,
                        locality: nil,
                        country: nil,
                        countryCode: nil,
                        priceLevel: nil,
                        rating: nil,
                        userRatingsTotal: nil,
                        openingHours: nil,
                        website: nil,
                        phoneNumber: nil,
                        photos: nil
                    )
                }
                
                // Cache results
                self.cacheManager.cacheAutocomplete(query: query, results: results)
                
                print("✅ [GOOGLE PLACES] Found \(results.count) results for: \(query)")
                completion(.success(results))
                
            } catch {
                print("❌ [GOOGLE PLACES] Decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
        
        incrementRequestCount(endpoint: "autocomplete")
    }
    
    // MARK: - Place Details
    
    /// Get detailed information about a place using Places API (New) v1
    /// - Parameters:
    ///   - placeId: Google Place ID
    ///   - completion: Place details callback
    func placeDetails(
        placeId: String,
        completion: @escaping (Result<GooglePlaceResult, Error>) -> Void
    ) {
        // Check cache first
        if let cachedPlace = cacheManager.getCachedPlaceDetails(placeId: placeId) {
            print("✅ [GOOGLE PLACES] Cache hit for place: \(placeId)")
            completion(.success(cachedPlace))
            return
        }
        
        // Check rate limit
        guard checkRateLimit(endpoint: "details") else {
            print("⚠️ [GOOGLE PLACES] Rate limit exceeded for place details")
            completion(.failure(PlacesError.rateLimitExceeded))
            return
        }
        
        // NEW API: GET to /places/{placeId}
        guard let url = URL(string: "\(baseURL)/places/\(placeId)") else {
            completion(.failure(PlacesError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        // Add field mask header for the fields we want
        let fieldMask = "id,displayName,formattedAddress,location,types,addressComponents,rating,userRatingCount,priceLevel,websiteUri,nationalPhoneNumber,regularOpeningHours,photos"
        request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        
        print("🌐 [GOOGLE PLACES] Fetching details (v1) for: \(placeId)")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [GOOGLE PLACES] Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ [GOOGLE PLACES] No data received")
                completion(.failure(PlacesError.noData))
                return
            }
            
            // Debug: print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [DEBUG] Details Response: \(jsonString.prefix(300))")
            }
            
            do {
                let response = try JSONDecoder().decode(NewPlaceDetailsResponse.self, from: data)
                
                // Extract address components
                let addressComponents = response.addressComponents ?? []
                let adminArea = addressComponents.first { $0.types.contains("administrative_area_level_1") }?.longName
                let locality = addressComponents.first { $0.types.contains("locality") }?.longName
                let country = addressComponents.first { $0.types.contains("country") }?.longName
                let countryCode = addressComponents.first { $0.types.contains("country") }?.shortName
                
                // Convert price level from String to Int
                // NEW API uses: PRICE_LEVEL_FREE (0), PRICE_LEVEL_INEXPENSIVE (1), PRICE_LEVEL_MODERATE (2),
                //                PRICE_LEVEL_EXPENSIVE (3), PRICE_LEVEL_VERY_EXPENSIVE (4)
                let priceLevelInt: Int?
                if let priceLevelString = response.priceLevel {
                    switch priceLevelString {
                    case "PRICE_LEVEL_FREE":
                        priceLevelInt = 0
                    case "PRICE_LEVEL_INEXPENSIVE":
                        priceLevelInt = 1
                    case "PRICE_LEVEL_MODERATE":
                        priceLevelInt = 2
                    case "PRICE_LEVEL_EXPENSIVE":
                        priceLevelInt = 3
                    case "PRICE_LEVEL_VERY_EXPENSIVE":
                        priceLevelInt = 4
                    default:
                        priceLevelInt = nil
                    }
                } else {
                    priceLevelInt = nil
                }
                
                let placeResult = GooglePlaceResult(
                    placeId: placeId,
                    name: response.displayName?.text ?? "Unknown",
                    formattedAddress: response.formattedAddress ?? "",
                    coordinates: Coordinate(
                        latitude: response.location?.latitude ?? 0,
                        longitude: response.location?.longitude ?? 0
                    ),
                    types: response.types ?? [],
                    vicinity: nil,
                    administrativeArea: adminArea,
                    locality: locality,
                    country: country,
                    countryCode: countryCode,
                    priceLevel: priceLevelInt,
                    rating: response.rating,
                    userRatingsTotal: response.userRatingCount,
                    openingHours: response.regularOpeningHours?.weekdayDescriptions,
                    website: response.websiteUri,
                    phoneNumber: response.nationalPhoneNumber,
                    photos: response.photos?.map { $0.name }
                )
                
                // Cache result
                self.cacheManager.cachePlaceDetails(placeId: placeId, place: placeResult)
                
                print("✅ [GOOGLE PLACES] Got details for: \(response.displayName?.text ?? placeId)")
                completion(.success(placeResult))
                
            } catch {
                print("❌ [GOOGLE PLACES] Decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 [DEBUG] Failed JSON: \(jsonString)")
                }
                completion(.failure(error))
            }
        }.resume()
        
        incrementRequestCount(endpoint: "details")
    }
    
    // MARK: - Nearby Search
    
    /// Search for places near a location
    /// - Parameters:
    ///   - location: Center coordinate
    ///   - radius: Search radius in meters (max 50000)
    ///   - type: Place type (e.g., "restaurant", "museum")
    ///   - keyword: Additional search keyword
    ///   - completion: Results callback
    func nearbySearch(
        location: Coordinate,
        radius: Int = 5000,
        type: String? = nil,
        keyword: String? = nil,
        completion: @escaping (Result<[GooglePlaceResult], Error>) -> Void
    ) {
        // Check cache first
        let cacheKey = "\(location.latitude),\(location.longitude)_\(radius)_\(type ?? "")_\(keyword ?? "")"
        if let cachedResults = cacheManager.getCachedNearbySearch(key: cacheKey) {
            print("✅ [GOOGLE PLACES] Cache hit for nearby search")
            completion(.success(cachedResults))
            return
        }
        
        // Check rate limit
        guard checkRateLimit(endpoint: "nearby") else {
            print("⚠️ [GOOGLE PLACES] Rate limit exceeded for nearby search")
            completion(.failure(PlacesError.rateLimitExceeded))
            return
        }
        
        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")
        var queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            completion(.failure(PlacesError.invalidURL))
            return
        }
        
        print("🌐 [GOOGLE PLACES] Nearby search: \(type ?? "all") within \(radius)m")
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(PlacesError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(NearbySearchResponse.self, from: data)
                
                guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                    completion(.failure(PlacesError.apiError(response.status)))
                    return
                }
                
                let results = response.results.map { place in
                    GooglePlaceResult(
                        placeId: place.placeId,
                        name: place.name,
                        formattedAddress: place.vicinity ?? "",
                        coordinates: Coordinate(
                            latitude: place.geometry.location.lat,
                            longitude: place.geometry.location.lng
                        ),
                        types: place.types,
                        vicinity: place.vicinity,
                        administrativeArea: nil,
                        locality: nil,
                        country: nil,
                        countryCode: nil,
                        priceLevel: place.priceLevel,
                        rating: place.rating,
                        userRatingsTotal: place.userRatingsTotal,
                        openingHours: nil,
                        website: nil,
                        phoneNumber: nil,
                        photos: place.photos?.map { $0.photoReference }
                    )
                }
                
                // Cache results
                self.cacheManager.cacheNearbySearch(key: cacheKey, results: results)
                
                print("✅ [GOOGLE PLACES] Found \(results.count) nearby places")
                completion(.success(results))
                
            } catch {
                print("❌ [GOOGLE PLACES] Decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
        
        incrementRequestCount(endpoint: "nearby")
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit(endpoint: String) -> Bool {
        let today = dateString()
        let key = "\(endpoint)_\(today)"
        let count = requestCount[key] ?? 0
        
        let limit: Int
        switch endpoint {
        case "autocomplete":
            limit = maxAutocompletePerDay
        case "details", "nearby":
            limit = maxPlaceDetailsPerDay
        default:
            limit = 100
        }
        
        return count < limit
    }
    
    private func incrementRequestCount(endpoint: String) {
        let today = dateString()
        let key = "\(endpoint)_\(today)"
        requestCount[key, default: 0] += 1
        
        print("📊 [GOOGLE PLACES] \(endpoint) requests today: \(requestCount[key] ?? 0)")
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Error Types

enum PlacesError: Error, LocalizedError {
    case invalidURL
    case noData
    case apiError(String)
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .apiError(let status):
            return "API Error: \(status)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Try again later."
        }
    }
}

// MARK: - API Response Models

struct AutocompleteResponse: Codable {
    let predictions: [Prediction]
    let status: String
    
    struct Prediction: Codable {
        let description: String
        let placeId: String
        let types: [String]
        let structuredFormatting: StructuredFormatting
        
        enum CodingKeys: String, CodingKey {
            case description
            case placeId = "place_id"
            case types
            case structuredFormatting = "structured_formatting"
        }
    }
    
    struct StructuredFormatting: Codable {
        let mainText: String
        let secondaryText: String?
        
        enum CodingKeys: String, CodingKey {
            case mainText = "main_text"
            case secondaryText = "secondary_text"
        }
    }
}

struct PlaceDetailsResponse: Codable {
    let result: PlaceDetails?
    let status: String
}

struct PlaceDetails: Codable {
    let name: String
    let formattedAddress: String
    let geometry: Geometry
    let types: [String]
    let vicinity: String?
    let addressComponents: [AddressComponent]?
    let priceLevel: Int?
    let rating: Double?
    let userRatingsTotal: Int?
    let openingHours: GoogleOpeningHours?
    let website: String?
    let formattedPhoneNumber: String?
    let photos: [Photo]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case types
        case vicinity
        case addressComponents = "address_components"
        case priceLevel = "price_level"
        case rating
        case userRatingsTotal = "user_ratings_total"
        case openingHours = "opening_hours"
        case website
        case formattedPhoneNumber = "formatted_phone_number"
        case photos
    }
}

struct NearbySearchResponse: Codable {
    let results: [NearbyPlace]
    let status: String
}

struct NearbyPlace: Codable {
    let placeId: String
    let name: String
    let vicinity: String?
    let geometry: Geometry
    let types: [String]
    let priceLevel: Int?
    let rating: Double?
    let userRatingsTotal: Int?
    let photos: [Photo]?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case geometry
        case types
        case priceLevel = "price_level"
        case rating
        case userRatingsTotal = "user_ratings_total"
        case photos
    }
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct AddressComponent: Codable {
    let longName: String
    let shortName: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case types
    }
}

struct GoogleOpeningHours: Codable {
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case weekdayText = "weekday_text"
    }
}

struct Photo: Codable {
    let photoReference: String
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
    }
}

// MARK: - NEW API (v1) Response Models

struct NewAutocompleteResponse: Codable {
    let suggestions: [AutocompleteSuggestion]
}

struct AutocompleteSuggestion: Codable {
    let placePrediction: PlacePrediction?
}

struct PlacePrediction: Codable {
    let placeId: String?
    let text: PlaceText
    let structuredFormat: StructuredFormat?
    let types: [String]?
    
    enum CodingKeys: String, CodingKey {
        case placeId
        case text
        case structuredFormat
        case types
    }
}

struct PlaceText: Codable {
    let text: String
}

struct StructuredFormat: Codable {
    let mainText: PlaceText
    let secondaryText: PlaceText?
}

// NEW API v1: Place Details Response
struct NewPlaceDetailsResponse: Codable {
    let id: String?
    let displayName: PlaceText?
    let formattedAddress: String?
    let location: LatLng?
    let types: [String]?
    let addressComponents: [NewAddressComponent]?
    let rating: Double?
    let userRatingCount: Int?
    let priceLevel: String?
    let websiteUri: String?
    let nationalPhoneNumber: String?
    let regularOpeningHours: RegularOpeningHours?
    let photos: [PlacePhoto]?
}

struct LatLng: Codable {
    let latitude: Double
    let longitude: Double
}

struct NewAddressComponent: Codable {
    let longText: String?
    let shortText: String?
    let types: [String]
    let languageCode: String?
    
    var longName: String { longText ?? "" }
    var shortName: String { shortText ?? "" }
}

struct RegularOpeningHours: Codable {
    let openNow: Bool?
    let periods: [OpeningPeriod]?
    let weekdayDescriptions: [String]?
}

struct OpeningPeriod: Codable {
    let open: DayTime?
    let close: DayTime?
}

struct DayTime: Codable {
    let day: Int?
    let hour: Int?
    let minute: Int?
}

struct PlacePhoto: Codable {
    let name: String
    let widthPx: Int?
    let heightPx: Int?
}
