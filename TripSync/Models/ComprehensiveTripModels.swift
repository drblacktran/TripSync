//
//  ComprehensiveTripModels.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import Foundation

// MARK: - Core Trip Model
struct Trip: Codable, Identifiable {
    let id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var createdDate: Date
    var lastModified: Date

    // Geographical Info
    var homeCountry: String
    var targetCountries: [String]
    var isInternational: Bool

    // Financial Overview
    var baseCurrency: String
    var totalBudget: Double?
    var actualSpent: Double
    var forexRate: ForexSnapshot

    // Transportation
    var primaryTransportMode: TransportMode
    var hasFlightDetails: Bool
    var flightPromptDismissed: Bool

    // Structure
    var regions: [TripRegion]
    var documents: [TripDocument]
    var dailySchedules: [DailySchedule]
    var flights: [Flight] // Flight routes for visualization

    // Metadata
    var isShared: Bool
    var collaborators: [String] // User IDs
    var tags: [String]

    // Backwards-compatible CodingKeys and custom decoder
    enum CodingKeys: String, CodingKey {
        case id, title, startDate, endDate, createdDate, lastModified
        case homeCountry, targetCountries, isInternational
        case baseCurrency, totalBudget, actualSpent, forexRate
        case primaryTransportMode, hasFlightDetails, flightPromptDismissed
        case regions, documents, dailySchedules, flights
        case isShared, collaborators, tags
    }

