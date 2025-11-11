//
//  AddTripViewController.swift
//  TripSync
//
//  Main entry point for creating a new trip
//

import UIKit

protocol AddTripDelegate: AnyObject {
    func didAddTrip(_ trip: Trip)
}

class AddTripViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: AddTripDelegate?
    private var selectedCountry: Country?
    
    // MARK: - Trip Builder
    
    private var tripBuilder: TripBuilder!
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Create New Trip"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let tripNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Trip Name (e.g., Vietnam Adventure)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date()
        return picker
    }()
    
    private let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date()
        return picker
    }()
    
    private let homeCountryTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Tap to select home country"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.text = "🇦🇺 Australia"
        textField.isUserInteractionEnabled = true
        return textField
    }()
    
    private let baseCurrencyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Currency (auto-filled)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.text = "AUD"
        textField.isEnabled = false // Read-only, auto-filled from country
        textField.textColor = .secondaryLabel
        return textField
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next: Add Destinations", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tripBuilder = TripBuilder()
        
        // Set default country (Australia)
        selectedCountry = Country.allCountries.first { $0.code == "AU" }
        
        setupUI()
        setupActions()
        setupKeyboardDismiss()
        
        // Auto-set end date to 7 days after start date
        endDatePicker.date = Calendar.current.date(byAdding: .day, value: 7, to: startDatePicker.date) ?? Date()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create labels once
        let startDateLabel = createLabel("Start Date:")
        let endDateLabel = createLabel("End Date:")
        let homeCountryLabel = createLabel("Home Country:")
        let baseCurrencyLabel = createLabel("Base Currency:")
        
        [headerLabel, tripNameTextField, startDateLabel, startDatePicker,
         endDateLabel, endDatePicker, homeCountryLabel,
         homeCountryTextField, baseCurrencyLabel, baseCurrencyTextField,
         nextButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        // Layout form fields
        var lastView: UIView = headerLabel
        let spacing: CGFloat = 12
        
        for subview in [tripNameTextField, startDateLabel, startDatePicker,
                        endDateLabel, endDatePicker, homeCountryLabel,
                        homeCountryTextField, baseCurrencyLabel, baseCurrencyTextField] {
            NSLayoutConstraint.activate([
                subview.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: spacing),
                subview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                subview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])
            
            if let textField = subview as? UITextField {
                textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }
            
            lastView = subview
        }
        
        NSLayoutConstraint.activate([
            nextButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 32),
            nextButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        // Add tap gesture to country field
        let countryTapGesture = UITapGestureRecognizer(target: self, action: #selector(countryFieldTapped))
        homeCountryTextField.addGestureRecognizer(countryTapGesture)
    }
    
    @objc private func countryFieldTapped() {
        let countryPicker = CountryPickerViewController()
        countryPicker.delegate = self
        let nav = UINavigationController(rootViewController: countryPicker)
        present(nav, animated: true)
    }
    
    @objc private func startDateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date < startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
        endDatePicker.minimumDate = startDatePicker.date
    }
    
    @objc private func nextButtonTapped() {
        // Validate input
        guard let tripName = tripNameTextField.text, !tripName.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a trip name")
            return
        }
        
        guard let country = selectedCountry else {
            showAlert(title: "Missing Information", message: "Please select a home country")
            return
        }
        
        guard startDatePicker.date < endDatePicker.date else {
            showAlert(title: "Invalid Dates", message: "End date must be after start date")
            return
        }
        
        // Build basic trip info
        tripBuilder.setBasicInfo(
            title: tripName,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            homeCountry: country.name,
            baseCurrency: country.currency
        )
        
        // Navigate to daily planning view (calendar-style interface)
        let planningVC = DailyPlanningViewController(tripBuilder: tripBuilder)
        navigationController?.pushViewController(planningVC, animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CountryPickerDelegate

extension AddTripViewController: CountryPickerDelegate {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountry country: Country) {
        selectedCountry = country
        
        // Update UI
        homeCountryTextField.text = "\(country.flag) \(country.name)"
        baseCurrencyTextField.text = country.currency
    }
}

// MARK: - Trip Builder

