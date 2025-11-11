//
//  TripSyncService.swift
//  TripSync
//
//  Unified service for trip CRUD operations across all view controllers
//  Ensures DailyPlanning, TripMap, and AddTrip use the same data structures
//

import Foundation
import CoreData

/// Central service for trip management - ensures consistency across all view controllers
class TripSyncService {
    
    static let shared = TripSyncService()
    
    private init() {}
    
    // MARK: - Save Trip from TripBuilder
    
    /// Converts TripBuilder timelines → Trip model and saves to CoreData + Firebase
    /// - Parameter tripBuilder: The TripBuilder with timelines
    /// - Returns: Saved Trip object with ID
    func saveTripFromBuilder(_ tripBuilder: TripBuilder) -> Trip? {
        print("💾 [TRIP SYNC] Starting trip save from TripBuilder...")
        
        // Build trip from timelines
        var trip = tripBuilder.build()
        
        // Sync budget from TimelineBlocks to PointOfInterest.estimatedSpending
        syncBudgetToPOIs(&trip, timelines: tripBuilder.timelines)
        
        // Save to Core Data
        guard let tripEntity = CoreDataManager.shared.createTrip(from: trip) else {
            print("❌ [TRIP SYNC] Failed to save trip to Core Data")
            return nil
        }
        
        print("✅ [TRIP SYNC] Trip saved to Core Data: \(tripEntity.id ?? "")")
        
        // Save to Firebase (async)
        FirebaseManager.shared.saveTrip(trip) { result in
            switch result {
            case .success:
                print("✅ [TRIP SYNC] Trip synced to Firebase")
            case .failure(let error):
                print("⚠️ [TRIP SYNC] Firebase sync failed: \(error)")
            }
        }
        
        return trip
    }
    
    // MARK: - Update Existing Trip
    
    /// Updates an existing trip with new POIs from daily planning
    /// - Parameters:
    ///   - tripId: The ID of the trip to update
    ///   - tripBuilder: The TripBuilder with updated data
    /// - Returns: Updated Trip object
    func updateTrip(tripId: String, from tripBuilder: TripBuilder) -> Trip? {
        print("🔄 [TRIP SYNC] Updating trip: \(tripId)")
        
        // Find existing trip entity
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tripId)
        
        guard let tripEntity = try? CoreDataManager.shared.context.fetch(request).first else {
            print("❌ [TRIP SYNC] Trip not found: \(tripId)")
            return nil
        }
        
        // Rebuild trip from timelines
        var updatedTrip = tripBuilder.build()
        updatedTrip.lastModified = Date()
        
        // Sync budget with timelines
        syncBudgetToPOIs(&updatedTrip, timelines: tripBuilder.timelines)
        
        // Recalculate all budgets (Constraint 4: Option D)
        recalculateAllBudgets(&updatedTrip)
        
        // Update Core Data entity
        CoreDataManager.shared.updateTripEntity(tripEntity, from: updatedTrip)
        CoreDataManager.shared.save()
        
        print("✅ [TRIP SYNC] Trip updated in Core Data")
        
        // Sync to Firebase
        FirebaseManager.shared.saveTrip(updatedTrip) { result in
            switch result {
            case .success:
                print("✅ [TRIP SYNC] Updated trip synced to Firebase")
            case .failure(let error):
                print("⚠️ [TRIP SYNC] Firebase sync failed: \(error)")
            }
        }
        
