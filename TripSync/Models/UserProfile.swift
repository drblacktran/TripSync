//
//  UserProfile.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import Foundation

struct UserProfile: Codable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var profileImageURL: String?
    var homeCountry: String
    var homeCurrency: String
    var preferredUnits: MeasurementUnit
    var languageCode: String
    var timeZone: String
    var dateJoined: Date
    var lastUpdated: Date
    
    // Travel Preferences
    var travelPreferences: TravelPreferences
    var notificationSettings: NotificationSettings
    var privacySettings: PrivacySettings
    
    init(id: String, firstName: String, lastName: String, email: String, homeCountry: String = "Australia") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImageURL = nil
        self.homeCountry = homeCountry
        self.homeCurrency = CurrencyHelper.getDefaultCurrency(for: homeCountry)
        self.preferredUnits = .metric
        self.languageCode = "en"
        self.timeZone = TimeZone.current.identifier
        self.dateJoined = Date()
        self.lastUpdated = Date()
        self.travelPreferences = TravelPreferences()
        self.notificationSettings = NotificationSettings()
        self.privacySettings = PrivacySettings()
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var countryFlag: String {
        return CountryHelper.getFlag(for: homeCountry)
    }
}

struct TravelPreferences: Codable {
    var defaultTripLength: Int // days
    var preferredTransportMode: TransportMode
    var budgetRange: BudgetRange
    var accommodationType: AccommodationType
    var activityPreferences: [ActivityType]
    var dietaryRestrictions: [String]
    var accessibilityNeeds: [String]
    
    init() {
        self.defaultTripLength = 7
        self.preferredTransportMode = .flight
        self.budgetRange = .moderate
        self.accommodationType = .hotel
        self.activityPreferences = [.cultural, .food, .sightseeing]
        self.dietaryRestrictions = []
        self.accessibilityNeeds = []
    }
}

struct NotificationSettings: Codable {
    var pushNotifications: Bool
    var emailNotifications: Bool
    var tripReminders: Bool
    var flightUpdates: Bool
    var documentReminders: Bool
    var budgetAlerts: Bool
    var reminderDaysBefore: Int
    
    init() {
        self.pushNotifications = true
        self.emailNotifications = true
        self.tripReminders = true
        self.flightUpdates = true
        self.documentReminders = true
        self.budgetAlerts = true
        self.reminderDaysBefore = 7
    }
}

struct PrivacySettings: Codable {
    var shareTripsWithContacts: Bool
    var allowTripDiscovery: Bool
    var shareLocationData: Bool
    var analyticsOptIn: Bool
    var marketingEmails: Bool
    
    init() {
        self.shareTripsWithContacts = false
        self.allowTripDiscovery = false
        self.shareLocationData = true
        self.analyticsOptIn = true
        self.marketingEmails = false
    }
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "Metric (km, °C)"
        case .imperial: return "Imperial (miles, °F)"
        }
    }

    var subtitleName: String {
        switch self {
        case .metric: return "Metric system"
        case .imperial: return "Imperial system"
        }
    }
}

enum BudgetRange: String, Codable, CaseIterable {
    case budget = "budget"
    case moderate = "moderate"
    case luxury = "luxury"
    case unlimited = "unlimited"
    
    var displayName: String {
        switch self {
        case .budget: return "Budget ($0-100/day)"
        case .moderate: return "Moderate ($100-300/day)"
        case .luxury: return "Luxury ($300-500/day)"
        case .unlimited: return "Unlimited ($500+/day)"
        }
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case adventure = "adventure"
    case cultural = "cultural"
    case food = "food"
    case nightlife = "nightlife"
    case nature = "nature"
    case shopping = "shopping"
    case sightseeing = "sightseeing"
    case sports = "sports"
    case relaxation = "relaxation"
    case photography = "photography"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .adventure: return "🏔️"
        case .cultural: return "🎭"
        case .food: return "🍽️"
        case .nightlife: return "🌃"
        case .nature: return "🌿"
        case .shopping: return "🛍️"
        case .sightseeing: return "🏛️"
        case .sports: return "⚽"
        case .relaxation: return "🧘"
        case .photography: return "📸"
        }
    }
}

// MARK: - Country Helper
struct CountryHelper {
    static func getFlag(for country: String) -> String {
        let flagMap: [String: String] = [
            "Australia": "🇦🇺",
            "United States": "🇺🇸",
            "Vietnam": "🇻🇳",
            "Japan": "🇯🇵",
            "France": "🇫🇷",
            "Germany": "🇩🇪",
            "United Kingdom": "🇬🇧",
            "Canada": "🇨🇦",
            "Singapore": "🇸🇬",
            "Thailand": "🇹🇭",
            "Indonesia": "🇮🇩",
            "Malaysia": "🇲🇾",
            "Philippines": "🇵🇭",
            "South Korea": "🇰🇷",
            "China": "🇨🇳",
            "India": "🇮🇳",
            "Italy": "🇮🇹",
            "Spain": "🇪🇸",
            "Netherlands": "🇳🇱",
            "Switzerland": "🇨🇭",
            "New Zealand": "🇳🇿"
        ]
        return flagMap[country] ?? "🌍"
    }
    
    static let popularCountries = [
        "Australia", "United States", "Vietnam", "Japan", "France",
        "Germany", "United Kingdom", "Canada", "Singapore", "Thailand",
        "Indonesia", "Malaysia", "Philippines", "South Korea", "China",
        "India", "Italy", "Spain", "Netherlands", "Switzerland", "New Zealand"
    ]
}