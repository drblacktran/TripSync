# TripMapViewController Update Plan

## Changes to Implement:

### 1. Header Updates (20px below nav bar)
- ✅ Title and date already present in setupDateButton()
- ✅ Remove coordinate display from title
- Position: 20px below safe area

### 2. Remove Day Number Overlays
- Hide day markers with numbers when specific day selected
- Show only POI icons
- Keep day markers visible in "All Days" view for overview

### 3. Add Expandable Day Details Table View
- Add UITableView below map
- Show when specific day selected
- Display:
  - Activity name
  - Start time - End time
  - Transport mode between activities
- Hide when "All Days" selected

### 4. Route Drawing Logic
- **Single Day View**: Draw lines ONLY between POIs in same day
  - Use transport mode from POI data
  - Color-code by transport type
- **All Days View**: Show POI icons ONLY, no route lines

### 5. Known Issues
- Segmented control scroll view not working (noted for future fix)

## Implementation Steps:
1. Add detailsTableView property
2. Modify filterMapContentByDay() to show/hide table
3. Update createPOIRoutes() to draw lines only for selected day
4. Modify showAllDaysView() to hide routes
5. Update createDayAnnotationView() to hide markers in single day view