        return updatedTrip
    }
    
    // MARK: - Load Trip for Editing
    
    /// Load trip for editing (converts Trip → TripBuilder)
    /// - Parameter tripId: The trip ID
    /// - Returns: TripBuilder populated with trip data
    func loadTripForEditing(tripId: String) -> TripBuilder? {
        print("📂 [TRIP SYNC] Loading trip for editing: \(tripId)")
        
        // For synchronous loading, try Firebase cache first
        // Note: This is a simplified approach - in production, use async callback
        var loadedTrip: Trip?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        FirebaseManager.shared.fetchTrips { result in
            switch result {
            case .success(let trips):
                loadedTrip = trips.first(where: { $0.id == tripId })
            case .failure(let error):
                print("❌ [TRIP SYNC] Failed to load trip: \(error)")
            }
            semaphore.signal()
        }
        
        // Wait for fetch (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        guard let trip = loadedTrip else {
            print("❌ [TRIP SYNC] Trip not found")
            return nil
        }
        
        // Convert Trip back to TripBuilder
        let builder = convertToTripBuilder(trip: trip)
        
        print("✅ [TRIP SYNC] Trip loaded into TripBuilder")
        return builder
    }
    
    // MARK: - Budget Synchronization
    
    /// Syncs budget from TimelineBlocks to PointOfInterest.estimatedSpending
    /// Decision: Option A - TimelineBlock as source of truth, sync to POI
    /// Decision: Option C - Store original currency with exchange rate for conversion
    private func syncBudgetToPOIs(_ trip: inout Trip, timelines: [Date: DailyTimeline]) {
        print("💰 [BUDGET SYNC] Syncing budget from TimelineBlocks to POIs...")
        
        // Build mapping of POI ID → original budget from timeline blocks
        var poiBudgetMap: [String: (amount: Double, currency: String)] = [:]
        
        for (_, timeline) in timelines {
            for block in timeline.blocks {
                // Store ORIGINAL budget (not converted)
                poiBudgetMap[block.poi.id] = (
                    amount: block.estimatedBudget,
                    currency: block.budgetCurrency
                )
            }
        }
        
        // Update POIs in all regions with original currency + exchange rate
        for regionIndex in trip.regions.indices {
            for poiIndex in trip.regions[regionIndex].pointsOfInterest.indices {
                let poiId = trip.regions[regionIndex].pointsOfInterest[poiIndex].id
                if let budgetData = poiBudgetMap[poiId] {
                    // Calculate exchange rate for on-the-fly conversion
                    let exchangeRate = CurrencyConverter.getExchangeRate(
                        from: budgetData.currency,
                        to: trip.baseCurrency
                    )
                    
                    trip.regions[regionIndex].pointsOfInterest[poiIndex].estimatedSpending = Money(
                        amount: budgetData.amount,
                        currency: budgetData.currency,
                        exchangeRate: exchangeRate
                    )
                    
                    let convertedAmount = budgetData.amount * (exchangeRate ?? 1.0)
                    print("   ✅ POI '\(trip.regions[regionIndex].pointsOfInterest[poiIndex].name)':")
                    print("      Original: \(budgetData.amount) \(budgetData.currency)")
                    print("      Converted: \(convertedAmount) \(trip.baseCurrency) (rate: \(exchangeRate ?? 1.0))")
                }
            }
        }
        
        print("✅ [BUDGET SYNC] Synced \(poiBudgetMap.count) POIs with original currency + exchange rates")
    }
    
    // MARK: - Budget Recalculation (Constraint 4: Option D)
    
    /// Recalculates all budget levels: POI → Daily → Trip total
    /// Triggered when any POI budget changes in edit mode
    private func recalculateAllBudgets(_ trip: inout Trip) {
        print("💰 [BUDGET RECALC] Recalculating all budgets...")
        
        var tripTotal: Double = 0.0
        
        // Recalculate daily budgets from POIs
        for scheduleIndex in trip.dailySchedules.indices {
            var dailyTotal: Double = 0.0
            
            for activity in trip.dailySchedules[scheduleIndex].plannedActivities {
                guard let poiId = activity.poiId else { continue }
                
                // Find POI and get its budget
                if let poi = findPOI(id: poiId, in: trip.regions),
                   let budget = poi.estimatedSpending {
                    // Convert to base currency if needed
                    let amountInBase = budget.convertedAmount ?? budget.amount
                    dailyTotal += amountInBase
                }
            }
            
            // Update daily budget
            trip.dailySchedules[scheduleIndex].dailyBudget = Money(
                amount: dailyTotal,
                currency: trip.baseCurrency
            )
            
            tripTotal += dailyTotal
            print("   📅 Day \(scheduleIndex + 1): \(dailyTotal) \(trip.baseCurrency)")
        }
        
        // Update trip total
        trip.totalBudget = tripTotal
        print("✅ [BUDGET RECALC] Trip total budget: \(tripTotal) \(trip.baseCurrency)")
    }
    
    // MARK: - Trip to TripBuilder Conversion
    
    /// Converts a saved Trip back into TripBuilder for editing
    private func convertToTripBuilder(trip: Trip) -> TripBuilder {
        let builder = TripBuilder()
        
        // Set existing trip ID for edit mode (Decision 2: Option A)
        builder.existingTripId = trip.id
        
        // Set basic info
        builder.setBasicInfo(
            title: trip.title,
            startDate: trip.startDate,
            endDate: trip.endDate,
            homeCountry: trip.homeCountry,
            baseCurrency: trip.baseCurrency
        )
        
        // Convert daily schedules back to timelines
        for schedule in trip.dailySchedules {
            let date = schedule.date
            var timeline = DailyTimeline(date: date)
            
            // Convert scheduled activities back to timeline blocks
            for activity in schedule.plannedActivities.sorted(by: { $0.startTime < $1.startTime }) {
                // Find matching POI from regions
                guard let poiId = activity.poiId,
                      let poi = findPOI(id: poiId, in: trip.regions) else {
                    print("⚠️ [TRIP SYNC] POI not found for activity: \(activity.title)")
                    continue
                }
                
                // Extract budget from POI
                let estimatedBudget = poi.estimatedSpending?.amount ?? 0.0
                let budgetCurrency = poi.estimatedSpending?.currency ?? trip.baseCurrency
                
                // Create timeline block
                let block = TimelineBlock(
                    poi: poi,
                    startTime: activity.startTime,
                    duration: activity.endTime.timeIntervalSince(activity.startTime),
                    estimatedBudget: estimatedBudget,
                    budgetCurrency: budgetCurrency
                )
                
                timeline.blocks.append(block)
            }
            
            builder.timelines[date] = timeline
        }
        
        print("✅ [TRIP SYNC] Converted \(trip.dailySchedules.count) schedules to timelines")
        return builder
    }
    
    /// Helper: Find POI by ID in trip regions (recursive search)
    private func findPOI(id: String, in regions: [TripRegion]) -> PointOfInterest? {
        for region in regions {
            // Search in current region
            if let poi = region.pointsOfInterest.first(where: { $0.id == id }) {
                return poi
            }
            
            // Search in subregions recursively
            if let poi = findPOI(id: id, in: region.subRegions) {
                return poi
            }
        }
        return nil
    }
    
    // MARK: - Delete Trip
    
    /// Deletes a trip from Core Data and Firebase
    func deleteTrip(tripId: String) -> Bool {
        print("🗑️ [TRIP SYNC] Deleting trip: \(tripId)")
        
        // Find trip entity to delete
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tripId)
        
        guard let tripEntity = try? CoreDataManager.shared.context.fetch(request).first else {
            print("❌ [TRIP SYNC] Trip not found: \(tripId)")
            return false
        }
        
        // Delete from Core Data
        CoreDataManager.shared.deleteTrip(tripEntity)
        CoreDataManager.shared.save()
        
        print("✅ [TRIP SYNC] Deleted from Core Data")
        
        // Delete from Firebase
        FirebaseManager.shared.deleteTrip(tripId: tripId) { result in
            switch result {
            case .success:
                print("✅ [TRIP SYNC] Deleted from Firebase")
            case .failure(let error):
                print("⚠️ [TRIP SYNC] Firebase deletion failed: \(error)")
            }
        }
        
        return true
    }
}

// MARK: - Extensions for Consistent Budget Access

extension PointOfInterest {
    /// Get budget amount in consistent format (Money struct)
    var budgetAmount: Money? {
        return estimatedSpending
    }
    
    /// Set budget amount (ensures consistency)
    mutating func setBudget(amount: Double, currency: String) {
        self.estimatedSpending = Money(amount: amount, currency: currency)
    }
}

extension TimelineBlock {
    /// Convert to Money struct for consistency
    var budgetAsMoney: Money {
        return Money(amount: estimatedBudget, currency: budgetCurrency)
    }
}
