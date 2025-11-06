# Currency System Documentation

## Overview
TripSync uses a hierarchical currency system with automatic fallback to ensure budget amounts are always displayed in the most appropriate currency.

## Currency Hierarchy (Fallback Chain)

The system follows this priority order when displaying budgets:

1. **POI Level** (Highest Priority)
   - `PointOfInterest.estimatedSpending.currency`
   - Most specific - individual attraction/activity currency
   - Example: Entry fee to a museum in VND

2. **Region Level** (Medium Priority)
   - `TripRegion.localCurrency`
   - Regional currency for cities/countries
   - Example: All POIs in Ho Chi Minh City use VND

3. **Trip Level** (Fallback)
   - `Trip.baseCurrency`
   - Usually the traveler's home currency
   - Example: AUD for Australian travelers

## How It Works

### Budget Badge Display
```swift
// Automatic currency selection:
Currency = POI.currency ?? Region.localCurrency ?? Trip.baseCurrency
```

When viewing a day's budget:
- If any POI has a specific currency set → Use that currency
- Otherwise, use the region's local currency
- If region currency is empty → Fall back to trip's base currency

### Example Scenario

**Trip Setup:**
- Base Currency: `AUD` (Australian Dollar)
- Traveler from Australia

**Region: Ho Chi Minh City**
- Local Currency: `VND` (Vietnamese Dong)

**POIs:**
1. Ben Thanh Market: 500,000 VND (currency set)
2. War Remnants Museum: 200,000 VND (currency set)
3. Free Walking Tour: No budget data

**Result:** Budget badge shows **"850K VND"** (uses POI currency)

## Currency Formatting

### VND (Vietnamese Dong) - Special K/M Notation
- **≥ 1,000,000**: Display as "M" (millions)
  - Example: 2,500,000 → "2.5M VND"
- **≥ 1,000**: Display as "K" (thousands)
  - Example: 850,000 → "850K VND"
- **< 1,000**: Display full number
  - Example: 500 → "500 VND"

### Other Currencies
- Standard formatting with currency symbol
- Example: "$150 AUD", "€50 EUR", "¥1000 JPY"

## Future: Exchange Rate Integration

The `Money` struct is already prepared for real-time exchange rates:

```swift
struct Money {
    let amount: Double
    let currency: String
    let exchangeRate: Double?      // Ready for API integration
    let convertedAmount: Double?   // Auto-calculated from rate
}
```

### Recommended APIs:
1. **exchangerate-api.com** (Free tier: 1,500 requests/month)
2. **fixer.io** (Reliable, paid)
3. **currencyapi.com** (Good free tier)

### Implementation Plan:
1. Create `ExchangeRateService.swift`
2. Fetch rates daily and cache in Firestore
3. Update `Money` initializer to accept live rates
4. Display both local and converted amounts in budget breakdown

## Code Location

- **Models**: `ComprehensiveTripModels.swift`
  - `Trip.baseCurrency`
  - `TripRegion.localCurrency`
  - `Money` struct with exchange rate support

- **Budget Logic**: `TripMapViewController.swift`
  - `loadDayActivities()` - Calculates daily budget with currency fallback
  - `budgetBadgeTapped()` - Shows breakdown modal
  - `getDisplayCurrency()` - Implements fallback logic

- **Formatting**: `CurrencyFormatter.swift`
  - `formatCompact()` - Main formatter with K/M notation
  - `formatVND()` - Vietnamese Dong specific formatting

## Usage Examples

### Setting Currency for POIs (Mock Data)
```swift
var poi = PointOfInterest(name: "Museum", ...)
poi.estimatedSpending = Money(
    amount: 200000,
    currency: "VND",
    exchangeRate: 0.000059  // VND to AUD (for future conversion)
)
```

### Setting Regional Currency
```swift
var region = TripRegion(name: "Ho Chi Minh City", ...)
region.localCurrency = "VND"
```

### Setting Trip Base Currency
```swift
var trip = Trip(title: "Vietnam Adventure", ...)
trip.baseCurrency = "AUD"  // Traveler's home currency
```

## Benefits

1. **Flexibility**: Support different currencies at different levels
2. **User-Friendly**: Always shows most relevant currency
3. **Future-Proof**: Ready for exchange rate APIs
4. **Smart Fallback**: Never shows empty or missing currency
5. **Regional Accuracy**: Respects local currencies

---

**Last Updated**: November 6, 2025
**Version**: 1.0
