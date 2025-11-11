# TripSync Architecture & Data Flow Analysis

## 📊 **Current State Analysis**

After auditing **DailyPlanningViewController**, **AddTripViewController**, and **TripMapViewController**, I've identified critical inconsistencies in data handling.

---

## ⚠️ **CRITICAL ISSUES FOUND**

### **1. Budget Storage Mismatch**

**Problem:** Budget data is stored in THREE different places:

| Location | Structure | Used By | Format |
|----------|-----------|---------|--------|
| `TimelineBlock` | `estimatedBudget: Double`<br>`budgetCurrency: String` | DailyPlanningViewController<br>AddTripViewController | Raw double + currency string |
| `PointOfInterest` | `estimatedSpending: Money?` | TripMapViewController | Money struct (amount, currency, exchangeRate) |
| `DailySchedule` | `dailyBudget: Money?` | TripBuilder.build() | Money struct (aggregated) |

**Impact:**
- When user adds POI with budget in DailyPlanning, it's stored in `TimelineBlock`
- When TripBuilder.build() runs, it converts to `DailySchedule.dailyBudget`
- TripMap tries to read from `POI.estimatedSpending` which is **NEVER SET** ❌
- **Result:** Budget badge shows 0 in TripMap even after successful save

**Current Flow:**
```
User enters 30000 VND in POIConfirmationModal
  → TimelineBlock(estimatedBudget: 30000, budgetCurrency: "VND")
  → TripBuilder.build() converts to DailySchedule.dailyBudget (Money)
  → Trip.totalBudget = aggregated amount
  → POI.estimatedSpending = nil ⚠️ NEVER POPULATED
  → TripMap.budgetBadge reads POI.estimatedSpending → SHOWS 0
```

---

### **2. POI Data Structure Mismatch**

**Problem:** POI data exists in TWO parallel structures:

| Structure | Used In | Properties | Lifecycle |
|-----------|---------|------------|-----------|
| `TimelineBlock` | DailyPlanning | `poi: PointOfInterest`<br>`startTime: Date`<br>`duration: TimeInterval`<br>`estimatedBudget: Double`<br>`budgetCurrency: String` | Temporary (planning phase) |
| `PointOfInterest` | TripMap | `name`, `category`, `coordinates`<br>`estimatedSpending: Money?`<br>`plannedVisitDate: Date?`<br>`estimatedDuration: TimeInterval` | Final (saved trip) |

**Impact:**
- TimelineBlock wraps POI + adds timing data
- When saved, TimelineBlock → ScheduledActivity (loses budget)
- POI in Trip.regions never gets budget updated
- **Result:** No budget breakdown in TripMap

**Missing Link:**
```swift
// TripBuilder.build() creates ScheduledActivity but doesn't update POI.estimatedSpending:
var activity = ScheduledActivity(
    title: block.poi.name,  // ✅ Name copied
    start: block.startTime, // ✅ Time copied
    end: block.endTime      // ✅ Time copied
)
activity.poiId = block.poi.id  // ✅ ID linked
// ❌ MISSING: activity.budget = block.estimatedBudget
// ❌ MISSING: Update POI.estimatedSpending in region
```

---

### **3. No Edit Flow**

**Problem:** Once trip is saved, there's NO way to re-edit it

| Flow | Current State | Missing |
|------|---------------|---------|
| Create New Trip | ✅ AddTrip → DailyPlanning → Save | Working |
| View Saved Trip | ✅ TripList → TripMap (read-only) | Working |
| Edit Saved Trip | ❌ No entry point | **MISSING** |
| Add POI to Existing Trip | ❌ No flow | **MISSING** |
| Update POI Budget | ❌ No UI | **MISSING** |

**Impact:**
- User creates trip with 5 POIs
- Realizes they forgot museum visit
- **Cannot add it** without recreating entire trip
- **Cannot update budget** if plans change

---

## 🎯 **DECISIONS NEEDED FROM YOU**

### **Decision 1: Budget Storage Location**

**Option A: Use TimelineBlock as source of truth (Recommended)**
- ✅ Simpler: All budget logic in planning flow
- ✅ Clean separation: Planning uses TimelineBlock, display uses POI
- ❌ Need sync step: TimelineBlock.estimatedBudget → POI.estimatedSpending

**Option B: Use POI.estimatedSpending everywhere**
- ✅ Single source of truth
- ❌ Complex: Need to update POI during planning
- ❌ Breaks current TimelineBlock structure

