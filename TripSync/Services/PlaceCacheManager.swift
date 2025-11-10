//
//  PlaceCacheManager.swift
//  TripSync
//
//  Local cache for Google Places API results
//  Enables offline access after initial search
//

import Foundation

/// Manages local caching of Google Places results for offline access
class PlaceCacheManager {
    
    static let shared = PlaceCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheDuration: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    
    // In-memory cache for fast access
    private var memoryCache: [String: CachedData] = [:]
    
    struct CachedData: Codable {
        let data: Data
        let timestamp: Date
        let expiresAt: Date
    }
    
    init() {
        // Create cache directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("PlacesCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Clean up old cache on init
        cleanExpiredCache()
    }
    
    // MARK: - Autocomplete Cache
    
    func cacheAutocomplete(query: String, results: [GooglePlaceResult]) {
        let key = "autocomplete_\(query.lowercased().replacingOccurrences(of: " ", with: "_"))"
        saveToCache(key: key, value: results)
    }
    
    func getCachedAutocomplete(query: String) -> [GooglePlaceResult]? {
        let key = "autocomplete_\(query.lowercased().replacingOccurrences(of: " ", with: "_"))"
        return loadFromCache(key: key)
    }
    
    // MARK: - Place Details Cache
    
    func cachePlaceDetails(placeId: String, place: GooglePlaceResult) {
        let key = "place_details_\(placeId)"
        saveToCache(key: key, value: place)
    }
    
    func getCachedPlaceDetails(placeId: String) -> GooglePlaceResult? {
        let key = "place_details_\(placeId)"
        return loadFromCache(key: key)
    }
    
    // MARK: - Nearby Search Cache
    
    func cacheNearbySearch(key: String, results: [GooglePlaceResult]) {
        let cacheKey = "nearby_\(key.replacingOccurrences(of: " ", with: "_"))"
        saveToCache(key: cacheKey, value: results)
    }
    
    func getCachedNearbySearch(key: String) -> [GooglePlaceResult]? {
        let cacheKey = "nearby_\(key.replacingOccurrences(of: " ", with: "_"))"
        return loadFromCache(key: cacheKey)
    }
    
    // MARK: - Generic Cache Operations
    
    private func saveToCache<T: Codable>(key: String, value: T) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            
            let cachedData = CachedData(
                data: data,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(cacheDuration)
            )
            
            // Save to memory cache
            let cacheDataEncoded = try encoder.encode(cachedData)
            memoryCache[key] = cachedData
            
            // Save to disk
            let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
            try cacheDataEncoded.write(to: fileURL)
            
            print("💾 [CACHE] Saved: \(key)")
            
        } catch {
            print("❌ [CACHE] Failed to save \(key): \(error)")
        }
    }
    
    private func loadFromCache<T: Codable>(key: String) -> T? {
        // Check memory cache first
        if let cached = memoryCache[key] {
            if cached.expiresAt > Date() {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let value = try decoder.decode(T.self, from: cached.data)
                    print("💾 [CACHE] Memory hit: \(key)")
                    return value
                } catch {
                    print("❌ [CACHE] Failed to decode from memory: \(error)")
                }
            } else {
                memoryCache.removeValue(forKey: key)
            }
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let cachedData = try decoder.decode(CachedData.self, from: data)
            
            // Check if expired
            guard cachedData.expiresAt > Date() else {
                print("⏰ [CACHE] Expired: \(key)")
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
            
            let value = try decoder.decode(T.self, from: cachedData.data)
            
            // Load into memory cache
            memoryCache[key] = cachedData
            
            print("💾 [CACHE] Disk hit: \(key)")
            return value
            
        } catch {
            print("❌ [CACHE] Failed to load \(key): \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        memoryCache.removeAll()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("🗑️ [CACHE] Cleared all cache")
        } catch {
            print("❌ [CACHE] Failed to clear cache: \(error)")
        }
    }
    
    func cleanExpiredCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            var cleanedCount = 0
            
            for file in files {
                let data = try Data(contentsOf: file)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                if let cachedData = try? decoder.decode(CachedData.self, from: data),
                   cachedData.expiresAt < Date() {
                    try fileManager.removeItem(at: file)
                    cleanedCount += 1
                }
            }
            
            if cleanedCount > 0 {
                print("🗑️ [CACHE] Cleaned \(cleanedCount) expired items")
            }
        } catch {
            print("❌ [CACHE] Failed to clean cache: \(error)")
        }
    }
    
    func getCacheStats() -> CacheStats {
        var totalSize: Int64 = 0
        var fileCount = 0
        var oldestDate: Date?
        var newestDate: Date?
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
                if let created = attributes[.creationDate] as? Date {
                    if oldestDate == nil || created < oldestDate! {
                        oldestDate = created
                    }
                    if newestDate == nil || created > newestDate! {
                        newestDate = created
                    }
                }
                fileCount += 1
            }
        } catch {
            print("❌ [CACHE] Failed to get stats: \(error)")
        }
        
        return CacheStats(
            fileCount: fileCount,
            totalSize: totalSize,
            oldestDate: oldestDate,
            newestDate: newestDate
        )
    }
}

struct CacheStats {
    let fileCount: Int
    let totalSize: Int64  // bytes
    let oldestDate: Date?
    let newestDate: Date?
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
