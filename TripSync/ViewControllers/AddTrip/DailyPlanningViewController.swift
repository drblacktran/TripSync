//
//  DailyPlanningViewController.swift
//  TripSync
//
//  Main container for calendar-style trip planning with horizontal day navigation
//

import UIKit
import MapKit

class DailyPlanningViewController: UIViewController {
    
    // MARK: - Properties
    
    private let tripBuilder: TripBuilder
    private var currentDayIndex = 0
    private var days: [Date] = []
    
    // UI Components
    private let tabScrollView = UIScrollView()
    private let tabStackView = UIStackView()
    private var dayButtons: [UIButton] = []
    
    // Simple table view for POIs
    private let poiTableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .systemBackground
        table.separatorStyle = .singleLine
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.register(POIPlanningCell.self, forCellReuseIdentifier: "POIPlanningCell")
        return table
    }()
    
    // Empty state view
    private let emptyStateView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.isHidden = true
        return view
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No places added yet.\nTap '+ Add Place' to start planning your day!"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let emptyStateIcon: UILabel = {
        let label = UILabel()
        label.text = "📍"
        label.font = .systemFont(ofSize: 60)
        label.textAlignment = .center
        return label
    }()
    
    private let addPlaceButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)
    
    // MARK: - Init
    
    init(tripBuilder: TripBuilder) {
        self.tripBuilder = tripBuilder
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Plan Your Trip"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupDays()
        setupUI()
        showDay(at: 0)
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }
    
    private func setupDays() {
        // Generate array of days from start to end date
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: tripBuilder.startDate)
        let endDate = calendar.startOfDay(for: tripBuilder.endDate)
        
        while currentDate <= endDate {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
    }
    
    private func setupUI() {
        // Tab scroll view (horizontal day selector)
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.backgroundColor = .secondarySystemBackground
        
        // Tab stack
        tabStackView.axis = .horizontal
        tabStackView.spacing = 8
        tabStackView.distribution = .fillEqually
        
        // Create day tabs
        for (index, day) in days.enumerated() {
            let button = createDayButton(for: day, index: index)
            tabStackView.addArrangedSubview(button)
            dayButtons.append(button)
        }
        
        // Timeline container replaced with simple table
        poiTableView.delegate = self
        poiTableView.dataSource = self
        
        // Empty state setup
        emptyStateView.addSubview(emptyStateIcon)
        emptyStateView.addSubview(emptyStateLabel)
        
        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -30),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -40)
        ])
        
        // Add Place button
        addPlaceButton.setTitle("+ Add Place", for: .normal)
        addPlaceButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addPlaceButton.backgroundColor = .systemBlue
        addPlaceButton.setTitleColor(.white, for: .normal)
        addPlaceButton.layer.cornerRadius = 12
        addPlaceButton.addTarget(self, action: #selector(addPlaceTapped), for: .touchUpInside)
        
        // Continue button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.backgroundColor = .systemGreen
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 12
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        
        // Hierarchy
        view.addSubview(tabScrollView)
        tabScrollView.addSubview(tabStackView)
        view.addSubview(poiTableView)
        view.addSubview(emptyStateView)
        view.addSubview(addPlaceButton)
        view.addSubview(continueButton)
        
        // Layout
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        poiTableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        addPlaceButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 60),
            
            tabStackView.topAnchor.constraint(equalTo: tabScrollView.topAnchor, constant: 8),
            tabStackView.leadingAnchor.constraint(equalTo: tabScrollView.leadingAnchor, constant: 12),
            tabStackView.trailingAnchor.constraint(equalTo: tabScrollView.trailingAnchor, constant: -12),
            tabStackView.bottomAnchor.constraint(equalTo: tabScrollView.bottomAnchor, constant: -8),
            tabStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // Table fills space between tabs and buttons
            poiTableView.topAnchor.constraint(equalTo: tabScrollView.bottomAnchor, constant: 8),
            poiTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poiTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poiTableView.bottomAnchor.constraint(equalTo: addPlaceButton.topAnchor, constant: -12),
            
            // Empty state fills same space as table
            emptyStateView.topAnchor.constraint(equalTo: tabScrollView.bottomAnchor, constant: 8),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: addPlaceButton.topAnchor, constant: -12),
            
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -30),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -40),
            
            addPlaceButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addPlaceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addPlaceButton.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -8),
            addPlaceButton.heightAnchor.constraint(equalToConstant: 44),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createDayButton(for date: Date, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: date)
        
        button.setTitle("Day \(index + 1)\n\(dateStr)", for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.tag = index
        button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        
        // Set width constraint
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        return button
    }
    
    private func updateDayButtonStyles() {
        for (index, button) in dayButtons.enumerated() {
            if index == currentDayIndex {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                button.backgroundColor = .systemBackground
                button.setTitleColor(.label, for: .normal)
                button.layer.borderColor = UIColor.separator.cgColor
            }
        }
    }
    
    // MARK: - Day Management
    
    private func showDay(at index: Int) {
        guard index >= 0 && index < days.count else { return }
        
        currentDayIndex = index
        updateDayButtonStyles()
        
        // Scroll to selected tab
        if index < dayButtons.count {
            let button = dayButtons[index]
            tabScrollView.scrollRectToVisible(button.frame, animated: true)
        }
        
        // Get or create timeline for this day
        let date = days[index]
        let timeline = tripBuilder.timelines[date] ?? DailyTimeline(date: date)
        
        // Show empty state if no blocks
        let isEmpty = timeline.blocks.isEmpty
        emptyStateView.isHidden = !isEmpty
        poiTableView.isHidden = isEmpty
        
        // Reload table with current day's POIs
        poiTableView.reloadData()
        
        print("📅 [DAY SWITCH] Showing day \(index + 1): \(timeline.blocks.count) POIs")
    }
    
    // MARK: - Actions
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        showDay(at: sender.tag)
    }
    
    @objc private func addPlaceTapped() {
        // Show POI search modal with map
        let selectedDate = days[currentDayIndex]
        let searchVC = POISearchMapViewController(tripBuilder: tripBuilder, selectedDate: selectedDate)
        searchVC.delegate = self
        
        let nav = UINavigationController(rootViewController: searchVC)
        present(nav, animated: true)
        
        print("� [DAILY PLANNING] ====== ADD PLACE FLOW STARTED ======")
        print("📍 [DAILY PLANNING] Opening POISearchMapViewController")
        print("📅 [DAILY PLANNING] For Day \(currentDayIndex + 1): \(formatDate(selectedDate))")
        print("📊 [DAILY PLANNING] Current POIs on this day: \(tripBuilder.timelines[Calendar.current.startOfDay(for: selectedDate)]?.blocks.count ?? 0)")
        print("=================================================")
    }
    
    @objc private func continueTapped() {
        // Check if there are any POIs added
        let hasAnyPOIs = tripBuilder.timelines.values.contains { !$0.blocks.isEmpty }
        
        if !hasAnyPOIs {
            let alert = UIAlertController(
                title: "No Places Added",
                message: "Add at least one place to your trip before continuing.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Check for overlaps
        let hasOverlaps = tripBuilder.timelines.values.contains { $0.hasOverlaps }
        
        if hasOverlaps {
            let alert = UIAlertController(
                title: "Overlapping Times",
                message: "Some activities overlap in time. Do you want to continue anyway?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Fix", style: .cancel))
            alert.addAction(UIAlertAction(title: "Continue Anyway", style: .default) { [weak self] _ in
                self?.proceedToNext()
            })
            present(alert, animated: true)
        } else {
            proceedToNext()
        }
    }
    
    private func proceedToNext() {
        // Save timelines to TripBuilder and proceed
        // This will convert timelines to Trip structure and save
        print("✅ [PLANNING] Proceeding with trip planning")
        
        // For now, just go back or show success
        let alert = UIAlertController(
            title: "Trip Planned!",
            message: "Your trip has been organized. Ready to save?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Save Trip", style: .default) { [weak self] _ in
            self?.saveTrip()
        })
        present(alert, animated: true)
    }
    
    private func saveTrip() {
        // Convert timelines to Trip and save using TripSyncService (Constraint 5: Option A - Confirm dialog handled in backTapped)
        print("💾 [PLANNING] Starting trip save process...")
        
        // Check if editing existing trip or creating new
        if let existingTripId = tripBuilder.existingTripId {
            // UPDATE mode
            print("� [PLANNING] Updating existing trip: \(existingTripId)")
            
            guard let updatedTrip = TripSyncService.shared.updateTrip(tripId: existingTripId, from: tripBuilder) else {
                showErrorAlert(title: "Update Failed", message: "Failed to update trip. Please try again.")
                return
            }
            
            print("✅ [PLANNING] Trip updated successfully: \(updatedTrip.title)")
            
        } else {
            // CREATE mode
            print("💾 [PLANNING] Creating new trip")
            
            guard let savedTrip = TripSyncService.shared.saveTripFromBuilder(tripBuilder) else {
                showErrorAlert(title: "Save Failed", message: "Failed to save trip. Please try again.")
                return
            }
            
            print("✅ [PLANNING] Trip saved successfully: \(savedTrip.title)")
        }
        
        // Navigate back to trip list
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func backTapped() {
        // Check if user has added any POIs (Constraint 5: Option A - Confirmation dialog)
        let hasAnyPOIs = tripBuilder.timelines.values.contains { !$0.blocks.isEmpty }
        
        if hasAnyPOIs {
            // Show save confirmation
            let alert = UIAlertController(
                title: "Save Your Changes?",
                message: "You have \(getTotalPOICount()) place(s) added. Save before leaving?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Save & Exit", style: .default) { [weak self] _ in
                self?.saveTrip()
            })
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            present(alert, animated: true)
        } else {
            // No POIs added, check if editing existing trip
            if tripBuilder.existingTripId != nil {
                // Editing but no changes - just go back
                navigationController?.popViewController(animated: true)
            } else {
                // Creating new trip with no POIs
                let alert = UIAlertController(
                    title: "Discard Trip?",
                    message: "No places were added. Discard this trip?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
                alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                })
                present(alert, animated: true)
            }
        }
    }
    
    private func getTotalPOICount() -> Int {
        return tripBuilder.timelines.values.reduce(0) { $0 + $1.blocks.count }
    }
}

