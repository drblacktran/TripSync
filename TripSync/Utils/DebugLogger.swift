//
//  DebugLogger.swift
//  TripSync
//
//  Centralized logging utility to reduce console clutter
//

import Foundation

struct DebugLogger {
    
    enum LogLevel: String {
        case verbose = "📝"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case network = "🌐"
        case database = "💾"
        case ui = "🎨"
        case location = "📍"
        case weather = "🌤️"
        case budget = "💰"
        case map = "🗺️"
    }
    
    // MASTER SWITCH - Set to false to disable ALL debug logging
    #if DEBUG
    static var isEnabled: Bool = true  // ENABLED - Show your app's debug logs
    #else
    static var isEnabled: Bool = false  // Always disabled in release
    #endif
    
    // Control which log levels are shown (useful during debugging)
    static var enabledLevels: Set<LogLevel> = [.success, .error, .warning, .network, .database, .map, .weather, .budget]  // Show important logs
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled, enabledLevels.contains(level) else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        print("\(level.rawValue) [\(timestamp)] [\(fileName):\(line)] \(message)")
    }
    
    // Convenience methods
    static func success(_ message: String) {
        log(message, level: .success)
    }
    
    static func error(_ message: String) {
        log(message, level: .error)
    }
    
    static func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    static func network(_ message: String) {
        log(message, level: .network)
    }
    
    static func database(_ message: String) {
        log(message, level: .database)
    }
}