    init(id: String = UUID().uuidString, title: String, startDate: Date, endDate: Date, homeCountry: String = "Australia") {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.createdDate = Date()
        self.lastModified = Date()
        self.homeCountry = homeCountry
        self.targetCountries = []
        self.isInternational = false
        self.baseCurrency = CurrencyHelper.getDefaultCurrency(for: homeCountry)
        self.totalBudget = nil
        self.actualSpent = 0.0
        self.forexRate = ForexSnapshot(baseCurrency: self.baseCurrency)
        self.primaryTransportMode = .car
        self.hasFlightDetails = false
        self.flightPromptDismissed = false
        self.regions = []
        self.documents = []
        self.dailySchedules = []
        self.flights = []
        self.isShared = false
        self.collaborators = []
        self.tags = []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()

        homeCountry = try container.decodeIfPresent(String.self, forKey: .homeCountry) ?? "Australia"
        targetCountries = try container.decodeIfPresent([String].self, forKey: .targetCountries) ?? []
        isInternational = try container.decodeIfPresent(Bool.self, forKey: .isInternational) ?? false

        baseCurrency = try container.decodeIfPresent(String.self, forKey: .baseCurrency) ?? CurrencyHelper.getDefaultCurrency(for: homeCountry)
        totalBudget = try container.decodeIfPresent(Double.self, forKey: .totalBudget)
        actualSpent = try container.decodeIfPresent(Double.self, forKey: .actualSpent) ?? 0.0
        forexRate = try container.decodeIfPresent(ForexSnapshot.self, forKey: .forexRate) ?? ForexSnapshot(baseCurrency: baseCurrency)

        primaryTransportMode = try container.decodeIfPresent(TransportMode.self, forKey: .primaryTransportMode) ?? .car
        hasFlightDetails = try container.decodeIfPresent(Bool.self, forKey: .hasFlightDetails) ?? false
        flightPromptDismissed = try container.decodeIfPresent(Bool.self, forKey: .flightPromptDismissed) ?? false

        regions = try container.decodeIfPresent([TripRegion].self, forKey: .regions) ?? []
        documents = try container.decodeIfPresent([TripDocument].self, forKey: .documents) ?? []
        dailySchedules = try container.decodeIfPresent([DailySchedule].self, forKey: .dailySchedules) ?? []
        flights = try container.decodeIfPresent([Flight].self, forKey: .flights) ?? []

        isShared = try container.decodeIfPresent(Bool.self, forKey: .isShared) ?? false
        collaborators = try container.decodeIfPresent([String].self, forKey: .collaborators) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

// MARK: - Hierarchical Structure Models
struct TripRegion: Codable, Identifiable {
    let id: String
    var name: String
    var country: String
    var arrivalDate: Date
    var departureDate: Date
    
    // Geographical
    var coordinates: Coordinate?
    var timezone: String
    var localCurrency: String
    
    // Geocoding Support
    var cityName: String?
    var administrativeArea: String?
    var countryCode: String?
    var formattedAddress: String?
    var placeID: String?
    var regionType: RegionType
    
    // Financial
    var budgetAllocation: Double?
    var actualSpent: Double
    var dailyBudgetSuggestion: Double?
    
    // Structure - Nested regions (cities within countries, districts within cities)
    var subRegions: [TripRegion]
    var pointsOfInterest: [PointOfInterest]
    var accommodations: [Accommodation]
    var transportationMethods: [TransportationMethod]
    
    // Planning
    var notes: String
    var priority: RegionPriority
    var weatherInfo: WeatherInfo?
    
    // Custom coding keys for backward compatibility
    enum CodingKeys: String, CodingKey {
        case id, name, country, arrivalDate, departureDate
        case coordinates, timezone, localCurrency
        case cityName, administrativeArea, countryCode, formattedAddress, placeID, regionType
        case budgetAllocation, actualSpent, dailyBudgetSuggestion
        case subRegions, pointsOfInterest, accommodations, transportationMethods
        case notes, priority, weatherInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        country = try container.decode(String.self, forKey: .country)
        arrivalDate = try container.decode(Date.self, forKey: .arrivalDate)
        departureDate = try container.decode(Date.self, forKey: .departureDate)
        coordinates = try container.decodeIfPresent(Coordinate.self, forKey: .coordinates)
        timezone = try container.decode(String.self, forKey: .timezone)
        localCurrency = try container.decode(String.self, forKey: .localCurrency)
        
        // New fields with defaults for backward compatibility
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        administrativeArea = try container.decodeIfPresent(String.self, forKey: .administrativeArea)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        placeID = try container.decodeIfPresent(String.self, forKey: .placeID)
        regionType = try container.decodeIfPresent(RegionType.self, forKey: .regionType) ?? .city
        
        budgetAllocation = try container.decodeIfPresent(Double.self, forKey: .budgetAllocation)
        actualSpent = try container.decode(Double.self, forKey: .actualSpent)
        dailyBudgetSuggestion = try container.decodeIfPresent(Double.self, forKey: .dailyBudgetSuggestion)
        subRegions = try container.decode([TripRegion].self, forKey: .subRegions)
        pointsOfInterest = try container.decode([PointOfInterest].self, forKey: .pointsOfInterest)
        accommodations = try container.decode([Accommodation].self, forKey: .accommodations)
        transportationMethods = try container.decode([TransportationMethod].self, forKey: .transportationMethods)
        notes = try container.decode(String.self, forKey: .notes)
        priority = try container.decode(RegionPriority.self, forKey: .priority)
        weatherInfo = try container.decodeIfPresent(WeatherInfo.self, forKey: .weatherInfo)
    }
    
    init(id: String = UUID().uuidString, name: String, country: String, arrivalDate: Date, departureDate: Date) {
        self.id = id
        self.name = name
        self.country = country
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.coordinates = nil
        self.timezone = TimeZone.current.identifier
        self.localCurrency = CurrencyHelper.getDefaultCurrency(for: country)
        self.cityName = nil
        self.administrativeArea = nil
        self.countryCode = nil
        self.formattedAddress = nil
        self.placeID = nil
        self.regionType = .city
        self.budgetAllocation = nil
        self.actualSpent = 0.0
        self.dailyBudgetSuggestion = nil
        self.subRegions = []
        self.pointsOfInterest = []
        self.accommodations = []
        self.transportationMethods = []
        self.notes = ""
        self.priority = .medium
        self.weatherInfo = nil
    }
}

// MARK: - Points of Interest
struct PointOfInterest: Codable, Identifiable {
    let id: String
    var name: String
    var category: POICategory
    var coordinates: Coordinate
    var address: String
    
    // Visit Details
    var plannedVisitDate: Date?
    var estimatedDuration: TimeInterval // in seconds
    var visitedDate: Date?
    var actualDuration: TimeInterval?
    
    // Financial
    var entryCost: Money?
    var estimatedSpending: Money?
    var actualSpending: Money?
    
    // Content
    var description: String
    var rating: Double? // 1-5 stars (Google rating)
    var userRating: Double? // User's personal rating
    var photos: [String] // URLs or local paths
    var documents: [String] // Document IDs
    var notes: String // User notes
    var tags: [String] // Custom tags
    
    // Preferences
    var isFavorite: Bool
    
    // Weather
    var weatherAtVisit: WeatherForecast?
    
    // Logistics
    var openingHours: [OpeningHours]?
    var bookingRequired: Bool
    var bookingInfo: BookingInfo?
    var accessibilityInfo: String?
    var contactInfo: String?
    
    // Transportation to this POI
    var transportFromPrevious: TransportationMethod?
    var walkingTimeFromAccommodation: TimeInterval?
    
    // Custom decoding for backward compatibility
    enum CodingKeys: String, CodingKey {
        case id, name, category, coordinates, address
        case plannedVisitDate, estimatedDuration, visitedDate, actualDuration
        case entryCost, estimatedSpending, actualSpending
        case description, rating, userRating, photos, documents, notes, tags
        case isFavorite, weatherAtVisit
        case openingHours, bookingRequired, bookingInfo, accessibilityInfo, contactInfo
        case transportFromPrevious, walkingTimeFromAccommodation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(POICategory.self, forKey: .category)
        coordinates = try container.decode(Coordinate.self, forKey: .coordinates)
        
        // Fields with defaults for backward compatibility
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        plannedVisitDate = try container.decodeIfPresent(Date.self, forKey: .plannedVisitDate)
        estimatedDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .estimatedDuration) ?? 3600
        visitedDate = try container.decodeIfPresent(Date.self, forKey: .visitedDate)
        actualDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .actualDuration)
        entryCost = try container.decodeIfPresent(Money.self, forKey: .entryCost)
        estimatedSpending = try container.decodeIfPresent(Money.self, forKey: .estimatedSpending)
        actualSpending = try container.decodeIfPresent(Money.self, forKey: .actualSpending)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        userRating = try container.decodeIfPresent(Double.self, forKey: .userRating)
        photos = try container.decodeIfPresent([String].self, forKey: .photos) ?? []
        documents = try container.decodeIfPresent([String].self, forKey: .documents) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        weatherAtVisit = try container.decodeIfPresent(WeatherForecast.self, forKey: .weatherAtVisit)
        openingHours = try container.decodeIfPresent([OpeningHours].self, forKey: .openingHours)
        bookingRequired = try container.decodeIfPresent(Bool.self, forKey: .bookingRequired) ?? false
        bookingInfo = try container.decodeIfPresent(BookingInfo.self, forKey: .bookingInfo)
        accessibilityInfo = try container.decodeIfPresent(String.self, forKey: .accessibilityInfo)
        contactInfo = try container.decodeIfPresent(String.self, forKey: .contactInfo)
        transportFromPrevious = try container.decodeIfPresent(TransportationMethod.self, forKey: .transportFromPrevious)
        walkingTimeFromAccommodation = try container.decodeIfPresent(TimeInterval.self, forKey: .walkingTimeFromAccommodation)
    }
    
