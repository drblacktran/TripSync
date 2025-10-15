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
            createVietnamTrip()
        ]
    }

    // MARK: - Vietnam Cities Helper
    private static func createVietnamCities(startDate: Date) -> [TripRegion] {
        let cities = [
            ("Ho Chi Minh City", 10.8231, 106.6297),
            ("Hanoi", 21.0285, 105.8542),
            ("Da Nang", 16.0544, 108.2022),
            ("Hoi An", 15.8801, 108.3380),
            ("Hue", 16.4637, 107.5909),
            ("Can Tho", 10.0452, 105.7469),
            ("Nha Trang", 12.2388, 109.1967),
            ("Dalat", 11.9404, 108.4583),
            ("Vung Tau", 10.4113, 107.1362),
            ("Halong Bay", 20.9101, 107.1839),
            ("Sapa", 22.3380, 103.8442),
            ("Phan Thiet", 10.9280, 108.1028),
            ("My Tho", 10.3600, 106.3596),
            ("Vinh Long", 10.2535, 105.9571)
        ]

        return cities.enumerated().map { (index, cityData) in
            let (cityName, lat, lon) = cityData
            let dayDate = Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
            let nextDayDate = Calendar.current.date(byAdding: .day, value: index + 1, to: startDate) ?? startDate

            var cityRegion = TripRegion(
                id: "vietnam_city_\(index + 1)",
                name: cityName,
                country: "Vietnam",
                arrivalDate: dayDate,
                departureDate: nextDayDate
            )
            cityRegion.coordinates = Coordinate(latitude: lat, longitude: lon)
            cityRegion.localCurrency = "VND"
            cityRegion.budgetAllocation = 250.0

            // Add 3+ POIs for each city with authentic Vietnamese landmarks
            cityRegion.pointsOfInterest = createPOIsForCity(cityName: cityName, baseLat: lat, baseLon: lon, dayIndex: index)

            return cityRegion
        }
    }

    // MARK: - POI Creation Helper
    private static func createPOIsForCity(cityName: String, baseLat: Double, baseLon: Double, dayIndex: Int) -> [PointOfInterest] {
        let poiData: [String: [(String, POICategory, Double, Double)]] = [
            "Ho Chi Minh City": [
                ("Ben Thanh Market", .market, 10.7720, 106.6980),
                ("War Remnants Museum", .museum, 10.7797, 106.6914),
                ("Independence Palace", .attraction, 10.7769, 106.6955),
                ("Notre Dame Cathedral", .attraction, 10.7798, 106.6990)
            ],
            "Hanoi": [
                ("Hoan Kiem Lake", .attraction, 21.0285, 105.8542),
                ("Temple of Literature", .attraction, 21.0227, 105.8363),
                ("Old Quarter", .attraction, 21.0343, 105.8517),
                ("Vietnamese Museum", .museum, 21.0368, 105.8515)
            ],
            "Da Nang": [
                ("Dragon Bridge", .attraction, 16.0614, 108.2277),
                ("Marble Mountains", .attraction, 16.0062, 108.2651),
                ("Ba Na Hills", .attraction, 15.9969, 107.9917),
                ("My Khe Beach", .attraction, 16.0471, 108.2525)
            ],
            "Hoi An": [
                ("Ancient Town", .attraction, 15.8801, 108.3380),
                ("Japanese Covered Bridge", .attraction, 15.8796, 108.3279),
                ("Lantern Festival", .attraction, 15.8794, 108.3268),
                ("Night Market", .market, 15.8788, 108.3285)
            ],
            "Hue": [
                ("Imperial City", .attraction, 16.4674, 107.5905),
                ("Thien Mu Pagoda", .attraction, 16.4548, 107.5561),
                ("Royal Tombs", .attraction, 16.4637, 107.5909),
                ("Perfume River", .attraction, 16.4622, 107.5972)
            ]
        ]

        // Get POIs for this city or create generic ones
        if let cityPOIs = poiData[cityName] {
            return cityPOIs.map { (name, category, lat, lon) in
                PointOfInterest(
                    id: "poi_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_day\(dayIndex + 1)",
                    name: name,
                    category: category,
                    coordinates: Coordinate(latitude: lat, longitude: lon)
                )
            }
        } else {
            // Create generic POIs for other cities
            let categories: [POICategory] = [.attraction, .restaurant, .market, .museum]
            return (0..<3).map { poiIndex in
                let latOffset = Double.random(in: -0.02...0.02)
                let lonOffset = Double.random(in: -0.02...0.02)
                return PointOfInterest(
                    id: "poi_\(cityName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(poiIndex)_day\(dayIndex + 1)",
                    name: "\(cityName) \(categories[poiIndex % categories.count].rawValue.capitalized) \(poiIndex + 1)",
                    category: categories[poiIndex % categories.count],
                    coordinates: Coordinate(latitude: baseLat + latOffset, longitude: baseLon + lonOffset)
                )
            }
        }
    }

    // MARK: - Vietnam Adventure Trip
    static func createVietnamTrip() -> Trip {
        let startDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate) ?? Date() // 14 days total

        var trip = Trip(
            id: "vietnam_trip_\(UUID().uuidString.prefix(8))",
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
            id: UUID().uuidString,  // Generate unique ID
            name: "Vietnam",
            country: "Vietnam",
            arrivalDate: startDate,
            departureDate: endDate
        )
        vietnamRegion.coordinates = Coordinate(latitude: 14.0583, longitude: 108.2772)
        vietnamRegion.localCurrency = "VND"
        vietnamRegion.budgetAllocation = 3500.0

        // Create 14 different Vietnamese cities for each day
        let vietnamCities = createVietnamCities(startDate: startDate)
        vietnamRegion.subRegions = vietnamCities

        // Add Melbourne as departure point
        var melbourneRegion = TripRegion(
            id: UUID().uuidString,  // Generate unique ID
            name: "Melbourne",
            country: "Australia",
            arrivalDate: Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate,
            departureDate: startDate
        )
        melbourneRegion.coordinates = Coordinate(latitude: -37.8136, longitude: 144.9631)
        melbourneRegion.localCurrency = "AUD"
        melbourneRegion.budgetAllocation = 0.0

        // Update regions array to include Melbourne
        trip.regions = [melbourneRegion, vietnamRegion]

        // Note: Trip ID is set during initialization, cannot be modified after creation

        return trip
    }

    // MARK: - Helper Functions
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
        region.budgetAllocation = 500.0

        return region
    }

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
