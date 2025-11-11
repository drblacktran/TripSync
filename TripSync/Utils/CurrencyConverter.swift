//
//  CurrencyConverter.swift
//  TripSync
//
//  Hardcoded currency conversion rates (to be replaced with live API later)
//

import Foundation

class CurrencyConverter {
    
    // MARK: - Hardcoded Exchange Rates (as of Nov 2025)
    // Base currency: AUD
    private static let exchangeRates: [String: Double] = [
        "AUD": 1.0,           // Australian Dollar (base)
        "VND": 16500.0,       // Vietnamese Dong (1 AUD = 16,500 VND)
        "USD": 0.65,          // US Dollar
        "EUR": 0.60,          // Euro
        "GBP": 0.51,          // British Pound
        "JPY": 97.0,          // Japanese Yen
        "CNY": 4.70,          // Chinese Yuan
        "THB": 22.5,          // Thai Baht
        "SGD": 0.87,          // Singapore Dollar
        "MYR": 2.90,          // Malaysian Ringgit
        "IDR": 10200.0,       // Indonesian Rupiah
        "KRW": 860.0,         // South Korean Won
        "NZD": 1.08,          // New Zealand Dollar
        "CAD": 0.90,          // Canadian Dollar
        "HKD": 5.06           // Hong Kong Dollar
    ]
    
    // MARK: - Conversion Methods
    
    /// Convert amount from one currency to another
    /// - Parameters:
    ///   - amount: Amount in source currency
    ///   - from: Source currency code (e.g., "VND")
    ///   - to: Target currency code (e.g., "AUD")
    /// - Returns: Converted amount, or original amount if conversion fails
    static func convert(amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double {
        // If same currency, no conversion needed
        if sourceCurrency == targetCurrency {
            return amount
        }
        
        // Get exchange rates
        guard let sourceRate = exchangeRates[sourceCurrency],
              let targetRate = exchangeRates[targetCurrency] else {
            print("⚠️ [CURRENCY] Unknown currency: \(sourceCurrency) or \(targetCurrency)")
            return amount
        }
        
        // Convert to base currency (AUD) first, then to target
        let amountInAUD = amount / sourceRate
        let convertedAmount = amountInAUD * targetRate
        
        print("💱 [CURRENCY] Converting \(amount) \(sourceCurrency) → \(convertedAmount) \(targetCurrency)")
        print("   Rate: 1 \(sourceCurrency) = \(1.0 / sourceRate) AUD")
        
        return convertedAmount
    }
    
    /// Convert to base currency (AUD)
    /// - Parameters:
    ///   - amount: Amount in source currency
    ///   - from: Source currency code
    /// - Returns: Amount in AUD
    static func convertToBase(amount: Double, from sourceCurrency: String) -> Double {
        return convert(amount: amount, from: sourceCurrency, to: "AUD")
    }
    
    /// Get exchange rate from one currency to another
    /// - Parameters:
    ///   - from: Source currency code
    ///   - to: Target currency code
    /// - Returns: Exchange rate, or nil if currency not found
    static func getExchangeRate(from sourceCurrency: String, to targetCurrency: String) -> Double? {
        // If same currency, rate is 1.0
        if sourceCurrency == targetCurrency {
            return 1.0
        }
        
        // Get exchange rates
        guard let sourceRate = exchangeRates[sourceCurrency],
              let targetRate = exchangeRates[targetCurrency] else {
            print("⚠️ [CURRENCY] Unknown currency: \(sourceCurrency) or \(targetCurrency)")
            return nil
        }
        
        // Calculate rate: (1 / sourceRate) * targetRate
        let rate = targetRate / sourceRate
        return rate
    }
    
    /// Get formatted currency string
    /// - Parameters:
    ///   - amount: Amount to format
    ///   - currency: Currency code
    ///   - locale: Locale for formatting (optional)
    /// - Returns: Formatted string (e.g., "A$123.45" or "₫16,500")
    static func format(amount: Double, currency: String, locale: Locale? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        if let locale = locale {
            formatter.locale = locale
        } else {
            // Use default locale for the currency
            formatter.locale = localeForCurrency(currency)
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
    }
    
    /// Get appropriate locale for currency
    private static func localeForCurrency(_ currency: String) -> Locale {
        switch currency {
        case "AUD": return Locale(identifier: "en_AU")
        case "VND": return Locale(identifier: "vi_VN")
        case "USD": return Locale(identifier: "en_US")
        case "EUR": return Locale(identifier: "en_EU")
        case "GBP": return Locale(identifier: "en_GB")
        case "JPY": return Locale(identifier: "ja_JP")
        case "CNY": return Locale(identifier: "zh_CN")
        case "THB": return Locale(identifier: "th_TH")
        case "SGD": return Locale(identifier: "en_SG")
        default: return Locale.current
        }
    }
    
    /// Get currency symbol for a currency code
    static func symbol(for currency: String) -> String {
        switch currency {
        case "AUD": return "A$"
        case "VND": return "₫"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "¥"
        case "THB": return "฿"
        case "SGD": return "S$"
        case "MYR": return "RM"
        case "IDR": return "Rp"
        case "KRW": return "₩"
        case "NZD": return "NZ$"
        case "CAD": return "C$"
        case "HKD": return "HK$"
        default: return currency
        }
    }
}
