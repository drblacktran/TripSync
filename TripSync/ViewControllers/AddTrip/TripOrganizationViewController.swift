//
//  TripOrganizationViewController.swift
//  TripSync
//
//  Preview how cities and POIs are organized into destinations
//

import UIKit
import CoreLocation

class TripOrganizationViewController: UIViewController {
    
    // MARK: - Properties
    
    private let tripBuilder: TripBuilder
    private var destinations: [OrganizedDestination]
    private var ungroupedPOIs: [SearchResultItem]
    
    private var isLoading = false
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(DestinationHeaderCell.self, forCellReuseIdentifier: "DestinationHeaderCell")
        table.register(POICell.self, forCellReuseIdentifier: "POICell")
        return table
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Trip", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    // MARK: - Init
    
    init(tripBuilder: TripBuilder, destinations: [OrganizedDestination], ungroupedPOIs: [SearchResultItem]) {
        self.tripBuilder = tripBuilder
        self.destinations = destinations
        self.ungroupedPOIs = ungroupedPOIs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Review Trip Organization"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        
        [tableView, saveButton, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -8),
            
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.hidesWhenStopped = true
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        guard !isLoading else { return }
        
        showLoadingIndicator()
        
        // Build trip from organized destinations
        Task {
            do {
                let trip = try await buildTripFromOrganization()
                await MainActor.run {
                    hideLoadingIndicator()
                    completeTripCreation(trip)
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    showError("Failed to create trip: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Trip Building
    
    private func buildTripFromOrganization() async throws -> Trip {
        print("🏗️ Building trip from \(destinations.count) destinations and \(ungroupedPOIs.count) ungrouped POIs")
        
        var regions: [TripRegion] = []
        
        // Convert each organized destination to a TripRegion
        for destination in destinations {
            let region = try await convertDestinationToRegion(destination)
            regions.append(region)
        }
        
        // Add ungrouped POIs to trip builder (they'll be in a general region)
        if !ungroupedPOIs.isEmpty {
            let ungroupedRegion = try await createRegionForUngroupedPOIs(ungroupedPOIs)
            regions.append(ungroupedRegion)
        }
        
        // Add all regions to trip builder
        regions.forEach { tripBuilder.addDestination($0) }
        
        // Build the final trip
        var trip = tripBuilder.build()
        
        // Generate daily schedules based on trip duration
        trip.dailySchedules = generateDailySchedules(for: trip)
        
        print("✅ Trip built successfully: \(trip.title)")
        print("   - Regions: \(trip.regions.count)")
        print("   - Days: \(trip.dailySchedules.count)")
        
        return trip
    }
    
    private func convertDestinationToRegion(_ destination: OrganizedDestination) async throws -> TripRegion {
        print("   Converting destination: \(destination.name)")
        
        // Determine coordinates for the region (use first POI's coordinates or province center)
        let regionCoordinate: Coordinate
        
        if let firstPOI = destination.pois.first, let coord = firstPOI.coordinate {
            regionCoordinate = Coordinate(latitude: coord.latitude, longitude: coord.longitude)
        } else if let province = destination.province {
            regionCoordinate = province.coordinates  // Fixed: was .coordinate
        } else {
            // Default to center of Vietnam if no coordinates available
            regionCoordinate = Coordinate(latitude: 16.0, longitude: 106.0)
        }
        
        // Create base region using the simple initializer
        var region = TripRegion(
            id: UUID().uuidString,
            name: destination.name,
            country: "Vietnam",
            arrivalDate: Date(), // Will be set during schedule generation
            departureDate: Date().addingTimeInterval(86400) // +1 day
        )
        
        // Set additional properties after initialization
        region.coordinates = regionCoordinate
        region.localCurrency = "VND"  // Vietnam Dong
        region.timezone = "Asia/Ho_Chi_Minh"
        region.regionType = destination.province != nil ? .province : .city
        
        // Convert POIs
        var pois: [PointOfInterest] = []
        for poiItem in destination.pois {
            if let poi = await convertSearchItemToPOI(poiItem) {
                pois.append(poi)
            }
        }
        
        region.pointsOfInterest = pois
        
        print("      - Created region with \(pois.count) POIs")
        
        return region
    }
    
    private func createRegionForUngroupedPOIs(_ pois: [SearchResultItem]) async throws -> TripRegion {
        print("   Creating region for \(pois.count) ungrouped POIs")
        
        // Use average coordinates of all POIs
        let coordinates = pois.compactMap { $0.coordinate }
        let avgLat = coordinates.isEmpty ? 16.0 : coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let avgLng = coordinates.isEmpty ? 106.0 : coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        
        var region = TripRegion(
            id: UUID().uuidString,
            name: "Other Locations",
            country: "Vietnam",
            arrivalDate: Date(),
            departureDate: Date().addingTimeInterval(86400)
        )
        
        // Set additional properties
        region.coordinates = Coordinate(latitude: avgLat, longitude: avgLng)
        region.localCurrency = "VND"
        region.timezone = "Asia/Ho_Chi_Minh"
        region.regionType = .neighborhood  // Use neighborhood for ungrouped POIs
        
        var convertedPOIs: [PointOfInterest] = []
        for poiItem in pois {
            if let poi = await convertSearchItemToPOI(poiItem) {
                convertedPOIs.append(poi)
            }
        }
        
        region.pointsOfInterest = convertedPOIs
        
        return region
    }
    
    private func convertSearchItemToPOI(_ item: SearchResultItem) async -> PointOfInterest? {
        guard let coordinate = item.coordinate else {
            print("      ⚠️ Skipping POI \(item.name) - no coordinates")
            return nil
        }
        
        let poiCoordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Use the initializer and set additional fields
        var poi = PointOfInterest(
            id: item.id,
            name: item.name,
            category: determinePOICategory(from: item),
            coordinates: poiCoordinate
        )
        
        // Set the address from search result
        poi.address = item.address
        
        return poi
    }
    
    private func determinePOICategory(from item: SearchResultItem) -> POICategory {
        // Simple categorization based on item type
        switch item.type {
        case .poi:
            return .attraction
        case .custom:
            return .other
        }
    }
    
    private func generateDailySchedules(for trip: Trip) -> [DailySchedule] {
        var schedules: [DailySchedule] = []
        
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: trip.startDate)
        let endDate = calendar.startOfDay(for: trip.endDate)
        
        // Use first region ID as default, or empty string if no regions
        let defaultRegionId = trip.regions.first?.id ?? ""
        
        while currentDate <= endDate {
            let schedule = DailySchedule(
                id: UUID().uuidString,
                date: currentDate,
                regionId: defaultRegionId  // Required parameter
            )
            
            schedules.append(schedule)
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            
            currentDate = nextDate
        }
        
        return schedules
    }
    
    // MARK: - Navigation
    
    private func completeTripCreation(_ trip: Trip) {
        print("🎉 Completing trip creation: \(trip.title)")
        
        // Navigate back through the navigation stack to AddTripViewController
        guard let navController = navigationController else {
            print("❌ No navigation controller found")
            return
        }
        
        // Find AddTripViewController in the stack
        guard let addTripVC = navController.viewControllers.first(where: { $0 is AddTripViewController }) as? AddTripViewController else {
            print("❌ AddTripViewController not found in navigation stack")
            return
        }
        
        // Dismiss the entire modal navigation controller
        navController.dismiss(animated: true) {
            // Call delegate to save the trip
            addTripVC.delegate?.didAddTrip(trip)
            print("✅ Trip creation completed and delegate called")
        }
    }
    
    // MARK: - Loading State
    
    private func showLoadingIndicator() {
        isLoading = true
        loadingIndicator.startAnimating()
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
        tableView.isUserInteractionEnabled = false
    }
    
    private func hideLoadingIndicator() {
        isLoading = false
        loadingIndicator.stopAnimating()
        saveButton.isEnabled = true
        saveButton.alpha = 1.0
        tableView.isUserInteractionEnabled = true
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension TripOrganizationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return destinations.count + (ungroupedPOIs.isEmpty ? 0 : 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < destinations.count {
            return destinations[section].pois.count
        } else {
            return ungroupedPOIs.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < destinations.count {
            let dest = destinations[section]
            let poiCount = dest.pois.count
            return "\(dest.name) (\(poiCount) POI\(poiCount == 1 ? "" : "s"))"
        } else {
            return "Ungrouped POIs"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath) as! POICell
        
        let poi: SearchResultItem
        if indexPath.section < destinations.count {
            poi = destinations[indexPath.section].pois[indexPath.row]
        } else {
            poi = ungroupedPOIs[indexPath.row]
        }
        
        cell.configure(with: poi)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == destinations.count - 1 && !ungroupedPOIs.isEmpty {
            return "Note: Ungrouped POIs couldn't be matched to a specific destination."
        }
        return nil
    }
}

// MARK: - Custom Cells

class DestinationHeaderCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemBlue.withAlphaComponent(0.1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class POICell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: SearchResultItem) {
        var config = defaultContentConfiguration()
        config.text = item.name
        config.secondaryText = item.address
        config.image = UIImage(systemName: item.type.icon)
        config.imageProperties.tintColor = item.type.color
        contentConfiguration = config
    }
}
