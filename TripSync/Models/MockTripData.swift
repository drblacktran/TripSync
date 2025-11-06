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
        // 5 days - 5 popular Vietnamese cities
        let cities = [
            ("Ho Chi Minh City", 10.8231, 106.6297, "VN-SG", "Ho Chi Minh"),
            ("Da Nang", 16.0544, 108.2022, "VN-DN", "Da Nang"),
            ("Hoi An", 15.8801, 108.3380, "VN-QN", "Quang Nam"),
            ("Hue", 16.4637, 107.5909, "VN-TTH", "Thua Thien Hue"),
            ("Hanoi", 21.0285, 105.8542, "VN-HN", "Hanoi")
        ]

        return cities.enumerated().map { (index, cityData) in
            let (cityName, lat, lon, areaCode, province) = cityData
            let dayDate = Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
            let nextDayDate = Calendar.current.date(byAdding: .day, value: 1, to: dayDate) ?? startDate

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
            cityRegion.cityName = cityName
            cityRegion.administrativeArea = province
            cityRegion.countryCode = "VN"
            cityRegion.formattedAddress = "\(cityName), Vietnam"
            cityRegion.regionType = .city

            // Add 4 POIs for each city with authentic Vietnamese landmarks
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
        // Trip starts in 3 days (Nov 9, 2025) - within 5-day forecast range!
        let startDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate) ?? Date()

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
        
        // Create Vietnam country region (parent)
        var vietnamRegion = TripRegion(
            id: UUID().uuidString,
            name: "Vietnam",
            country: "Vietnam",
            arrivalDate: startDate,
            departureDate: endDate
        )
        vietnamRegion.coordinates = Coordinate(latitude: 14.0583, longitude: 108.2772)
        vietnamRegion.localCurrency = "VND"
        vietnamRegion.budgetAllocation = 3500.0
        vietnamRegion.countryCode = "VN"
        vietnamRegion.regionType = .country

        // Create 5 city subregions with correct dates
        vietnamRegion.subRegions = createVietnamCities(startDate: startDate)

        // Add transportation between cities with mixed modes
        for i in 0..<vietnamRegion.subRegions.count - 1 {
            let from = vietnamRegion.subRegions[i]
            let to = vietnamRegion.subRegions[i + 1]

            let transportMode = determineTransportMode(from: from, to: to, legNumber: i)
            
            // Departure time is at the end of the current day (evening)
            let departureTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: from.departureDate) ?? from.departureDate
            
            // Arrival time depends on transport mode
            let travelHours: Int
            switch transportMode {
            case .flight:
                travelHours = 1  // 1 hour flight + 1 hour for check-in/boarding
            case .car:
                travelHours = 4  // 4-5 hours driving
            case .bus:
                travelHours = 6  // Slower than car
            default:
                travelHours = 3
            }
            
            let arrivalTime = Calendar.current.date(byAdding: .hour, value: travelHours, to: departureTime) ?? departureTime

            var transport = TransportationMethod(
                mode: transportMode,
                from: from.name,
                to: to.name,
                departureTime: departureTime,
                arrivalTime: arrivalTime
            )
            
            if let fromCoords = from.coordinates, let toCoords = to.coordinates {
                transport.coordinates = CoordinatePair(from: fromCoords, to: toCoords)
            }
            
            // Add flight details for flights
            if transportMode == .flight {
                transport.flightNumber = "VN\(100 + i)"
                transport.airline = "Vietnam Airlines"
                transport.bookingReference = "ABC\(String(format: "%03d", i + 1))"
            }
            
            // Add cost estimates
            switch transportMode {
            case .flight:
                transport.estimatedCost = Double.random(in: 80...150)
            case .car:
                transport.estimatedCost = Double.random(in: 30...60)
            case .bus:
                transport.estimatedCost = Double.random(in: 15...30)
            default:
                transport.estimatedCost = 50.0
            }

            vietnamRegion.subRegions[i].transportationMethods.append(transport)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            print("🚗 [MOCK] Added \(transportMode.rawValue) from \(from.name) to \(to.name)")
            print("   🕐 Departs: \(formatter.string(from: departureTime))")
            print("   🕐 Arrives: \(formatter.string(from: arrivalTime))")
            if let flightNum = transport.flightNumber {
                print("   ✈️ Flight: \(flightNum)")
            }
        }

        trip.regions = [vietnamRegion]

        print("✅ [MOCK] Created Vietnam trip with \(vietnamRegion.subRegions.count) cities")
        print("📍 [MOCK] Total POIs: \(vietnamRegion.subRegions.reduce(0) { $0 + $1.pointsOfInterest.count })")

        return trip
    }

    // MARK: - Transport Mode Helper
    private static func determineTransportMode(from: TripRegion, to: TripRegion, legNumber: Int) -> TransportMode {
        guard let fromCoords = from.coordinates, let toCoords = to.coordinates else {
            return .car  // Default fallback
        }

        // Calculate approximate distance in kilometers
        let distance = calculateDistance(
            lat1: fromCoords.latitude, lon1: fromCoords.longitude,
            lat2: toCoords.latitude, lon2: toCoords.longitude
        )

        // Mix of transport modes based on distance and leg number for variety:
        // Leg 0 (HCM → Da Nang): ~600km - Flight
        // Leg 1 (Da Nang → Hoi An): ~30km - Car
        // Leg 2 (Hoi An → Hue): ~120km - Bus
        // Leg 3 (Hue → Hanoi): ~660km - Flight
        
        if legNumber == 0 || legNumber == 3 {
            // Long distance - use flight
            return .flight
        } else if legNumber == 1 {
            // Short distance - use car/taxi
            return .car
        } else {
            // Medium distance - use bus
            return .bus
        }
    }

    private static func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        // Haversine formula for distance between two coordinates
        let earthRadius = 6371.0 // km

        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)

        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        return earthRadius * c
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
