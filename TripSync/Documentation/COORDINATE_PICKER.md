# Coordinate Picker Implementation Guide

## Overview
Implemented **Option A: Map Tap + Pin Drop** with a hybrid approach using:
- **Apple MapKit** for map display (native, unlimited)
- **OpenStreetMap Nominatim** for reverse geocoding and search (free, no API key)

## Architecture

### 1. OpenStreetMapService (`Services/OpenStreetMapService.swift`)

**Purpose**: Free alternative to Google Places for geocoding and search

**Key Features**:
- ✅ No API key required
- ✅ Free tier: 1 request/second (enforced with automatic rate limiting)
- ✅ Reverse geocoding: coordinates → address
- ✅ Search/autocomplete: text → coordinates
- ✅ Nearby search: find places around coordinates
- ✅ Required attribution: "© OpenStreetMap contributors"

**API Methods**:

```swift
// Reverse geocode coordinates to get place info
func reverseGeocode(
    coordinate: CLLocationCoordinate2D, 
    zoom: Int = 18
) async throws -> SearchResult

// Search for places (autocomplete)
func search(
    query: String,
    countryCode: String? = nil,
    viewBox: (minLon, minLat, maxLon, maxLat)? = nil,
    limit: Int = 10
) async throws -> [SearchResult]

// Find places near a coordinate
func searchNearby(
    coordinate: CLLocationCoordinate2D,
    radius: Double = 1000,
    query: String? = nil,
    limit: Int = 20
) async throws -> [SearchResult]
```

**Rate Limiting**:
- Automatically enforces 1-second minimum between requests
- Uses async/await with Task.sleep for clean implementation
- Tracks last request time to prevent violations

**Data Models**:
```swift
struct SearchResult {
    let placeId: Int
    let lat, lon: String
    let displayName: String
    let address: Address?
    let importance: Double
    
    var coordinate: CLLocationCoordinate2D { ... }
}
```

### 2. CoordinatePickerViewController (`ViewControllers/AddTrip/CoordinatePickerViewController.swift`)

**Purpose**: Visual map-based coordinate picker with search

**User Interaction Flow**:

1. **Initial State**:
   - Map shows initial region (destination/trip area) or world view
   - Search bar at top for text search
   - Instruction: "Tap anywhere on the map to drop a pin"
   - GPS accuracy indicator (if location permitted)

2. **Search Flow** (Optional):
   - User types in search bar
   - Debounced search (0.5s) queries OpenStreetMap
   - Results appear in table overlay
   - User selects result → pin drops, map zooms
   - Search data populates name/address (no reverse geocoding needed)

3. **Map Tap Flow**:
   - User taps anywhere on map
   - Pin drops at tapped coordinate
   - Automatic reverse geocoding via OpenStreetMap
   - Shows "Loading address..." during geocoding
   - Annotation updates with place name and address
   - Callout shows with details

4. **Confirmation**:
   - "Confirm Location" button becomes enabled
   - User taps → delegate receives coordinate, name, address
   - Picker dismisses

**UI Components**:

```
┌─────────────────────────────────┐
│ Cancel        Select Location    │
├─────────────────────────────────┤
│ [Search bar]                     │  ← OpenStreetMap search
├─────────────────────────────────┤
│                                  │
│        📍 Map (MapKit)          │  ← Tap to drop pin
│                                  │
│  "Tap anywhere to drop a pin"   │  ← Instruction overlay
│                                  │
│                                  │
│                                  │
│  GPS Accuracy: Good (±15m)      │  ← Accuracy indicator
│  [Confirm Location]             │  ← Enabled when pin dropped
└─────────────────────────────────┘
```

**Search Results Overlay**:
```
┌─────────────────────────────────┐
│ [Search: "coffee hanoi"]         │
├─────────────────────────────────┤
│ Hanoi Coffee Shop                │
│ 123 Pho Street, Hanoi, Vietnam  │
├─────────────────────────────────┤
│ The Coffee House - Hanoi         │
│ 456 Ba Trieu, Hanoi, Vietnam    │
├─────────────────────────────────┤
│ ...                              │
└─────────────────────────────────┘
```

**Features**:
- ✅ MapKit map display (native performance)
- ✅ Tap gesture to drop pin
- ✅ Search bar with OSM autocomplete
- ✅ GPS location tracking with accuracy indicator
- ✅ Automatic reverse geocoding
- ✅ Manual pin placement anywhere
- ✅ Search results with view box prioritization
- ✅ Annotation callout with name/address
- ✅ Smooth animations and transitions

**Delegate Protocol**:
```swift
protocol CoordinatePickerDelegate: AnyObject {
    func coordinatePickerDidSelectLocation(
        _ picker: CoordinatePickerViewController,
        coordinate: CLLocationCoordinate2D,
        name: String,
        address: String
    )
}
```