class TripBuilder {
    private var title: String = ""
    var startDate: Date = Date() // Public for DatePickerModal
    var endDate: Date = Date()   // Public for DatePickerModal
    private var _homeCountry: String = "Australia"
    private var _baseCurrency: String = "AUD"
    private var destinations: [TripRegion] = []
    
    // Calendar-style timeline support
    var timelines: [Date: DailyTimeline] = [:]  // Date → Timeline mapping
    
    // Edit mode support (Decision 2: Option A - Track existing trip ID)
    var existingTripId: String?  // Set when editing existing trip
    
    // Public getters
    var homeCountry: String { _homeCountry }
    var baseCurrency: String { _baseCurrency }
    
    func setBasicInfo(title: String, startDate: Date, endDate: Date, homeCountry: String, baseCurrency: String) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self._homeCountry = homeCountry
        self._baseCurrency = baseCurrency
        
        // Initialize empty timelines for each day
        initializeTimelines()
    }
    
    private func initializeTimelines() {
        timelines.removeAll()
        
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        while currentDate <= end {
            timelines[currentDate] = DailyTimeline(date: currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    // MARK: - Timeline POI Management
    
    /// Add POI to a specific date's timeline
    func addPOI(_ poi: PointOfInterest, to date: Date, at startTime: Date? = nil, duration: TimeInterval? = nil, estimatedBudget: Double = 0.0, budgetCurrency: String = "VND") {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard var timeline = timelines[normalizedDate] else { return }
        
        // Calculate smart start time if not provided
        let finalStartTime = startTime ?? calculateNextAvailableTime(for: normalizedDate)
        
        // Calculate smart duration if not provided
        let finalDuration = duration ?? POIDurationHelper.suggestedDuration(for: poi)
        
        print("📅 [TRIP BUILDER] Adding POI '\(poi.name)' to timeline")
        print("   Start Time: \(finalStartTime)")
        print("   Duration: \(finalDuration) seconds (\(Int(finalDuration / 60)) minutes)")
        print("   End Time: \(finalStartTime.addingTimeInterval(finalDuration))")
        print("   Budget: \(estimatedBudget) \(budgetCurrency)")
        
        // Create timeline block
        let block = TimelineBlock(
            poi: poi,
            startTime: finalStartTime,
            duration: finalDuration,
            estimatedBudget: estimatedBudget,
            budgetCurrency: budgetCurrency
        )
        
        // Add block to timeline
        timeline.blocks.append(block)
        
        print("   Timeline now has \(timeline.blocks.count) block(s)")
        
        // Update travel segment to next block if there's a previous block
        if timeline.blocks.count > 1 {
            let previousIndex = timeline.blocks.count - 2
            updateTravelSegment(in: &timeline, from: previousIndex, to: timeline.blocks.count - 1)
        }
        
        timelines[normalizedDate] = timeline
    }
    
    /// Remove POI block from timeline
    func removePOI(blockId: String, from date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard var timeline = timelines[normalizedDate] else { return }
        
        timeline.blocks.removeAll { $0.id == blockId }
        timelines[normalizedDate] = timeline
    }
    
    /// Update POI block time/duration
    func updatePOIBlock(blockId: String, on date: Date, newStartTime: Date? = nil, newDuration: TimeInterval? = nil) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard var timeline = timelines[normalizedDate] else { return }
        guard let index = timeline.blocks.firstIndex(where: { $0.id == blockId }) else { return }
        
        if let newTime = newStartTime {
            timeline.blocks[index].startTime = newTime
        }
        if let newDur = newDuration {
            timeline.blocks[index].duration = newDur
        }
        
        // Update travel segments
        if index > 0 {
            updateTravelSegment(in: &timeline, from: index - 1, to: index)
        }
        if index < timeline.blocks.count - 1 {
            updateTravelSegment(in: &timeline, from: index, to: index + 1)
        }
        
        timelines[normalizedDate] = timeline
    }
    
    /// Calculate next available time slot for a POI
    private func calculateNextAvailableTime(for date: Date) -> Date {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard let timeline = timelines[normalizedDate] else {
            // Default to 9 AM
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        if timeline.blocks.isEmpty {
            // First POI of the day - default to 9 AM
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        // Find last block and add its duration + travel time
        guard let lastBlock = timeline.blocks.max(by: { $0.endTime < $1.endTime }) else {
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        var nextTime = lastBlock.endTime
        
        // Add estimated travel time to next POI (placeholder - will be calculated when POI is selected)
        nextTime = nextTime.addingTimeInterval(30 * 60) // 30 min buffer
        
        return TimelineBlock.snapToInterval(nextTime, interval: 15 * 60)
    }
    
    /// Update travel segment between two blocks
    private func updateTravelSegment(in timeline: inout DailyTimeline, from fromIndex: Int, to toIndex: Int) {
        guard fromIndex < timeline.blocks.count,
              toIndex < timeline.blocks.count,
              fromIndex >= 0,
              toIndex >= 0 else { return }
        
        let fromBlock = timeline.blocks[fromIndex]
        let toBlock = timeline.blocks[toIndex]
        
        // Calculate distance between POIs
        let fromCoord = fromBlock.poi.coordinates
        let toCoord = toBlock.poi.coordinates
        
        let distance = calculateDistance(from: fromCoord, to: toCoord)
        let mode = TravelSegment.calculateMode(distance: distance)
        let duration = TravelSegment.estimateDuration(distance: distance, mode: mode)
        
        let travelSegment = TravelSegment(mode: mode, duration: duration, distance: distance)
        timeline.blocks[fromIndex].travelToNext = travelSegment
    }
    
    /// Calculate distance between two coordinates (Haversine formula)
    private func calculateDistance(from: Coordinate, to: Coordinate) -> Double {
        let earthRadius = 6371000.0 // meters
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    // MARK: - Original Methods
    
    func addDestination(_ region: TripRegion) {
        destinations.append(region)
    }
    
    func removeDestination(at index: Int) {
        guard index < destinations.count else { return }
        destinations.remove(at: index)
    }
    
    func getDestinations() -> [TripRegion] {
        return destinations
    }
    
    func build() -> Trip {
        print("🏗️ [TRIP BUILDER] Building trip...")
        print("   📅 Dates: \(startDate) to \(endDate)")
        print("   🗓️ Timelines: \(timelines.count) days")
        print("   🏛️ Destinations (regions): \(destinations.count)")
        
        var trip = Trip(
            title: title,
            startDate: startDate,
            endDate: endDate,
            homeCountry: homeCountry
        )
        
        trip.baseCurrency = baseCurrency
        
        // Collect all POIs from timelines and create regions
        var allPOIs: [PointOfInterest] = []
        var regionsByCountry: [String: [PointOfInterest]] = [:]
        
        for (_, timeline) in timelines {
            for block in timeline.blocks {
                allPOIs.append(block.poi)
                
                // Group POIs by country (extract from address)
                let country = extractCountry(from: block.poi.address)
                regionsByCountry[country, default: []].append(block.poi)
            }
        }
        
        print("   📍 Found \(allPOIs.count) total POIs from timelines")
        print("   🌍 Countries detected: \(regionsByCountry.keys.joined(separator: ", "))")
        
        // Create regions from POIs if destinations is empty
        var finalRegions = destinations
        if finalRegions.isEmpty && !allPOIs.isEmpty {
            print("   🏗️ No pre-defined regions, creating from POIs...")
            
            for (country, pois) in regionsByCountry {
                // Create a region for this country
                let regionId = UUID().uuidString
                var region = TripRegion(
                    id: regionId,
                    name: country,
                    country: country,
                    arrivalDate: startDate,
                    departureDate: endDate
                )
                
                // Add all POIs to the region
                region.pointsOfInterest = pois
                
                // Set coordinates to first POI's location
                if let firstPOI = pois.first {
                    region.coordinates = firstPOI.coordinates
                }
                
                finalRegions.append(region)
                print("      ✅ Created region '\(country)' with \(pois.count) POIs")
            }
        }
        
        trip.regions = finalRegions
        trip.isInternational = finalRegions.contains { $0.country != homeCountry }
        trip.targetCountries = Array(Set(finalRegions.map { $0.country }))
        
        print("   🗺️ Final trip structure:")
        print("      - Regions: \(trip.regions.count)")
        for (idx, region) in trip.regions.enumerated() {
            print("         \(idx + 1). \(region.name): \(region.pointsOfInterest.count) POIs")
        }
        
        // Convert timelines to DailySchedule
        var dailySchedules: [DailySchedule] = []
        var totalBudgetInBaseCurrency: Double = 0.0
        
        for (date, timeline) in timelines.sorted(by: { $0.key < $1.key }) {
            // Skip empty timelines
            if timeline.blocks.isEmpty {
                continue
            }
            
            var scheduledActivities: [ScheduledActivity] = []
            var dailyBudget: Double = 0.0
            
            for block in timeline.blocks.sorted(by: { $0.startTime < $1.startTime }) {
                // Convert budget to base currency
                let budgetInBase = CurrencyConverter.convertToBase(amount: block.estimatedBudget, from: block.budgetCurrency)
                dailyBudget += budgetInBase
                
                print("   💰 Activity '\(block.poi.name)': \(block.estimatedBudget) \(block.budgetCurrency) → \(budgetInBase) AUD")
                
                // Create scheduled activity from timeline block
                var activity = ScheduledActivity(
                    title: block.poi.name,
                    start: block.startTime,
                    end: block.endTime
                )
                
                // Set POI ID for reference
                activity.poiId = block.poi.id
                
                // Add notes with location and activity type info
                let activityType = mapPOICategoryToActivityType(block.poi.category)
                let location = block.poi.address ?? ""
                activity.notes = "Type: \(activityType)\nLocation: \(location)"
                
                // Add transportation to next activity if exists
                if let travel = block.travelToNext {
                    activity.transportationToActivity = TransportationMethod(
                        mode: travel.mode,
                        from: block.poi.name,
                        to: "", // Will be filled when we know next POI
                        departureTime: block.endTime,
                        arrivalTime: block.endTime.addingTimeInterval(travel.duration)
                    )
                }
                
                scheduledActivities.append(activity)
            }
            
            // Create daily schedule
            // Try to determine region from POI coordinates (use first POI's region)
            let regionId = determineRegionId(from: timeline.blocks)
            
            var schedule = DailySchedule(date: date, regionId: regionId ?? "unknown")
            schedule.plannedActivities = scheduledActivities
            
            // Set daily budget using Money struct
            if dailyBudget > 0 {
                schedule.dailyBudget = Money(amount: dailyBudget, currency: baseCurrency)
            }
            
            totalBudgetInBaseCurrency += dailyBudget
            print("   📅 Daily budget for \(date): \(dailyBudget) AUD")
            
            dailySchedules.append(schedule)
        }
        
        trip.dailySchedules = dailySchedules
        
        // Set total budget
        if totalBudgetInBaseCurrency > 0 {
            trip.totalBudget = totalBudgetInBaseCurrency
            trip.actualSpent = 0.0
            print("   💰 Total trip budget: \(totalBudgetInBaseCurrency) \(baseCurrency)")
        }
        
        return trip
    }
    
    private func mapPOICategoryToActivityType(_ category: POICategory) -> String {
        switch category {
        case .museum, .attraction, .cultural, .religious:
            return "Sightseeing"
        case .restaurant, .cafe:
            return "Dining"
        case .park, .nature, .beach:
            return "Outdoor"
        case .shopping, .market:
            return "Shopping"
        case .entertainment, .nightlife:
            return "Entertainment"
        case .accommodation:
            return "Accommodation"
        case .transportation:
            return "Transportation"
        case .viewpoint:
            return "Sightseeing"
        case .medical, .other:
            return "Other"
        }
    }
    
    private func determineRegionId(from blocks: [TimelineBlock]) -> String? {
        // For now, return nil - will be enhanced later to match POI coordinates to regions
        // This would require region data to be available in TripBuilder
        return nil
    }
    
    /// Extract country name from address string
    private func extractCountry(from address: String) -> String {
        // Common patterns: addresses end with country name
        let components = address.components(separatedBy: ", ")
        
        // Check last component for known countries
        if let lastComponent = components.last?.trimmingCharacters(in: .whitespaces) {
            let knownCountries = ["Vietnam", "Việt Nam", "Thailand", "Singapore", "Malaysia", 
                                 "Indonesia", "Japan", "China", "Australia", "USA", "United States"]
            
            for country in knownCountries {
                if lastComponent.contains(country) {
                    return country == "Việt Nam" ? "Vietnam" : country
                }
            }
        }
        
        // Default to "Unknown" if can't determine
        return "Unknown Location"
    }
}