// MARK: - TimelineDayViewDelegate

// MARK: - DurationPickerModalDelegate

extension DailyPlanningViewController: DurationPickerModalDelegate {
    func durationPickerDidSelect(_ controller: DurationPickerModalViewController, duration: TimeInterval) {
        guard let blockId = objc_getAssociatedObject(controller, "blockId") as? String else { return }
        
        let date = days[currentDayIndex]
        tripBuilder.updatePOIBlock(blockId: blockId, on: date, newDuration: duration)
        
        // Refresh table view
        poiTableView.reloadData()
    }
    
    func durationPickerDidCancel(_ controller: DurationPickerModalViewController) {
        // Do nothing
    }
}

// MARK: - POISearchMapDelegate

extension DailyPlanningViewController: POISearchMapDelegate {
    func didSelectPOI(_ poi: PointOfInterest, forDate date: Date) {
        print("📥 [DAILY PLANNING] Received POI from search modal:")
        print("   Name: \(poi.name)")
        print("   Category: \(poi.category.rawValue)")
        print("   Coordinates: \(poi.coordinates.latitude), \(poi.coordinates.longitude)")
        print("   For date: \(formatDate(date))")
        
        // Show POI confirmation modal
        let selectedDate = days[currentDayIndex]
        print("   Current day index: \(currentDayIndex)")
        print("   Selected date (normalized): \(formatDate(selectedDate))")
        
        // Calculate smart start time and duration
        let startTime = calculateNextAvailableTime(for: selectedDate)
        let duration = POIDurationHelper.suggestedDuration(for: poi)
        
        print("   ⏰ Suggested start time: \(formatTime(startTime))")
        print("   ⌛️ Suggested duration: \(Int(duration / 60)) minutes")
        
        // Calculate travel from previous POI if exists
        var travelSegment: TravelSegment?
        var previousBlock: TimelineBlock?
        if let timeline = tripBuilder.timelines[selectedDate],
           let lastBlock = timeline.blocks.last {
            previousBlock = lastBlock
            let distance = calculateDistance(from: lastBlock.poi.coordinates, to: poi.coordinates)
            let mode = TravelSegment.calculateMode(distance: distance)
            let travelDuration = TravelSegment.estimateDuration(distance: distance, mode: mode)
            travelSegment = TravelSegment(mode: mode, duration: travelDuration, distance: distance)
            
            print("   🚗 Travel from previous POI:")
            print("      Distance: \(Int(distance))m")
            print("      Mode: \(mode)")
            print("      Duration: \(Int(travelDuration / 60)) minutes")
        } else {
            print("   ℹ️ No previous POI - this will be first activity of the day")
        }
        
        // Show confirmation modal
        print("   🎭 Showing confirmation modal...")
        let confirmationVC = POIConfirmationModalViewController(
            poi: poi,
            suggestedStartTime: startTime,
            suggestedDuration: duration,
            previousPOI: previousBlock,
            travelSegment: travelSegment
        )
        confirmationVC.delegate = self
        
        present(confirmationVC, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func calculateNextAvailableTime(for date: Date) -> Date {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        guard let timeline = tripBuilder.timelines[normalizedDate] else {
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        if timeline.blocks.isEmpty {
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        guard let lastBlock = timeline.blocks.max(by: { $0.endTime < $1.endTime }) else {
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        
        var nextTime = lastBlock.endTime
        nextTime = nextTime.addingTimeInterval(30 * 60) // 30 min buffer
        
        return TimelineBlock.snapToInterval(nextTime, interval: 15 * 60)
    }
    
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
}

// MARK: - POIConfirmationModalDelegate

extension DailyPlanningViewController: POIConfirmationModalDelegate {
    func poiConfirmationDidConfirm(_ controller: POIConfirmationModalViewController, poi: PointOfInterest, startTime: Date, duration: TimeInterval, estimatedBudget: Double) {
        print("✅ [POI CONFIRMATION] User confirmed POI:")
        print("   Name: \(poi.name)")
        print("   Start time: \(formatTime(startTime))")
        print("   Duration: \(Int(duration / 60)) minutes")
        print("   End time: \(formatTime(startTime.addingTimeInterval(duration)))")
        print("   Estimated Budget: \(estimatedBudget) VND")
        
        // Add POI to timeline
        let selectedDate = days[currentDayIndex]
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        
        print("   📅 Adding to date: \(formatDate(normalizedDate))")
        print("   Current day index: \(currentDayIndex)")
        
        // Get timeline before adding
        let timelineBefore = tripBuilder.timelines[normalizedDate]
        print("   Timeline before: \(timelineBefore?.blocks.count ?? 0) blocks")
        
        // Determine currency based on POI location
        let budgetCurrency = poi.address.contains("Vietnam") || poi.address.contains("Việt Nam") ? "VND" : "AUD"
        
        // Add POI with budget
        tripBuilder.addPOI(poi, to: normalizedDate, at: startTime, duration: duration, estimatedBudget: estimatedBudget, budgetCurrency: budgetCurrency)
        
        // Get timeline after adding
        let timelineAfter = tripBuilder.timelines[normalizedDate]
        print("   Timeline after: \(timelineAfter?.blocks.count ?? 0) blocks")
        
        if let timeline = timelineAfter {
            print("   📋 All blocks in timeline:")
            for (index, block) in timeline.blocks.enumerated() {
                print("      [\(index + 1)] \(block.poi.name): \(formatTime(block.startTime)) - \(formatTime(block.endTime))")
            }
        }
        
        // Refresh table view
        print("   🔄 Refreshing table view...")
        if let timeline = tripBuilder.timelines[normalizedDate] {
            poiTableView.isHidden = false
            emptyStateView.isHidden = true
            poiTableView.reloadData()
            print("   ✅ Table view updated with \(timeline.blocks.count) blocks")
        } else {
            print("   ⚠️ No timeline found for date after adding POI")
        }
        
        print("✅ [PLANNING] POI added and views refreshed")
    }
    
    func poiConfirmationDidCancel(_ controller: POIConfirmationModalViewController) {
        print("❌ [POI CONFIRMATION] User cancelled")
    }
}

// MARK: - UITableViewDataSource & Delegate

extension DailyPlanningViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let selectedDate = days[currentDayIndex]
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        let count = tripBuilder.timelines[normalizedDate]?.blocks.count ?? 0
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POIPlanningCell", for: indexPath) as! POIPlanningCell
        
        let selectedDate = days[currentDayIndex]
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        
        if let timeline = tripBuilder.timelines[normalizedDate],
           indexPath.row < timeline.blocks.count {
            let block = timeline.blocks[indexPath.row]
            cell.configure(with: block, index: indexPath.row + 1)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedDate = days[currentDayIndex]
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        
        if let timeline = tripBuilder.timelines[normalizedDate],
           indexPath.row < timeline.blocks.count {
            let block = timeline.blocks[indexPath.row]
            
            // Show edit options
            let alert = UIAlertController(title: block.poi.name, message: "What would you like to do?", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Edit Duration", style: .default) { [weak self] _ in
                self?.editBlockDuration(block)
            })
            
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
                self?.removeBlock(block)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad
            if let popover = alert.popoverPresentationController {
                popover.sourceView = tableView
                popover.sourceRect = tableView.rectForRow(at: indexPath)
            }
            
            present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selectedDate = days[currentDayIndex]
            let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
            
            if let timeline = tripBuilder.timelines[normalizedDate],
               indexPath.row < timeline.blocks.count {
                let block = timeline.blocks[indexPath.row]
                
                print("🗑️ [TABLE] Deleting POI: \(block.poi.name)")
                
                // Remove from timeline using blockId
                tripBuilder.removePOI(blockId: block.id, from: normalizedDate)
                
                // Refresh table
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                // Show empty state if no blocks left
                if let updatedTimeline = tripBuilder.timelines[normalizedDate], updatedTimeline.blocks.isEmpty {
                    emptyStateView.isHidden = false
                    poiTableView.isHidden = true
                }
                
                print("✅ [TABLE] POI removed")
            }
        }
    }
    
    private func editBlockDuration(_ block: TimelineBlock) {
        let durationPicker = DurationPickerModalViewController(poiName: block.poi.name, suggestedDuration: block.duration)
        durationPicker.delegate = self
        
        // Store block ID for callback
        objc_setAssociatedObject(durationPicker, "blockId", block.id, .OBJC_ASSOCIATION_RETAIN)
        
        present(durationPicker, animated: true)
    }
    
    private func removeBlock(_ block: TimelineBlock) {
        let date = days[currentDayIndex]
        tripBuilder.removePOI(blockId: block.id, from: date)
        
        // Refresh table
        poiTableView.reloadData()
        
        // Show empty state if no blocks left
        if let timeline = tripBuilder.timelines[date], timeline.blocks.isEmpty {
            emptyStateView.isHidden = false
            poiTableView.isHidden = true
        }
        
        print("🗑️ [PLANNING] Removed block: \(block.poi.name)")
    }
}

// MARK: - POI Planning Cell

class POIPlanningCell: UITableViewCell {
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let categoryBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(numberLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(categoryBadge)
        
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 40),
            numberLabel.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: -8),
            
            categoryBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            categoryBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            categoryBadge.heightAnchor.constraint(equalToConstant: 24),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            durationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            durationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with block: TimelineBlock, index: Int) {
        numberLabel.text = "\(index)"
        nameLabel.text = block.poi.name
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeLabel.text = "🕐 \(timeFormatter.string(from: block.startTime)) - \(timeFormatter.string(from: block.endTime))"
        
        let minutes = Int(block.duration / 60)
        durationLabel.text = "⌛️ \(minutes) min"
        
        categoryBadge.text = " \(block.poi.category.rawValue.capitalized) "
    }
}