    init(id: String = UUID().uuidString, name: String, category: POICategory, coordinates: Coordinate) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinates = coordinates
        self.address = ""
        self.plannedVisitDate = nil
        self.estimatedDuration = 3600 // 1 hour default
        self.visitedDate = nil
        self.actualDuration = nil
        self.entryCost = nil
        self.estimatedSpending = nil
        self.actualSpending = nil
        self.description = ""
        self.rating = nil
        self.userRating = nil
        self.photos = []
        self.documents = []
        self.notes = ""
        self.tags = []
        self.isFavorite = false
        self.weatherAtVisit = nil
        self.openingHours = nil
        self.bookingRequired = false
        self.bookingInfo = nil
        self.accessibilityInfo = nil
        self.contactInfo = nil
        self.transportFromPrevious = nil
        self.walkingTimeFromAccommodation = nil
    }
}

// MARK: - Supporting Models
enum TransportMode: String, Codable, CaseIterable {
    case flight = "flight"
    case car = "car"
    case train = "train"
    case bus = "bus"
    case ferry = "ferry"
    case walking = "walking"
    case bicycle = "bicycle"
    case taxi = "taxi"
    case rideshare = "rideshare"
    case publicTransport = "public_transport"
    case mixed = "mixed"
}

// MARK: - Flight Route Model
struct Flight: Codable, Identifiable {
    let id: String
    var day: Int // Which day of the trip (1-based)
    var departureLocation: String // Location name (e.g., "Melbourne", "Ho Chi Minh City")
    var arrivalLocation: String // Location name
    var departureCoordinate: Coordinate
    var arrivalCoordinate: Coordinate
    var flightType: FlightType // International or Domestic
    var airline: String?
    var flightNumber: String?
    var departureTime: Date?
    var arrivalTime: Date?
    var bookingReference: String?
    var cost: Money?
    
    init(id: String = UUID().uuidString, day: Int, from: String, to: String, fromCoord: Coordinate, toCoord: Coordinate, type: FlightType) {
        self.id = id
        self.day = day
        self.departureLocation = from
        self.arrivalLocation = to
        self.departureCoordinate = fromCoord
        self.arrivalCoordinate = toCoord
        self.flightType = type
        self.airline = nil
        self.flightNumber = nil
        self.departureTime = nil
        self.arrivalTime = nil
        self.bookingReference = nil
        self.cost = nil
    }
}