**My Recommendation:**
Use **Option A** with automatic sync in `TripBuilder.build()`:
```swift
// In TripBuilder.build(), after creating regions:
for region in trip.regions {
    for poi in region.pointsOfInterest {
        // Find corresponding timeline block
        if let block = findTimelineBlock(for: poi.id) {
            poi.estimatedSpending = Money(
                amount: block.estimatedBudget,
                currency: block.budgetCurrency
            )
        }
    }
}
```

**Your Decision:** [ Option A / Option B / Custom Solution ]

---

### **Decision 2: Edit Trip Flow**

**Option A: Convert Trip → TripBuilder for editing**
- When user taps "Edit Trip"
- Load Trip from CoreData
- Convert to TripBuilder with timelines
- Re-enter DailyPlanningViewController
- ✅ Reuse existing UI
- ❌ Complex conversion logic

**Option B: Create separate Edit UI**
- New `TripEditViewController`
- Direct manipulation of Trip.regions and POIs
- ✅ Simple, no conversion
- ❌ Duplicate UI code

**Option C: Make TripMap editable**
- Add "Edit Mode" to TripMap
- Allow adding/removing POIs directly
- ✅ In-context editing
- ❌ Major refactor of TripMap

**My Recommendation:**
Use **Option A** with service layer:
- Create `TripSyncService.loadTripForEditing()` that converts Trip → TripBuilder
- Add "Edit Trip" button in TripMap → navigates to DailyPlanning with loaded data
- User makes changes
- Save updates existing trip instead of creating new

**Your Decision:** [ Option A / Option B / Option C / Custom ]

---

### **Decision 3: Currency Handling**

**Current Issues:**
- POI entered in VND → TimelineBlock stores "VND"
- TripBuilder converts to AUD using hardcoded rates
- DailySchedule.dailyBudget stores in AUD
- Trip.totalBudget stores in AUD
- But POI.estimatedSpending is nil

**Options:**

**Option A: Store both original and converted**
```swift
struct POI {
    var estimatedSpending: Money? // Original currency (VND)
    var estimatedSpendingBase: Money? // Converted to base (AUD)
}
```

**Option B: Store only base currency everywhere**
```swift
// Convert immediately when entered
let budgetInBase = CurrencyConverter.convertToBase(30000, from: "VND")
poi.estimatedSpending = Money(amount: budgetInBase, currency: "AUD")
```

**Option C: Use Money.exchangeRate for on-the-fly conversion**
```swift
struct Money {
    let amount: Double // 30000
    let currency: String // "VND"
    let exchangeRate: Double? // 0.000061 (VND to AUD)
    var convertedAmount: Double? { // 1.82 AUD
        amount * (exchangeRate ?? 1.0)
    }
}
```

**My Recommendation:**
Use **Option C** - it's already in your Money struct!
- Store original amount + currency
- Store exchange rate (from CurrencyConverter or API)
- Calculate convertedAmount on demand
- TripMap badge shows either original OR base based on settings

**Your Decision:** [ Option A / Option B / Option C / Custom ]

---

## 🛠️ **CREATED SOLUTION: TripSyncService**

I've created **`TripSyncService.swift`** that provides:

### **Core Methods:**

```swift
// Save new trip from DailyPlanning
TripSyncService.shared.saveTripFromBuilder(_ tripBuilder: TripBuilder) -> Trip?

// Update existing trip
TripSyncService.shared.updateTrip(tripId: String, from tripBuilder: TripBuilder) -> Trip?

// Load trip for editing
TripSyncService.shared.loadTripForEditing(tripId: String) -> TripBuilder?

// Delete trip
TripSyncService.shared.deleteTrip(tripId: String) -> Bool
```

### **Features:**

1. **Automatic Budget Sync:** `syncBudgetToPOIs()` copies TimelineBlock.estimatedBudget → POI.estimatedSpending
2. **Bidirectional Conversion:** Trip ↔ TripBuilder for editing
3. **Unified Save:** CoreData + Firebase in one call
4. **Consistent POI Mapping:** Maintains linkage between ScheduledActivity ↔ POI

### **Integration Example:**

**DailyPlanningViewController.saveTrip():**
```swift
// OLD: Direct save
let trip = tripBuilder.build()
CoreDataManager.shared.createTrip(from: trip)
FirebaseManager.shared.saveTrip(trip)

// NEW: Use TripSyncService
if let savedTrip = TripSyncService.shared.saveTripFromBuilder(tripBuilder) {
    print("✅ Trip saved with ID: \(savedTrip.id)")
    navigationController?.popToRootViewController(animated: true)
}
```