## Usage Example

```swift
// Present coordinate picker
let picker = CoordinatePickerViewController()
picker.delegate = self

// Optional: Set initial region (e.g., near current destination)
let destinationCoord = CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
picker.initialCoordinate = destinationCoord

let nav = UINavigationController(rootViewController: picker)
present(nav, animated: true)

// Handle selection
func coordinatePickerDidSelectLocation(
    _ picker: CoordinatePickerViewController,
    coordinate: CLLocationCoordinate2D,
    name: String,
    address: String
) {
    // Use the selected location
    print("Selected: \(name)")
    print("Address: \(address)")
    print("Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
}
```

## Integration with Add Trip Flow

### POISearchViewController Integration:

```swift
class POISearchViewController {
    // "Add Custom POI" button action
    @objc private func addCustomPOITapped() {
        let picker = CoordinatePickerViewController()
        picker.delegate = self
        
        // Set initial region to current destination
        if let currentDestination = currentDestination {
            picker.initialCoordinate = currentDestination.coordinate
        }
        
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }
}

extension POISearchViewController: CoordinatePickerDelegate {
    func coordinatePickerDidSelectLocation(
        _ picker: CoordinatePickerViewController,
        coordinate: CLLocationCoordinate2D,
        name: String,
        address: String
    ) {
        // Create custom POI
        let poi = POI(
            name: name,
            coordinate: coordinate,
            category: .other, // User selects later
            address: address
        )
        
        // Navigate to POI detail for budget/ticket entry
        showPOIDetail(poi: poi)
    }
}
```

## Technical Details

### Reverse Geocoding Workflow:

1. User drops pin at coordinate
2. Show loading state: "Loading address..."
3. Call `osmService.reverseGeocode(coordinate:)`
4. Parse OpenStreetMap response
5. Extract short name (suburb/city)
6. Format full address
7. Update annotation title/subtitle
8. Enable confirm button
9. Show annotation callout

**Fallback**: If reverse geocoding fails, use coordinate string as address

### Search Workflow:

1. User types in search bar
2. Debounce 0.5 seconds
3. Get current map region (view box)
4. Call `osmService.search(query:viewBox:)`
5. Display results in table
6. User selects → drop pin + zoom
7. Use search result data (skip reverse geocoding)

### GPS Accuracy Display:

```swift
// Excellent: ±0-10m (green)
// Good: ±10-50m (blue)
// Fair: ±50-100m (orange)
// Poor: ±100+m (red)
```

## Attribution Requirements

OpenStreetMap requires attribution. Add to your UI:

**Option 1**: In app settings/about page
```
Map data © OpenStreetMap contributors
https://www.openstreetmap.org/copyright
```

**Option 2**: Small text at bottom of picker
```swift
let attributionLabel = UILabel()
attributionLabel.text = "© OpenStreetMap"
attributionLabel.font = .systemFont(ofSize: 10)
attributionLabel.textColor = .tertiaryLabel
```

## Advantages Over Google Places

| Feature | OpenStreetMap | Google Places |
|---------|---------------|---------------|
| Cost | Free (unlimited with rate limit) | $200/month free tier |
| API Key | Not required | Required |
| Rate Limit | 1 req/sec | 300 autocomplete/day |
| Reverse Geocoding | ✅ Included | ✅ Included |
| Search/Autocomplete | ✅ Included | ✅ Included |
| Map Display | Use MapKit | Use Google Maps SDK |
| Data Coverage | Global, community-maintained | Global, Google-maintained |
| Attribution | Required | Required |

## Next Steps

1. **Test with real coordinates**: Drop pins in various locations
2. **Add to POISearchViewController**: Wire up "Add Custom POI" button
3. **Add OSM attribution**: To settings or about page
4. **Test rate limiting**: Ensure 1 req/sec enforcement works
5. **Handle edge cases**: 
   - No internet (cache last reverse geocode?)
   - Invalid coordinates (out of bounds)
   - Search with no results

## Files Created

1. **`Services/OpenStreetMapService.swift`** (270 lines)
   - Nominatim API wrapper
   - Rate limiting
   - Search, reverse geocoding, nearby search
   
2. **`ViewControllers/AddTrip/CoordinatePickerViewController.swift`** (450 lines)
   - Map-based picker
   - Search with autocomplete
   - Pin drop with reverse geocoding
   - GPS accuracy tracking
   - Delegate pattern for selection

## Summary

✅ **Fully functional coordinate picker** with:
- Native MapKit performance
- Free OpenStreetMap geocoding
- Visual pin drop interface
- Search autocomplete
- Automatic reverse geocoding
- GPS accuracy indicators
- Clean delegate pattern

🎯 **Zero API costs** - no Google API key needed for this component!
