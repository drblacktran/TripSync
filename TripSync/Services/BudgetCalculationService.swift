//
//  BudgetCalculationService.swift
//  TripSync
//
//  Application-layer service for budget calculations
//

import Foundation

/// Service for calculating budgets at the application layer
/// Separates budget logic from database/model layer
class BudgetCalculationService {
    
    // MARK: - Budget Results
    
    struct DayBudget {
        let day: Int
        let date: Date
        let amount: Double
        let currency: String
        let items: [BudgetItem]
    }
    
    struct BudgetItem {
        let name: String
        let amount: Double
        let currency: String
        let category: String?
    }
    
    struct TripBudgetSummary {
        let totalAmount: Double
        let currency: String
        let dailyBudgets: [DayBudget]
        let itemCount: Int
        let averageDailySpend: Double
    }
    
    // MARK: - Day Budget Calculation
    
    /// Calculate budget for a specific day
    /// - Parameters:
    ///   - dayIndex: Zero-based day index (0 = first day)
    ///   - trip: The trip to calculate budget for
    /// - Returns: DayBudget with amount and currency, or nil if no budget data
    static func calculateDayBudget(for dayIndex: Int, in trip: Trip) -> DayBudget? {
        guard let dayRegion = getRegionForDay(dayIndex, in: trip) else {
            return nil
        }
        
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
        
        // Currency fallback: Region → Trip base currency
        var displayCurrency = dayRegion.localCurrency.isEmpty ? trip.baseCurrency : dayRegion.localCurrency
        
        var totalAmount: Double = 0
        var items: [BudgetItem] = []
        
        print("💰 [BUDGET SERVICE] Calculating budget for Day \(dayIndex + 1)")
        print("💰 [BUDGET SERVICE] Region currency: \(dayRegion.localCurrency), Trip base: \(trip.baseCurrency)")
        
        for poi in dayRegion.pointsOfInterest {
            if let estimatedSpending = poi.estimatedSpending {
                // Use POI currency if set, otherwise use display currency
                let poiCurrency = estimatedSpending.currency.isEmpty ? displayCurrency : estimatedSpending.currency
                
                print("   💵 \(poi.name): \(estimatedSpending.amount) \(poiCurrency)")
                totalAmount += estimatedSpending.amount
                
                items.append(BudgetItem(
                    name: poi.name,
                    amount: estimatedSpending.amount,
                    currency: poiCurrency,
                    category: poi.category.rawValue
                ))
                
                // Update display currency to match POI currency (if consistent)
                if !estimatedSpending.currency.isEmpty {
                    displayCurrency = estimatedSpending.currency
                }
            }
        }
        
        print("💰 [BUDGET SERVICE] Total daily budget: \(totalAmount) \(displayCurrency)")
        
        guard totalAmount > 0 else {
            return nil
        }
        
        return DayBudget(
            day: dayIndex + 1,
            date: dayDate,
            amount: totalAmount,
            currency: displayCurrency,
            items: items
        )
    }
    
    // MARK: - Trip Budget Calculation
    
    /// Calculate total budget for entire trip
    /// - Parameter trip: The trip to calculate budget for
    /// - Returns: TripBudgetSummary with total amount and breakdown by day
    static func calculateTripBudget(for trip: Trip) -> TripBudgetSummary {
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        
        var dailyBudgets: [DayBudget] = []
        var totalAmount: Double = 0
        var itemCount: Int = 0
        let currency = trip.baseCurrency  // Use trip's base currency for totals
        
        print("💰 [BUDGET SERVICE] Calculating trip budget for \(numberOfDays + 1) days")
        print("💰 [BUDGET SERVICE] Trip base currency: \(currency)")
        
        // Calculate budget for each day
        for dayIndex in 0...numberOfDays {
            if let dayBudget = calculateDayBudget(for: dayIndex, in: trip) {
                dailyBudgets.append(dayBudget)
                
                // Convert to trip base currency if needed
                // TODO: In future, use exchange rates for accurate conversion
                // For now, just sum amounts (assumes same currency or provides warning)
                if dayBudget.currency != currency {
                    print("⚠️ [BUDGET SERVICE] Day \(dayBudget.day) uses \(dayBudget.currency) but trip uses \(currency) - conversion needed")
                }
                
                totalAmount += dayBudget.amount
                itemCount += dayBudget.items.count
            }
        }
        
        let averageDailySpend = dailyBudgets.isEmpty ? 0 : totalAmount / Double(dailyBudgets.count)
        
        print("💰 [BUDGET SERVICE] Trip total: \(totalAmount) \(currency)")
        print("💰 [BUDGET SERVICE] Days with budget: \(dailyBudgets.count)")
        print("💰 [BUDGET SERVICE] Average daily: \(averageDailySpend) \(currency)")
        
        return TripBudgetSummary(
            totalAmount: totalAmount,
            currency: currency,
            dailyBudgets: dailyBudgets,
            itemCount: itemCount,
            averageDailySpend: averageDailySpend
        )
    }
    
    // MARK: - Helper Methods
    
    private static func getRegionForDay(_ dayIndex: Int, in trip: Trip) -> TripRegion? {
        // Find any parent region with subregions (e.g., country with cities)
        guard let parentRegion = trip.regions.first(where: { !$0.subRegions.isEmpty }) else {
            // No subregions, return first region
            return trip.regions.first
        }
        
        // Direct index mapping to subregions (cities)
        if dayIndex < parentRegion.subRegions.count {
            let subRegion = parentRegion.subRegions[dayIndex]
            print("🗓️ [BUDGET SERVICE] Day \(dayIndex + 1) → \(subRegion.name)")
            return subRegion
        }
        
        // Fallback: return last subregion if index out of bounds
        return parentRegion.subRegions.last
    }
}
