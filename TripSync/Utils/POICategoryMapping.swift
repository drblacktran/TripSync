//
//  POICategoryMapping.swift
//  TripSync
//
//  Maps POICategory to Google Places API types and vice versa
//

import Foundation

extension POICategory {
    
    /// Convert POICategory to Google Places type for API queries
    func toGoogleType() -> String {
        switch self {
        case .restaurant:
            return "restaurant"
        case .attraction:
            return "tourist_attraction"
        case .museum:
            return "museum"
        case .park:
            return "park"
        case .shopping:
            return "shopping_mall"
        case .nightlife:
            return "night_club"
        case .accommodation:
            return "lodging"
        case .transportation:
            return "transit_station"
        case .medical:
            return "hospital"
        case .entertainment:
            return "movie_theater"
        case .cultural:
            return "art_gallery"
        case .nature:
            return "natural_feature"
        case .religious:
            return "place_of_worship"
        case .market:
            return "store"
        case .cafe:
            return "cafe"
        case .viewpoint:
            return "point_of_interest"
        case .beach:
            return "natural_feature"
        case .other:
            return "point_of_interest"
        }
    }
    
    /// Create POICategory from Google Places types
    static func from(googleTypes: [String]) -> POICategory {
        // Priority order - most specific first
        if googleTypes.contains("restaurant") || googleTypes.contains("food") {
            return .restaurant
        }
        if googleTypes.contains("cafe") || googleTypes.contains("bakery") {
            return .cafe
        }
        if googleTypes.contains("museum") {
            return .museum
        }
        if googleTypes.contains("tourist_attraction") {
            return .attraction
        }
        if googleTypes.contains("park") {
            return .park
        }
        if googleTypes.contains("shopping_mall") || googleTypes.contains("store") {
            return .shopping
        }
        if googleTypes.contains("night_club") || googleTypes.contains("bar") {
            return .nightlife
        }
        if googleTypes.contains("lodging") || googleTypes.contains("hotel") {
            return .accommodation
        }
        if googleTypes.contains("transit_station") || googleTypes.contains("airport") {
            return .transportation
        }
        if googleTypes.contains("hospital") || googleTypes.contains("pharmacy") {
            return .medical
        }
        if googleTypes.contains("movie_theater") || googleTypes.contains("amusement_park") {
            return .entertainment
        }
        if googleTypes.contains("art_gallery") || googleTypes.contains("library") {
            return .cultural
        }
        if googleTypes.contains("natural_feature") {
            return .nature
        }
        if googleTypes.contains("place_of_worship") || googleTypes.contains("church") || googleTypes.contains("mosque") {
            return .religious
        }
        if googleTypes.contains("supermarket") || googleTypes.contains("convenience_store") {
            return .market
        }
        
        // Default
        return .other
    }
    
    /// Get all categories suitable for searching POIs
    static func searchableCategories() -> [POICategory] {
        return [
            .restaurant,
            .cafe,
            .museum,
            .attraction,
            .park,
            .shopping,
            .nightlife,
            .cultural,
            .market,
            .viewpoint,
            .beach,
            .entertainment
        ]
    }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .restaurant: return "Restaurants"
        case .cafe: return "Cafés"
        case .museum: return "Museums"
        case .attraction: return "Attractions"
        case .park: return "Parks"
        case .shopping: return "Shopping"
        case .nightlife: return "Nightlife"
        case .accommodation: return "Hotels"
        case .transportation: return "Transport"
        case .medical: return "Medical"
        case .entertainment: return "Entertainment"
        case .cultural: return "Culture"
        case .nature: return "Nature"
        case .religious: return "Religious Sites"
        case .market: return "Markets"
        case .viewpoint: return "Viewpoints"
        case .beach: return "Beaches"
        case .other: return "Other"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .museum: return "building.columns.fill"
        case .attraction: return "star.fill"
        case .park: return "tree.fill"
        case .shopping: return "bag.fill"
        case .nightlife: return "moon.stars.fill"
        case .accommodation: return "bed.double.fill"
        case .transportation: return "bus.fill"
        case .medical: return "cross.case.fill"
        case .entertainment: return "ticket.fill"
        case .cultural: return "paintpalette.fill"
        case .nature: return "leaf.fill"
        case .religious: return "building.fill"
        case .market: return "cart.fill"
        case .viewpoint: return "eye.fill"
        case .beach: return "water.waves"
        case .other: return "mappin.circle.fill"
        }
    }
}

/// Budget estimation based on Google price level (0-4)
struct BudgetEstimator {
    
    /// Estimate budget amount from Google price level
    /// - Parameters:
    ///   - priceLevel: Google's price level (0 = free, 1 = inexpensive, 2 = moderate, 3 = expensive, 4 = very expensive)
    ///   - category: POI category for context
    ///   - currency: Currency code (default VND)
    /// - Returns: Estimated Money amount or nil
    static func estimateFromPriceLevel(
        _ priceLevel: Int?,
        category: POICategory,
        currency: String = "VND"
    ) -> Money? {
        guard let level = priceLevel else { return nil }
        
        // VND price ranges by category and price level
        let vndAmounts: [POICategory: [Int: Double]] = [
            .restaurant: [
                0: 0,         // Free
                1: 150_000,   // Inexpensive (~$6 USD)
                2: 350_000,   // Moderate (~$14 USD)
                3: 700_000,   // Expensive (~$28 USD)
                4: 1_500_000  // Very expensive (~$60 USD)
            ],
            .cafe: [
                0: 0,
                1: 50_000,    // ~$2 USD
                2: 100_000,   // ~$4 USD
                3: 200_000,   // ~$8 USD
                4: 400_000    // ~$16 USD
            ],
            .museum: [
                0: 0,         // Free museums
                1: 50_000,    // ~$2 USD
                2: 150_000,   // ~$6 USD
                3: 300_000,   // ~$12 USD
                4: 500_000    // ~$20 USD
            ],
            .attraction: [
                0: 0,
                1: 100_000,   // ~$4 USD
                2: 250_000,   // ~$10 USD
                3: 500_000,   // ~$20 USD
                4: 1_000_000  // ~$40 USD
            ],
            .shopping: [
                0: 0,
                1: 200_000,   // ~$8 USD
                2: 500_000,   // ~$20 USD
                3: 1_000_000, // ~$40 USD
                4: 2_500_000  // ~$100 USD
            ],
            .nightlife: [
                0: 0,
                1: 150_000,   // ~$6 USD
                2: 400_000,   // ~$16 USD
                3: 800_000,   // ~$32 USD
                4: 1_500_000  // ~$60 USD
            ],
            .entertainment: [
                0: 0,
                1: 100_000,   // ~$4 USD
                2: 250_000,   // ~$10 USD
                3: 500_000,   // ~$20 USD
                4: 1_000_000  // ~$40 USD
            ]
        ]
        
        // Get amount for category, or use restaurant as default
        let amounts = vndAmounts[category] ?? vndAmounts[.restaurant]!
        guard let amount = amounts[level] else { return nil }
        
        return Money(
            amount: amount,
            currency: currency,
            exchangeRate: nil  // Will be filled later if needed
        )
    }
}
