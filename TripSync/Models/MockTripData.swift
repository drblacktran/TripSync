//
//  MockTripData.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import Foundation

extension Trip {
    static func createMockTrips() -> [Trip] {
        return [
            createVietnamTrip(),
            createJapanTrip(),
            createEuropeTrip(),
            createDomesticTrip(),
            createBusinessTrip()
        ]
    }
    
    // MARK: - Vietnam Adventure Trip
    static func createVietnamTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 44, to: startDate) ?? Date()
        
        var trip = Trip(
            id: "vietnam_trip_001",
            title: "Vietnam Adventure",
            startDate: startDate,
            endDate: endDate,
            homeCountry: "Australia"
        )
        
        trip.targetCountries = ["Vietnam"]
        trip.isInternational = true
        trip.primaryTransportMode = .flight
        trip.hasFlightDetails = true
        trip.totalBudget = 3500.0
        trip.baseCurrency = "AUD"
        trip.tags = ["adventure", "culture", "food", "backpacking"]
        
        // Create Vietnam country region
        var vietnamRegion = TripRegion(
            id: "vietnam_country",
            name: "Vietnam",
            country: "Vietnam",
            arrivalDate: startDate,
            departureDate: endDate
        )
        vietnamRegion.coordinates = Coordinate(latitude: 14.0583, longitude: 108.2772)
        vietnamRegion.localCurrency = "VND"
        vietnamRegion.budgetAllocation = 3500.0
        
        // Ho Chi Minh City region
        var hcmcRegion = TripRegion(
            id: "hcmc_region",
            name: "Ho Chi Minh City",
            country: "Vietnam",
            arrivalDate: startDate,
            departureDate: Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        )
        hcmcRegion.coordinates = Coordinate(latitude: 10.8231, longitude: 106.6297)
        hcmcRegion.budgetAllocation = 1500.0
        hcmcRegion.dailyBudgetSuggestion = 200.0
        
        // HCMC POIs
        var benThanhMarket = PointOfInterest(
            id: "ben_thanh_market",
            name: "Ben Thanh Market",
            category: .market,
            coordinates: Coordinate(latitude: 10.7720, longitude: 106.6980)
        )
        benThanhMarket.address = "Lê Lợi, Phường Phạm Ngũ Lão, Quận 1, TP.HCM"
        benThanhMarket.estimatedDuration = 7200 // 2 hours
        benThanhMarket.entryCost = Money(amount: 0, currency: "VND")
        benThanhMarket.estimatedSpending = Money(amount: 500000, currency: "VND", exchangeRate: 0.000041) // ~$20 AUD
        benThanhMarket.description = "Famous traditional market with local food, souvenirs, and handicrafts"
        benThanhMarket.rating = 4.2
        benThanhMarket.openingHours = [
            OpeningHours(dayOfWeek: 1, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 2, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 3, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 4, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 5, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 6, openTime: "06:00", closeTime: "18:00", isClosed: false),
            OpeningHours(dayOfWeek: 7, openTime: "06:00", closeTime: "18:00", isClosed: false)
        ]
        
        var warMuseum = PointOfInterest(
            id: "war_remnants_museum",
            name: "War Remnants Museum",
            category: .museum,
            coordinates: Coordinate(latitude: 10.7797, longitude: 106.6914)
        )
        warMuseum.address = "28 Võ Văn Tần, Phường 6, Quận 3, TP.HCM"
        warMuseum.estimatedDuration = 5400 // 1.5 hours
        warMuseum.entryCost = Money(amount: 40000, currency: "VND", exchangeRate: 0.000041)
        warMuseum.description = "Comprehensive museum documenting the Vietnam War"
        warMuseum.rating = 4.5
        warMuseum.bookingRequired = false
        
        hcmcRegion.pointsOfInterest = [benThanhMarket, warMuseum]
        
        // HCMC Accommodation
        var hcmcHotel = Accommodation(
            id: "hcmc_hotel",
            name: "Hotel Continental Saigon",
            checkIn: startDate,
            checkOut: Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        )
        hcmcHotel.type = .hotel
        hcmcHotel.address = "132-134 Đồng Khởi, Bến Nghé, Quận 1, TP.HCM"
        hcmcHotel.coordinates = Coordinate(latitude: 10.7770, longitude: 106.7026)
        hcmcHotel.totalCost = Money(amount: 1400000, currency: "VND", exchangeRate: 0.000041) // ~$57 AUD per night
        hcmcHotel.rating = 4.3
        hcmcHotel.amenities = ["WiFi", "Air Conditioning", "Restaurant", "Pool", "Gym"]
        
        hcmcRegion.accommodations = [hcmcHotel]
        
        // Hanoi region
        var hanoiRegion = TripRegion(
            id: "hanoi_region",
            name: "Hanoi",
            country: "Vietnam",
            arrivalDate: Calendar.current.date(byAdding: .day, value: 8, to: startDate) ?? startDate,
            departureDate: Calendar.current.date(byAdding: .day, value: 14, to: startDate) ?? startDate
        )
        hanoiRegion.coordinates = Coordinate(latitude: 21.0285, longitude: 105.8542)
        hanoiRegion.budgetAllocation = 2000.0
        
        // Hanoi POIs
        var oldQuarter = PointOfInterest(
            id: "hanoi_old_quarter",
            name: "Hanoi Old Quarter",
            category: .cultural,
            coordinates: Coordinate(latitude: 21.0333, longitude: 105.8500)
        )
        oldQuarter.estimatedDuration = 14400 // 4 hours
        oldQuarter.description = "Historic neighborhood with narrow streets, traditional shops, and street food"
        oldQuarter.rating = 4.6
        
        hanoiRegion.pointsOfInterest = [oldQuarter]
        
        // Add transportation between cities
        var hcmcToHanoi = TransportationMethod(
            id: "hcmc_hanoi_flight",
            mode: .flight,
            from: "Ho Chi Minh City",
            to: "Hanoi"
        )
        hcmcToHanoi.departureTime = Calendar.current.date(byAdding: .day, value: 8, to: startDate)
        hcmcToHanoi.arrivalTime = Calendar.current.date(byAdding: .hour, value: 2, to: hcmcToHanoi.departureTime!)
        hcmcToHanoi.cost = Money(amount: 2500000, currency: "VND", exchangeRate: 0.000041) // ~$100 AUD
        hcmcToHanoi.bookingReference = "VN1234"
        hcmcToHanoi.coordinates = CoordinatePair(
            from: Coordinate(latitude: 10.8184, longitude: 106.6521), // SGN Airport
            to: Coordinate(latitude: 21.2187, longitude: 105.8068)    // HAN Airport
        )
        
        vietnamRegion.transportationMethods = [hcmcToHanoi]
        vietnamRegion.subRegions = [hcmcRegion, hanoiRegion]
        
        trip.regions = [vietnamRegion]
        
        // Add some documents
        var flightTicket = TripDocument(id: "vietnam_flight", title: "Sydney to HCMC Flight", type: .flight)
        flightTicket.associatedRegion = "vietnam_country"
        flightTicket.notes = "Jetstar flight JQ124, Gate 23"
        
        var passport = TripDocument(id: "passport_copy", title: "Passport Copy", type: .passport)
        
        trip.documents = [flightTicket, passport]
        
        return trip
    }
    
    // MARK: - Japan Cultural Trip
    static func createJapanTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 70, to: startDate) ?? Date()
        
        var trip = Trip(
            id: "japan_trip_001",
            title: "Japan Cultural Experience",
            startDate: startDate,
            endDate: endDate,
            homeCountry: "Australia"
        )
        
        trip.targetCountries = ["Japan"]
        trip.isInternational = true
        trip.primaryTransportMode = .flight
        trip.totalBudget = 5000.0
        trip.baseCurrency = "AUD"
        trip.tags = ["culture", "temples", "food", "technology"]
        
        var japanRegion = TripRegion(
            id: "japan_country",
            name: "Japan",
            country: "Japan",
            arrivalDate: startDate,
            departureDate: endDate
        )
        japanRegion.coordinates = Coordinate(latitude: 36.2048, longitude: 138.2529)
        japanRegion.localCurrency = "JPY"
        japanRegion.budgetAllocation = 5000.0
        
        // Tokyo region
        var tokyoRegion = TripRegion(
            id: "tokyo_region",
            name: "Tokyo",
            country: "Japan",
            arrivalDate: startDate,
            departureDate: Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        )
        tokyoRegion.coordinates = Coordinate(latitude: 35.6762, longitude: 139.6503)
        tokyoRegion.budgetAllocation = 3000.0
        
        var sensojiTemple = PointOfInterest(
            id: "sensoji_temple",
            name: "Sensoji Temple",
            category: .religious,
            coordinates: Coordinate(latitude: 35.7148, longitude: 139.7967)
        )
        sensojiTemple.description = "Ancient Buddhist temple in Asakusa district"
        sensojiTemple.rating = 4.7
        sensojiTemple.estimatedDuration = 5400 // 1.5 hours
        sensojiTemple.entryCost = Money(amount: 0, currency: "JPY")
        
        tokyoRegion.pointsOfInterest = [sensojiTemple]
        japanRegion.subRegions = [tokyoRegion]
        trip.regions = [japanRegion]
        
        return trip
    }
    
    // MARK: - Europe Backpacking Trip  
    static func createEuropeTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 118, to: startDate) ?? Date()
        
        var trip = Trip(
            id: "europe_trip_001", 
            title: "European Backpacking Adventure",
            startDate: startDate,
            endDate: endDate,
            homeCountry: "Australia"
        )
        
        trip.targetCountries = ["France", "Italy", "Germany", "Netherlands"]
        trip.isInternational = true
        trip.primaryTransportMode = .mixed
        trip.totalBudget = 8000.0
        trip.tags = ["backpacking", "culture", "art", "history"]
        
        // Multiple country regions would be added here...
        
        return trip
    }
    
    // MARK: - Domestic Australia Trip
    static func createDomesticTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 21, to: startDate) ?? Date()
        
        var trip = Trip(
            id: "melbourne_trip_001",
            title: "Melbourne Weekend Getaway", 
            startDate: startDate,
            endDate: endDate,
            homeCountry: "Australia"
        )
        
        trip.targetCountries = ["Australia"]
        trip.isInternational = false
        trip.primaryTransportMode = .car
        trip.hasFlightDetails = false
        trip.totalBudget = 1200.0
        trip.tags = ["domestic", "city", "food", "coffee"]
        
        return trip
    }
    
    // MARK: - Business Trip
    static func createBusinessTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 10, to: startDate) ?? Date()
        
        var trip = Trip(
            id: "business_trip_001",
            title: "Singapore Business Conference",
            startDate: startDate,
            endDate: endDate,
            homeCountry: "Australia"
        )
        
        trip.targetCountries = ["Singapore"]
        trip.isInternational = true
        trip.primaryTransportMode = .flight
        trip.hasFlightDetails = true
        trip.totalBudget = 2500.0
        trip.tags = ["business", "conference", "networking"]
        
        return trip
    }
}

// MARK: - Mock Data Extensions
extension TripRegion {
    static func createMockRegion(name: String, country: String, coordinates: Coordinate) -> TripRegion {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate) ?? startDate
        
        var region = TripRegion(
            id: UUID().uuidString,
            name: name,
            country: country,
            arrivalDate: startDate,
            departureDate: endDate
        )
        
        region.coordinates = coordinates
        region.localCurrency = CurrencyHelper.getDefaultCurrency(for: country)
        region.budgetAllocation = 500.0
        region.priority = .medium
        
        return region
    }
}

extension PointOfInterest {
    static func createMockPOI(name: String, category: POICategory, coordinates: Coordinate) -> PointOfInterest {
        var poi = PointOfInterest(
            id: UUID().uuidString,
            name: name,
            category: category,
            coordinates: coordinates
        )
        
        poi.estimatedDuration = 3600 // 1 hour
        poi.rating = Double.random(in: 3.5...5.0)
        poi.description = "A wonderful place to visit with great \(category.rawValue) experience"
        
        return poi
    }
}