enum FlightType: String, Codable {
    case international = "international"
    case domestic = "domestic"
}

enum POICategory: String, Codable, CaseIterable {
    case restaurant = "restaurant"
    case attraction = "attraction"
    case museum = "museum"
    case park = "park"
    case shopping = "shopping"
    case nightlife = "nightlife"
    case accommodation = "accommodation"
    case transportation = "transportation"
    case medical = "medical"
    case entertainment = "entertainment"
    case cultural = "cultural"
    case nature = "nature"
    case religious = "religious"
    case market = "market"
    case cafe = "cafe"
    case viewpoint = "viewpoint"
    case beach = "beach"
    case other = "other"
}

enum RegionPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case mustSee = "must_see"
}

enum RegionType: String, Codable {
    case country = "country"
    case province = "province"
    case city = "city"
    case district = "district"
    case neighborhood = "neighborhood"
}

// MARK: - Money & Currency
/// Represents a monetary amount with currency and optional exchange rate
/// 
/// Currency Hierarchy (fallback chain):
/// 1. POI's estimatedSpending.currency (most specific)
/// 2. TripRegion's localCurrency (region-level)
/// 3. Trip's baseCurrency (trip-level, usually home currency)
///
/// Exchange rates can be fetched from APIs like:
/// - exchangerate-api.com (free tier available)
/// - fixer.io
/// - currencyapi.com
struct Money: Codable {
    let amount: Double
    let currency: String // Currency code (e.g., "VND", "USD", "AUD")
    let exchangeRate: Double? // Rate to convert to trip's base currency (for future API integration)
    let convertedAmount: Double? // Amount in trip's base currency (auto-calculated)
    
    init(amount: Double, currency: String, exchangeRate: Double? = nil) {
        self.amount = amount
        self.currency = currency
        self.exchangeRate = exchangeRate
        self.convertedAmount = exchangeRate != nil ? amount * exchangeRate! : nil
    }
}

struct ForexSnapshot: Codable {
    let baseCurrency: String
    let rates: [String: Double] // Currency code to rate
    let lastUpdated: Date
    
    init(baseCurrency: String) {
        self.baseCurrency = baseCurrency
        self.rates = [:]
        self.lastUpdated = Date()
    }
}

struct TransportationMethod: Codable, Identifiable {
    let id: String
    var mode: TransportMode
    var fromLocation: String
    var toLocation: String
    var departureTime: Date?
    var arrivalTime: Date?
    var cost: Money?
    var bookingReference: String?
    var flightNumber: String?  // For flights (e.g., "VN123")
    var airline: String?  // For flights (e.g., "Vietnam Airlines")
    var estimatedCost: Double?  // Estimated cost in local currency
    var notes: String
    var coordinates: CoordinatePair
    
    init(id: String = UUID().uuidString, mode: TransportMode, from: String, to: String, departureTime: Date? = nil, arrivalTime: Date? = nil) {
        self.id = id
        self.mode = mode
        self.fromLocation = from
        self.toLocation = to
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.cost = nil
        self.bookingReference = nil
        self.flightNumber = nil
        self.airline = nil
        self.estimatedCost = nil
        self.notes = ""
        self.coordinates = CoordinatePair()
    }
}

struct Accommodation: Codable, Identifiable {
    let id: String
    var name: String
    var type: AccommodationType
    var address: String
    var coordinates: Coordinate?
    var checkInDate: Date
    var checkOutDate: Date
    var totalCost: Money?
    var bookingReference: String?
    var rating: Double?
    var amenities: [String]
    var notes: String
    var photos: [String]
    
    init(id: String = UUID().uuidString, name: String, checkIn: Date, checkOut: Date) {
        self.id = id
        self.name = name
        self.type = .hotel
        self.address = ""
        self.coordinates = nil
        self.checkInDate = checkIn
        self.checkOutDate = checkOut
        self.totalCost = nil
        self.bookingReference = nil
        self.rating = nil
        self.amenities = []
        self.notes = ""
        self.photos = []
    }
}

enum AccommodationType: String, Codable {
    case hotel = "hotel"
    case hostel = "hostel"
    case airbnb = "airbnb"
    case guesthouse = "guesthouse"
    case resort = "resort"
    case camping = "camping"
    case apartment = "apartment"
    case other = "other"
}

struct OpeningHours: Codable {
    let dayOfWeek: Int // 1-7, Sunday = 1
    let openTime: String // "09:00"
    let closeTime: String // "17:00"
    let isClosed: Bool
}

struct BookingInfo: Codable {
    var isBooked: Bool
    var bookingReference: String?
    var bookingDate: Date?
    var bookingPlatform: String?
    var contactInfo: String?
    var cancellationPolicy: String?
}

