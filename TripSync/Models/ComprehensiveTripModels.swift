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
    
    // Metadata
    var isShared: Bool
    var collaborators: [String] // User IDs
    var tags: [String]
    
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
        self.isShared = false
        self.collaborators = []
        self.tags = []
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
    
    init(id: String = UUID().uuidString, name: String, country: String, arrivalDate: Date, departureDate: Date) {
        self.id = id
        self.name = name
        self.country = country
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.coordinates = nil
        self.timezone = TimeZone.current.identifier
        self.localCurrency = CurrencyHelper.getDefaultCurrency(for: country)
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
    var rating: Double? // 1-5 stars
    var photos: [String] // URLs or local paths
    var documents: [String] // Document IDs
    
    // Logistics
    var openingHours: [OpeningHours]
    var bookingRequired: Bool
    var bookingInfo: BookingInfo?
    var accessibilityInfo: String?
    
    // Transportation to this POI
    var transportFromPrevious: TransportationMethod?
    var walkingTimeFromAccommodation: TimeInterval?
    
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
        self.photos = []
        self.documents = []
        self.openingHours = []
        self.bookingRequired = false
        self.bookingInfo = nil
        self.accessibilityInfo = nil
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

struct Money: Codable {
    let amount: Double
    let currency: String
    let exchangeRate: Double? // Rate when expense was recorded
    let convertedAmount: Double? // Amount in trip's base currency
    
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
    var notes: String
    var coordinates: CoordinatePair
    
    init(id: String = UUID().uuidString, mode: TransportMode, from: String, to: String) {
        self.id = id
        self.mode = mode
        self.fromLocation = from
        self.toLocation = to
        self.departureTime = nil
        self.arrivalTime = nil
        self.cost = nil
        self.bookingReference = nil
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