**TripMapViewController (Add Edit Button):**
```swift
navigationItem.rightBarButtonItem = UIBarButtonItem(
    title: "Edit",
    style: .plain,
    target: self,
    action: #selector(editTripTapped)
)

@objc private func editTripTapped() {
    guard let builder = TripSyncService.shared.loadTripForEditing(tripId: trip.id) else {
        showAlert("Cannot load trip for editing")
        return
    }
    
    let planningVC = DailyPlanningViewController(tripBuilder: builder)
    navigationController?.pushViewController(planningVC, animated: true)
}
```

---

## 📋 **CONSTRAINTS YOU NEED TO PROVIDE**

### **1. Budget Display Preference**

**Question:** In TripMap budget badge, which should be shown?

- **Option A:** Original currency (30000 VND)
- **Option B:** Base currency (1.82 AUD)
- **Option C:** Both with toggle button

**Answer:** [ A / B / C ]

---

### **2. Edit Mode Trigger**

**Question:** How should users enter edit mode?

- **Option A:** "Edit" button in TripMap navigation bar
- **Option B:** Long-press on trip in TripList → "Edit Trip" menu
- **Option C:** Swipe action in TripList (Edit / Delete)
- **Option D:** Separate "Edit Mode" toggle in TripMap

**Answer:** [ A / B / C / D / Combination ]

---

### **3. POI Addition in Existing Trip**

**Question:** When editing existing trip, should user be able to:

- **Option A:** Only modify existing POIs (time, budget)
- **Option B:** Add new POIs to existing days
- **Option C:** Remove POIs from days
- **Option D:** All of the above

**Answer:** [ A / B / C / D ]

---

### **4. Budget Update Propagation**

**Question:** If user updates POI budget in edit mode, should it:

- **Option A:** Update only that POI's estimatedSpending
- **Option B:** Recalculate entire day's budget
- **Option C:** Recalculate entire trip's totalBudget
- **Option D:** All of the above

**Answer:** [ A / B / C / D ]

---

### **5. Unsaved Changes Handling**

**Question:** If user edits trip but doesn't save, should we:

- **Option A:** Show confirmation dialog on back
- **Option B:** Auto-save changes (no confirmation)
- **Option C:** Discard changes silently
- **Option D:** Save as draft (separate from published trip)

**Answer:** [ A / B / C / D ]

---

## 🔧 **IMPLEMENTATION CHECKLIST**

Once you provide the above decisions, I'll implement:

### **Phase 1: Budget Sync (CRITICAL)**
- [ ] Implement `syncBudgetToPOIs()` in TripBuilder.build()
- [ ] Update DailyPlanningViewController to use TripSyncService
- [ ] Test budget flow: POIConfirmation → TimelineBlock → POI → TripMap badge

### **Phase 2: Edit Flow**
- [ ] Add "Edit" button to TripMap (based on your Decision 2)
- [ ] Implement Trip → TripBuilder conversion
- [ ] Handle unsaved changes (based on Decision 5)

### **Phase 3: POI Management in Edit Mode**
- [ ] Add/Remove POI functionality (based on Decision 3)
- [ ] Update budget recalculation (based on Decision 4)
- [ ] Real-time preview in TripMap

### **Phase 4: Currency Display**
- [ ] Implement currency toggle (based on Decision 1)
- [ ] Show both original + converted if needed
- [ ] User preference persistence

---

## 📝 **YOUR ACTION ITEMS**

Please provide answers to:

1. ✅ **Decision 1:** Budget storage strategy [ ]
2. ✅ **Decision 2:** Edit flow approach [ ]
3. ✅ **Decision 3:** Currency handling [ ]
4. ✅ **Constraint 1:** Budget display preference [ ]
5. ✅ **Constraint 2:** Edit mode trigger [ ]
6. ✅ **Constraint 3:** POI modification scope [ ]
7. ✅ **Constraint 4:** Budget update propagation [ ]
8. ✅ **Constraint 5:** Unsaved changes handling [ ]

**Reply format:**
```
Decision 1: Option A
Decision 2: Option A
Decision 3: Option C
Constraint 1: Option B
Constraint 2: Option A
Constraint 3: Option D
Constraint 4: Option D
Constraint 5: Option A
```

Once I have your answers, I'll:
1. Update TripSyncService with your choices
2. Modify all three view controllers to use unified service
3. Add edit flow with proper POI/budget handling
4. Create comprehensive test scenarios