struct WeatherInfo: Codable {
    let averageHigh: Double
    let averageLow: Double
    let precipitation: Double
    let humidity: Double
    let season: String
    let recommendations: String
}

struct TripDocument: Codable, Identifiable {
    let id: String
    var title: String
    var type: DocumentType
    var filePath: String? // Local path
    var cloudURL: String? // Firebase Storage URL
    var thumbnailPath: String?
    var uploadDate: Date
    var associatedPOI: String? // POI ID
    var associatedRegion: String? // Region ID
    var tags: [String]
    var notes: String
    
    init(id: String = UUID().uuidString, title: String, type: DocumentType) {
        self.id = id
        self.title = title
        self.type = type
        self.filePath = nil
        self.cloudURL = nil
        self.thumbnailPath = nil
        self.uploadDate = Date()
        self.associatedPOI = nil
        self.associatedRegion = nil
        self.tags = []
        self.notes = ""
    }
}

enum DocumentType: String, Codable {
    case flight = "flight"
    case accommodation = "accommodation"
    case ticket = "ticket"
    case receipt = "receipt"
    case map = "map"
    case photo = "photo"
    case itinerary = "itinerary"
    case passport = "passport"
    case visa = "visa"
    case insurance = "insurance"
    case other = "other"
}

struct DailySchedule: Codable, Identifiable {
    let id: String
    var date: Date
    var regionId: String
    var plannedActivities: [ScheduledActivity]
    var actualActivities: [ScheduledActivity]
    var dailyBudget: Money?
    var actualSpent: Money?
    var notes: String
    var weatherForecast: WeatherInfo?
    
    init(id: String = UUID().uuidString, date: Date, regionId: String) {
        self.id = id
        self.date = date
        self.regionId = regionId
        self.plannedActivities = []
        self.actualActivities = []
        self.dailyBudget = nil
        self.actualSpent = nil
        self.notes = ""
        self.weatherForecast = nil
    }
}

struct ScheduledActivity: Codable, Identifiable {
    let id: String
    var poiId: String?
    var title: String
    var startTime: Date
    var endTime: Date
    var transportationToActivity: TransportationMethod?
    var estimatedCost: Money?
    var actualCost: Money?
    var completed: Bool
    var rating: Double?
    var notes: String
    
    init(id: String = UUID().uuidString, title: String, start: Date, end: Date) {
        self.id = id
        self.poiId = nil
        self.title = title
        self.startTime = start
        self.endTime = end
        self.transportationToActivity = nil
        self.estimatedCost = nil
        self.actualCost = nil
        self.completed = false
        self.rating = nil
        self.notes = ""
    }
}

// MARK: - Utility Helpers
struct CurrencyHelper {
    static func getDefaultCurrency(for country: String) -> String {
        let currencyMap: [String: String] = [
            "Australia": "AUD",
            "United States": "USD",
            "Vietnam": "VND",
            "Japan": "JPY",
            "France": "EUR",
            "Indonesia": "IDR",
            // Add more mappings as needed
        ]
        return currencyMap[country] ?? "USD"
    }
}

// MARK: - Custom Coordinate Struct (Safe for Codable)
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coreLocation: Any) {
        // Safe conversion from CLLocationCoordinate2D when needed
        if let coord = coreLocation as? NSObject,
           coord.responds(to: NSSelectorFromString("latitude")),
           coord.responds(to: NSSelectorFromString("longitude")) {
            self.latitude = coord.value(forKey: "latitude") as? Double ?? 0.0
            self.longitude = coord.value(forKey: "longitude") as? Double ?? 0.0
        } else {
            self.latitude = 0.0
            self.longitude = 0.0
        }
    }
    
    // Convert to CLLocationCoordinate2D when needed for MapKit
    var coreLocationCoordinate: Any {
        // Simple approach: return a dictionary that can be easily converted
        // In real usage, this would be converted to CLLocationCoordinate2D by the calling code
        return [
            "latitude": latitude,
            "longitude": longitude
        ]
    }
    
    // Helper method to create CLLocationCoordinate2D when CoreLocation is imported
    func toCLLocationCoordinate2D() -> Any {
        // This method would be called from code that imports CoreLocation
        // For now, return the coordinate data as a simple structure
        return (latitude: latitude, longitude: longitude)
    }
}

// MARK: - Coordinate Pairs for Transportation
struct CoordinatePair: Codable {
    let from: Coordinate?
    let to: Coordinate?
    
    init(from: Coordinate? = nil, to: Coordinate? = nil) {
        self.from = from
        self.to = to
    }
}