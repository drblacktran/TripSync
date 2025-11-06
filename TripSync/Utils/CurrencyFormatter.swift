//
//  CurrencyFormatter.swift
//  TripSync
//
//  Utility for formatting currency with compact notation (K, M for Vietnamese Dong)
//

import Foundation

class CurrencyFormatter {
    
    /// Format currency with compact notation (K for thousands, M for millions)
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currency: Currency code (e.g., "VND", "AUD")
    ///   - showSymbol: Whether to show currency symbol
    /// - Returns: Formatted string (e.g., "2.5M VND", "$50")
    static func formatCompact(amount: Double, currency: String, showSymbol: Bool = true) -> String {
        // Special handling for Vietnamese Dong (VND) - use K/M notation
        if currency.uppercased() == "VND" {
            return formatVND(amount: amount, showSymbol: showSymbol)
        }
        
        // For other currencies, use standard formatting with K/M for large amounts
        if amount >= 1_000_000 {
            let millions = amount / 1_000_000
            let formatted = String(format: "%.1fM", millions)
            return showSymbol ? "\(currencySymbol(for: currency))\(formatted)" : formatted
        } else if amount >= 1_000 {
            let thousands = amount / 1_000
            let formatted = String(format: "%.1fK", thousands)
            return showSymbol ? "\(currencySymbol(for: currency))\(formatted)" : formatted
        } else {
            let formatted = String(format: "%.0f", amount)
            return showSymbol ? "\(currencySymbol(for: currency))\(formatted)" : formatted
        }
    }
    
    /// Format Vietnamese Dong with K/M notation
    /// - Parameters:
    ///   - amount: Amount in VND
    ///   - showSymbol: Whether to show "VND"
    /// - Returns: Formatted string (e.g., "2.5M VND", "500K VND")
    static func formatVND(amount: Double, showSymbol: Bool = true) -> String {
        let suffix = showSymbol ? " VND" : ""
        
        if amount >= 1_000_000 {
            // Millions
            let millions = amount / 1_000_000
            if millions >= 100 {
                return String(format: "%.0fM%@", millions, suffix)
            } else if millions >= 10 {
                return String(format: "%.1fM%@", millions, suffix)
            } else {
                return String(format: "%.1fM%@", millions, suffix)
            }
        } else if amount >= 1_000 {
            // Thousands
            let thousands = amount / 1_000
            if thousands >= 100 {
                return String(format: "%.0fK%@", thousands, suffix)
            } else {
                return String(format: "%.0fK%@", thousands, suffix)
            }
        } else if amount > 0 {
            // Less than 1K - show full amount
            return String(format: "%.0f%@", amount, suffix)
        } else {
            return showSymbol ? "0 VND" : "0"
        }
    }
    
    /// Get currency symbol for a currency code
    /// - Parameter currency: Currency code (e.g., "AUD", "USD")
    /// - Returns: Currency symbol (e.g., "$", "€")
    static func currencySymbol(for currency: String) -> String {
        let locale = NSLocale(localeIdentifier: currency)
        return locale.displayName(forKey: .currencySymbol, value: currency) ?? currency
    }
    
    /// Format money with both local currency and home currency
    /// - Parameters:
    ///   - localAmount: Amount in local currency
    ///   - localCurrency: Local currency code (e.g., "VND")
    ///   - homeAmount: Converted amount in home currency
    ///   - homeCurrency: Home currency code (e.g., "AUD")
    /// - Returns: Formatted string (e.g., "2.5M VND ($150 AUD)")
    static func formatWithConversion(localAmount: Double, localCurrency: String, homeAmount: Double, homeCurrency: String) -> String {
        let local = formatCompact(amount: localAmount, currency: localCurrency)
        let home = formatCompact(amount: homeAmount, currency: homeCurrency)
        return "\(local) (\(home))"
    }
    
    /// Calculate total from an array of Money objects
    /// - Parameter moneyArray: Array of Money objects
    /// - Returns: Total amount in the first currency found, or 0
    static func sumMoney(_ moneyArray: [Money?]) -> Double {
        return moneyArray.compactMap { $0?.amount }.reduce(0, +)
    }
}
