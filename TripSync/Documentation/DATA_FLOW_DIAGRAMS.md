# Data Flow Diagrams - Current vs Proposed

## 🔴 **CURRENT BROKEN FLOW** (Budget Lost)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER ENTERS BUDGET IN POI CONFIRMATION MODAL                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ POIConfirmationModalViewController                              │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ budgetTextField.text = "30000"                              │ │
│ │ budgetCurrency = "VND"                                      │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │ delegate.poiConfirmationDidConfirm()
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. DAILY PLANNING CREATES TIMELINE BLOCK                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ DailyPlanningViewController                                     │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ tripBuilder.addPOI(                                         │ │
│ │     poi,                                                    │ │
│ │     estimatedBudget: 30000.0,                              │ │
│ │     budgetCurrency: "VND"                                  │ │
│ │ )                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripBuilder.timelines[date]                                     │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ TimelineBlock(                                              │ │
│ │     poi: PointOfInterest(...),                             │ │
│ │     startTime: 9:00,                                       │ │
│ │     duration: 7200,                                        │ │
│ │     estimatedBudget: 30000.0,  ← ✅ BUDGET STORED HERE     │ │
│ │     budgetCurrency: "VND"                                  │ │
│ │ )                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. USER SAVES TRIP                                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripBuilder.build()                                             │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Convert timelines to daily schedules                    │ │
│ │ for (date, timeline) in timelines {                        │ │
│ │     var dailyBudget = 0.0                                  │ │
│ │     for block in timeline.blocks {                         │ │
│ │         // Convert VND → AUD                               │ │
│ │         let budgetInAUD = CurrencyConverter.convertToBase( │ │
│ │             amount: block.estimatedBudget,                 │ │
│ │             from: block.budgetCurrency                     │ │
│ │         )                                                   │ │
│ │         dailyBudget += budgetInAUD  ← ✅ AGGREGATED        │ │
│ │     }                                                       │ │
│ │     schedule.dailyBudget = Money(                          │ │
│ │         amount: dailyBudget,                               │ │
│ │         currency: baseCurrency                             │ │
│ │     )                                                       │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Trip Model (Saved to CoreData + Firebase)                       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Trip {                                                      │ │
│ │     totalBudget: 1.82  ← ✅ TOTAL IN AUD                   │ │
│ │     baseCurrency: "AUD"                                    │ │
│ │     regions: [                                             │ │
│ │         TripRegion {                                       │ │
│ │             pointsOfInterest: [                            │ │
│ │                 PointOfInterest {                          │ │
│ │                     name: "Ha Noi Calido Hotel"           │ │
│ │                     estimatedSpending: nil  ← ❌ NEVER SET │ │
│ │                 }                                          │ │
│ │             ]                                              │ │
│ │         }                                                   │ │
│ │     ]                                                       │ │
│ │     dailySchedules: [                                      │ │
│ │         DailySchedule {                                    │ │
│ │             dailyBudget: Money(1.82, "AUD") ← ✅ SAVED     │ │
│ │             plannedActivities: [                           │ │
│ │                 ScheduledActivity {                        │ │
│ │                     poiId: "abc123"  ← ✅ LINKED           │ │
│ │                 }                                          │ │
│ │             ]                                              │ │
│ │         }                                                   │ │
│ │     ]                                                       │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. USER OPENS TRIP IN MAP VIEW                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripMapViewController                                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Try to get budget for badge                             │ │
│ │ let dayPOIs = trip.regions[dayIndex].pointsOfInterest      │ │
│ │ for poi in dayPOIs {                                       │ │
│ │     if let budget = poi.estimatedSpending {                │ │
│ │         totalBudget += budget.amount                       │ │
│ │     }                                                       │ │
│ │ }                                                           │ │
│ │ // ❌ poi.estimatedSpending is nil!                         │ │
│ │ // budgetBadge shows 0.0                                   │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

❌ BUDGET LOST - Not transferred from TimelineBlock to POI
```

---

## ✅ **PROPOSED FIXED FLOW** (Budget Synced)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1-3. SAME AS BEFORE (User enters budget, creates timeline)     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ DailyPlanningViewController.saveTrip()                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // OLD CODE:                                                │ │
│ │ // let trip = tripBuilder.build()                          │ │
│ │ // CoreDataManager.shared.createTrip(from: trip)           │ │
│ │                                                             │ │
│ │ // NEW CODE:                                                │ │
│ │ if let savedTrip = TripSyncService.shared                  │ │
│ │     .saveTripFromBuilder(tripBuilder) {                    │ │
│ │     print("✅ Trip saved: \(savedTrip.id)")                │ │
│ │     navigationController?.popToRootViewController()        │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripSyncService.saveTripFromBuilder()                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ var trip = tripBuilder.build()                             │ │
│ │                                                             │ │
│ │ // ✅ NEW: Sync budget to POIs                              │ │
│ │ syncBudgetToPOIs(&trip)                                    │ │
│ │                                                             │ │
│ │ CoreDataManager.shared.createTrip(from: trip)              │ │
│ │ FirebaseManager.shared.saveTrip(trip)                      │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripSyncService.syncBudgetToPOIs()                              │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Build POI → Budget mapping from schedules               │ │
│ │ var poiBudgetMap: [String: Money] = [:]                    │ │
│ │                                                             │ │
│ │ for schedule in trip.dailySchedules {                      │ │
│ │     for activity in schedule.plannedActivities {           │ │
│ │         guard let poiId = activity.poiId else { continue } │ │
│ │                                                             │ │
│ │         // Option 1: Use dailyBudget / activity count      │ │
│ │         if let dailyBudget = schedule.dailyBudget {        │ │
│ │             let budgetPerActivity = dailyBudget.amount /   │ │
│ │                 Double(schedule.plannedActivities.count)   │ │
│ │             poiBudgetMap[poiId] = Money(                   │ │
│ │                 amount: budgetPerActivity,                 │ │
│ │                 currency: dailyBudget.currency             │ │
│ │             )                                               │ │
│ │         }                                                   │ │
│ │                                                             │ │
│ │         // Option 2: Store original in activity notes      │ │
│ │         // Extract from notes: "Budget: 30000 VND"         │ │
│ │     }                                                       │ │
│ │ }                                                           │ │
│ │                                                             │ │
│ │ // Apply to all POIs in regions                            │ │
│ │ for regionIndex in trip.regions.indices {                  │ │
│ │     for poiIndex in trip.regions[regionIndex]              │ │
│ │         .pointsOfInterest.indices {                        │ │
│ │         let poiId = trip.regions[regionIndex]              │ │
│ │             .pointsOfInterest[poiIndex].id                 │ │
│ │                                                             │ │
│ │         if let budget = poiBudgetMap[poiId] {              │ │
│ │             trip.regions[regionIndex]                      │ │
│ │                 .pointsOfInterest[poiIndex]                │ │
│ │                 .estimatedSpending = budget ← ✅ SET!       │ │
│ │         }                                                   │ │
│ │     }                                                       │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Trip Model (NOW WITH POI BUDGETS)                               │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Trip {                                                      │ │
│ │     totalBudget: 1.82                                      │ │
│ │     regions: [                                             │ │
│ │         TripRegion {                                       │ │
│ │             pointsOfInterest: [                            │ │
│ │                 PointOfInterest {                          │ │
│ │                     name: "Ha Noi Calido Hotel"           │ │
│ │                     estimatedSpending: Money(             │ │
│ │                         amount: 1.82,  ← ✅ NOW SET!       │ │
│ │                         currency: "AUD"                   │ │
│ │                     )                                      │ │
│ │                 }                                          │ │
│ │             ]                                              │ │
│ │         }                                                   │ │
│ │     ]                                                       │ │
│ │     dailySchedules: [                                      │ │
│ │         DailySchedule {                                    │ │
│ │             dailyBudget: Money(1.82, "AUD")               │ │
│ │         }                                                   │ │
│ │     ]                                                       │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripMapViewController                                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ let dayPOIs = trip.regions[dayIndex].pointsOfInterest      │ │
│ │ var totalBudget = 0.0                                      │ │
│ │                                                             │ │
│ │ for poi in dayPOIs {                                       │ │
│ │     if let budget = poi.estimatedSpending {                │ │
│ │         totalBudget += budget.amount  ← ✅ NOW WORKS!      │ │
│ │     }                                                       │ │
│ │ }                                                           │ │
│ │                                                             │ │
│ │ budgetBadgeLabel.text = "$1.82"  ← ✅ DISPLAYS CORRECTLY   │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

✅ BUDGET SYNCED - POIs now have estimatedSpending populated
```

---

## 🔄 **EDIT FLOW** (Trip → TripBuilder → DailyPlanning)

```
┌─────────────────────────────────────────────────────────────────┐
│ USER TAPS "EDIT" IN TRIP MAP VIEW                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripMapViewController.editTripTapped()                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ guard let builder = TripSyncService.shared                 │ │
│ │     .loadTripForEditing(tripId: trip.id) else {            │ │
│ │     showAlert("Cannot load trip")                          │ │
│ │     return                                                  │ │
│ │ }                                                           │ │
│ │                                                             │ │
│ │ let planningVC = DailyPlanningViewController(              │ │
│ │     tripBuilder: builder                                   │ │
│ │ )                                                           │ │
│ │ navigationController?.pushViewController(planningVC)       │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripSyncService.loadTripForEditing()                            │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Load trip from CoreData                                 │ │
│ │ let trip = CoreDataManager.shared.fetchTrip(id: tripId)    │ │
│ │                                                             │ │
│ │ // Convert to TripBuilder                                  │ │
│ │ let builder = TripBuilder()                                │ │
│ │ builder.setBasicInfo(...)                                  │ │
│ │                                                             │ │
│ │ // ✅ Convert DailySchedules → Timelines                    │ │
│ │ for schedule in trip.dailySchedules {                      │ │
│ │     var timeline = DailyTimeline(date: schedule.date)      │ │
│ │                                                             │ │
│ │     for activity in schedule.plannedActivities {           │ │
│ │         // Find matching POI from regions                  │ │
│ │         guard let poi = findPOI(id: activity.poiId) else { │ │
│ │             continue                                        │ │
│ │         }                                                   │ │
│ │                                                             │ │
│ │         // ✅ Extract budget from POI                        │ │
│ │         let budget = poi.estimatedSpending?.amount ?? 0.0  │ │
│ │         let currency = poi.estimatedSpending?.currency     │ │
│ │             ?? trip.baseCurrency                           │ │
│ │                                                             │ │
│ │         // Create TimelineBlock                            │ │
│ │         let block = TimelineBlock(                         │ │
│ │             poi: poi,                                      │ │
│ │             startTime: activity.start,                     │ │
│ │             duration: activity.end - activity.start,       │ │
│ │             estimatedBudget: budget,  ← ✅ RESTORED        │ │
│ │             budgetCurrency: currency                       │ │
│ │         )                                                   │ │
│ │         timeline.blocks.append(block)                      │ │
│ │     }                                                       │ │
│ │     builder.timelines[schedule.date] = timeline            │ │
│ │ }                                                           │ │
│ │                                                             │ │
│ │ return builder                                             │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ DailyPlanningViewController (EDIT MODE)                         │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Timelines populated with existing POIs                  │ │
│ │ tripBuilder.timelines = {                                  │ │
│ │     "2025-11-11": DailyTimeline(                           │ │
│ │         blocks: [                                          │ │
│ │             TimelineBlock(                                 │ │
│ │                 poi: "Ha Noi Calido Hotel",               │ │
│ │                 estimatedBudget: 30000,  ← ✅ LOADED       │ │
│ │                 budgetCurrency: "VND"                      │ │
│ │             )                                              │ │
│ │         ]                                                   │ │
│ │     )                                                       │ │
│ │ }                                                           │ │
│ │                                                             │ │
│ │ // User can now:                                           │ │
│ │ // - Add new POIs                                          │ │
│ │ // - Remove POIs                                           │ │
│ │ // - Modify times                                          │ │
│ │ // - Update budgets                                        │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ USER SAVES CHANGES                                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ DailyPlanningViewController.saveTrip()                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Check if editing existing trip                          │ │
│ │ if let existingTripId = tripBuilder.existingTripId {       │ │
│ │     // UPDATE mode                                         │ │
│ │     TripSyncService.shared.updateTrip(                     │ │
│ │         tripId: existingTripId,                            │ │
│ │         from: tripBuilder                                  │ │
│ │     )                                                       │ │
│ │ } else {                                                    │ │
│ │     // CREATE mode                                         │ │
│ │     TripSyncService.shared.saveTripFromBuilder(            │ │
│ │         tripBuilder                                        │ │
│ │     )                                                       │ │
│ │ }                                                           │ │
│ └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ TripSyncService.updateTrip()                                    │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ // Load existing trip                                      │ │
│ │ var existingTrip = CoreDataManager.shared.fetchTrip(id)    │ │
│ │                                                             │ │
│ │ // Build updated version from builder                      │ │
│ │ let updatedTrip = tripBuilder.build()                      │ │
│ │                                                             │ │
│ │ // Merge (preserve metadata, update content)               │ │
│ │ existingTrip.regions = updatedTrip.regions                 │ │
│ │ existingTrip.dailySchedules = updatedTrip.dailySchedules   │ │
│ │ existingTrip.totalBudget = updatedTrip.totalBudget         │ │
│ │ existingTrip.lastModified = Date()                         │ │
│ │                                                             │ │
│ │ // Sync budget                                             │ │
│ │ syncBudgetToPOIs(&existingTrip)                            │ │
│ │                                                             │ │
│ │ // Save                                                     │ │
│ │ CoreDataManager.shared.updateTrip(existingTrip)            │ │
│ │ FirebaseManager.shared.saveTrip(existingTrip)              │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

✅ ROUND-TRIP EDITING - Trip → TripBuilder → Trip with budget intact
```

---

## 📊 **KEY IMPROVEMENTS**

| Issue | Before | After |
|-------|--------|-------|
| **Budget Sync** | ❌ TimelineBlock → DailySchedule only | ✅ TimelineBlock → DailySchedule + POI |
| **Edit Flow** | ❌ No way to re-edit saved trip | ✅ Trip → TripBuilder conversion |
| **Data Consistency** | ❌ 3 separate save paths | ✅ Single TripSyncService |
| **Budget Display** | ❌ Always shows $0 in TripMap | ✅ Correct budget from POI.estimatedSpending |
| **Update Logic** | ❌ Create only | ✅ Create + Update modes |

