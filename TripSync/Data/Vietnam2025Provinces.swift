//
//  Vietnam2025Provinces.swift
//  TripSync
//
//  Vietnam's 34 provinces/cities after 2025 administrative reform
//

import Foundation

struct ProvinceInfo: Codable {
    let name: String
    let code: String
    let coordinates: Coordinate
    let regionType: RegionType
    let merged: [String]?      // Previous provinces that merged (if applicable)
    let capital: String?        // Provincial capital city
    let population: Int?
    let area: Double?           // km²
    let localCurrency: String
    let timezone: String
}

/// Vietnam 2025 Administrative Division Data
/// Based on government restructuring: 63 provinces → 34 merged provinces/cities
struct Vietnam2025 {
    
    static let countryCode = "VN"
    static let currencyCode = "VND"
    static let defaultTimezone = "Asia/Ho_Chi_Minh"
    
    // MARK: - 34 Provinces/Cities (2025 Merged Structure)
    
    static let provinces: [ProvinceInfo] = [
        
        // MARK: Metropolitan Regions (5 major merged metros)
        
        ProvinceInfo(
            name: "Ho Chi Minh Metropolis",
            code: "VN-HCMC-METRO",
            coordinates: Coordinate(latitude: 10.8231, longitude: 106.6297),
            regionType: .province,
            merged: ["Ho Chi Minh City", "Binh Duong", "Dong Nai", "Ba Ria-Vung Tau"],
            capital: "Ho Chi Minh City",
            population: 15_000_000,
            area: 8_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Hanoi Capital Region",
            code: "VN-HN-CAPITAL",
            coordinates: Coordinate(latitude: 21.0285, longitude: 105.8542),
            regionType: .province,
            merged: ["Hanoi", "Ha Nam", "Hung Yen", "Vinh Phuc"],
            capital: "Hanoi",
            population: 12_000_000,
            area: 7_200,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Da Nang-Quang Nam Metropolitan Area",
            code: "VN-DN-QN",
            coordinates: Coordinate(latitude: 15.9500, longitude: 108.2000),
            regionType: .province,
            merged: ["Da Nang", "Quang Nam"],
            capital: "Da Nang",
            population: 2_800_000,
            area: 11_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Can Tho-Mekong Delta Hub",
            code: "VN-CT-DELTA",
            coordinates: Coordinate(latitude: 10.0340, longitude: 105.7220),
            regionType: .province,
            merged: ["Can Tho", "Hau Giang", "Soc Trang"],
            capital: "Can Tho",
            population: 3_500_000,
            area: 7_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Hai Phong-Quang Ninh Economic Zone",
            code: "VN-HP-QN",
            coordinates: Coordinate(latitude: 20.8449, longitude: 106.6881),
            regionType: .province,
            merged: ["Hai Phong", "Quang Ninh"],
            capital: "Hai Phong",
            population: 4_200_000,
            area: 7_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: Northern Region (10 provinces)
        
        ProvinceInfo(
            name: "Northwest Mountain Region",
            code: "VN-NW-MOUNTAIN",
            coordinates: Coordinate(latitude: 21.3380, longitude: 103.9140),
            regionType: .province,
            merged: ["Dien Bien", "Lai Chau", "Son La", "Hoa Binh"],
            capital: "Dien Bien Phu",
            population: 2_100_000,
            area: 37_000,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Northeast Highland Region",
            code: "VN-NE-HIGHLAND",
            coordinates: Coordinate(latitude: 22.3380, longitude: 104.8000),
            regionType: .province,
            merged: ["Ha Giang", "Cao Bang", "Bac Kan", "Tuyen Quang"],
            capital: "Ha Giang",
            population: 1_800_000,
            area: 25_000,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Lao Cai-Yen Bai Mountain Province",
            code: "VN-LC-YB",
            coordinates: Coordinate(latitude: 22.4809, longitude: 103.9755),
            regionType: .province,
            merged: ["Lao Cai", "Yen Bai"],
            capital: "Lao Cai",
            population: 1_200_000,
            area: 15_000,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Thai Nguyen-Bac Giang Industrial Zone",
            code: "VN-TN-BG",
            coordinates: Coordinate(latitude: 21.5670, longitude: 105.8252),
            regionType: .province,
            merged: ["Thai Nguyen", "Bac Giang"],
            capital: "Thai Nguyen",
            population: 2_400_000,
            area: 6_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Lang Son-Bac Ninh Border Province",
            code: "VN-LS-BN",
            coordinates: Coordinate(latitude: 21.8467, longitude: 106.7617),
            regionType: .province,
            merged: ["Lang Son", "Bac Ninh"],
            capital: "Lang Son",
            population: 1_600_000,
            area: 4_200,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Phu Tho",
            code: "VN-PT",
            coordinates: Coordinate(latitude: 21.2680, longitude: 105.2045),
            regionType: .province,
            merged: nil,
            capital: "Viet Tri",
            population: 1_400_000,
            area: 3_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: North Central Region (6 provinces)
        
        ProvinceInfo(
            name: "Thanh Hoa",
            code: "VN-TH",
            coordinates: Coordinate(latitude: 19.8067, longitude: 105.7851),
            regionType: .province,
            merged: nil,
            capital: "Thanh Hoa",
            population: 3_500_000,
            area: 11_100,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Nghe An-Ha Tinh Coastal Province",
            code: "VN-NA-HT",
            coordinates: Coordinate(latitude: 19.2342, longitude: 104.9200),
            regionType: .province,
            merged: ["Nghe An", "Ha Tinh"],
            capital: "Vinh",
            population: 4_200_000,
            area: 22_700,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Quang Binh-Quang Tri Heritage Province",
            code: "VN-QB-QT",
            coordinates: Coordinate(latitude: 17.4675, longitude: 106.5952),
            regionType: .province,
            merged: ["Quang Binh", "Quang Tri"],
            capital: "Dong Hoi",
            population: 1_500_000,
            area: 12_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Thua Thien-Hue",
            code: "VN-TTH",
            coordinates: Coordinate(latitude: 16.4637, longitude: 107.5909),
            regionType: .province,
            merged: nil,
            capital: "Hue",
            population: 1_200_000,
            area: 5_000,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: Central Highlands (3 provinces)
        
        ProvinceInfo(
            name: "Kon Tum-Gia Lai Highland Province",
            code: "VN-KT-GL",
            coordinates: Coordinate(latitude: 14.3545, longitude: 108.0000),
            regionType: .province,
            merged: ["Kon Tum", "Gia Lai"],
            capital: "Pleiku",
            population: 2_100_000,
            area: 25_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Dak Lak-Dak Nong Coffee Province",
            code: "VN-DL-DN",
            coordinates: Coordinate(latitude: 12.7100, longitude: 108.2378),
            regionType: .province,
            merged: ["Dak Lak", "Dak Nong"],
            capital: "Buon Ma Thuot",
            population: 2_500_000,
            area: 19_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Lam Dong",
            code: "VN-LD",
            coordinates: Coordinate(latitude: 11.9404, longitude: 108.4583),
            regionType: .province,
            merged: nil,
            capital: "Da Lat",
            population: 1_300_000,
            area: 9_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: Southeast Region (3 provinces - excluding HCMC Metro)
        
        ProvinceInfo(
            name: "Binh Phuoc-Tay Ninh Border Province",
            code: "VN-BP-TN",
            coordinates: Coordinate(latitude: 11.7512, longitude: 106.7234),
            regionType: .province,
            merged: ["Binh Phuoc", "Tay Ninh"],
            capital: "Dong Xoai",
            population: 2_200_000,
            area: 9_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Binh Duong-Long An Industrial Corridor",
            code: "VN-BD-LA",
            coordinates: Coordinate(latitude: 11.3254, longitude: 106.4770),
            regionType: .province,
            merged: ["Binh Duong", "Long An"],
            capital: "Thu Dau Mot",
            population: 3_500_000,
            area: 6_500,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: Mekong Delta (7 provinces - excluding Can Tho Hub)
        
        ProvinceInfo(
            name: "Tien Giang-Ben Tre Delta Province",
            code: "VN-TG-BT",
            coordinates: Coordinate(latitude: 10.4493, longitude: 106.3420),
            regionType: .province,
            merged: ["Tien Giang", "Ben Tre"],
            capital: "My Tho",
            population: 2_900_000,
            area: 4_900,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Tra Vinh-Vinh Long Coastal Province",
            code: "VN-TV-VL",
            coordinates: Coordinate(latitude: 9.9349, longitude: 106.3429),
            regionType: .province,
            merged: ["Tra Vinh", "Vinh Long"],
            capital: "Tra Vinh",
            population: 2_100_000,
            area: 4_300,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Dong Thap-An Giang Rice Province",
            code: "VN-DT-AG",
            coordinates: Coordinate(latitude: 10.4914, longitude: 105.6881),
            regionType: .province,
            merged: ["Dong Thap", "An Giang"],
            capital: "Cao Lanh",
            population: 3_600_000,
            area: 7_100,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Kien Giang",
            code: "VN-KG",
            coordinates: Coordinate(latitude: 10.0125, longitude: 105.0808),
            regionType: .province,
            merged: nil,
            capital: "Rach Gia",
            population: 1_800_000,
            area: 6_300,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Bac Lieu-Ca Mau Coastal Province",
            code: "VN-BL-CM",
            coordinates: Coordinate(latitude: 9.2940, longitude: 105.7215),
            regionType: .province,
            merged: ["Bac Lieu", "Ca Mau"],
            capital: "Bac Lieu",
            population: 2_000_000,
            area: 7_900,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        // MARK: Central Coast (4 provinces)
        
        ProvinceInfo(
            name: "Quang Ngai-Binh Dinh Coastal Province",
            code: "VN-QNG-BD",
            coordinates: Coordinate(latitude: 14.8081, longitude: 108.7433),
            regionType: .province,
            merged: ["Quang Ngai", "Binh Dinh"],
            capital: "Quang Ngai",
            population: 2_500_000,
            area: 11_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Phu Yen-Khanh Hoa Tourism Province",
            code: "VN-PY-KH",
            coordinates: Coordinate(latitude: 12.6833, longitude: 109.1833),
            regionType: .province,
            merged: ["Phu Yen", "Khanh Hoa"],
            capital: "Nha Trang",
            population: 2_200_000,
            area: 8_400,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        ),
        
        ProvinceInfo(
            name: "Ninh Thuan-Binh Thuan Coastal Province",
            code: "VN-NT-BT",
            coordinates: Coordinate(latitude: 11.5752, longitude: 108.9888),
            regionType: .province,
            merged: ["Ninh Thuan", "Binh Thuan"],
            capital: "Phan Rang-Thap Cham",
            population: 1_500_000,
            area: 10_800,
            localCurrency: "VND",
            timezone: "Asia/Ho_Chi_Minh"
        )
    ]
    
    // MARK: - Helper Methods
    
    /// Find province by name (case-insensitive, partial match)
    static func findProvince(byName name: String) -> ProvinceInfo? {
        let lowercaseName = name.lowercased()
        return provinces.first { province in
            province.name.lowercased().contains(lowercaseName) ||
            lowercaseName.contains(province.name.lowercased()) ||
            (province.merged?.contains { $0.lowercased().contains(lowercaseName) } ?? false)
        }
    }
    
    /// Find province by coordinates (nearest province)
    static func findProvince(near coordinate: Coordinate, maxDistance: Double = 100_000) -> ProvinceInfo? {
        provinces.min { p1, p2 in
            let d1 = distance(from: coordinate, to: p1.coordinates)
            let d2 = distance(from: coordinate, to: p2.coordinates)
            return d1 < d2
        }
    }
    
    /// Calculate distance between coordinates (Haversine formula)
    private static func distance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadius = 6371000.0 // meters
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    /// Get all province names (for dropdown/picker)
    static func getAllProvinceNames() -> [String] {
        provinces.map { $0.name }.sorted()
    }
    
    /// Match Google Place result to Vietnam province
    static func matchToProvince(googlePlace: GooglePlaceResult) -> ProvinceInfo? {
        // Try matching by administrative area
        if let adminArea = googlePlace.administrativeArea {
            if let matched = findProvince(byName: adminArea) {
                return matched
            }
        }
        
        // Try matching by vicinity/address
        if let matched = findProvince(byName: googlePlace.formattedAddress) {
            return matched
        }
        
        // Fallback: Find nearest province by coordinates
        return findProvince(near: googlePlace.coordinates)
    }
}

// MARK: - Google Place Result Model

struct GooglePlaceResult: Codable {
    let placeId: String
    let name: String
    let formattedAddress: String
    let coordinates: Coordinate
    let types: [String]
    let vicinity: String?
    
    // Address components from Google
    let administrativeArea: String?  // Province/State level
    let locality: String?            // City level
    let country: String?
    let countryCode: String?
    
    // Additional details (from Place Details API)
    let priceLevel: Int?
    let rating: Double?
    let userRatingsTotal: Int?
    let openingHours: [String]?
    let website: String?
    let phoneNumber: String?
    let photos: [String]?  // Photo references
}
