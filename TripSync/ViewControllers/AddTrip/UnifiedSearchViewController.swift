//
//  UnifiedSearchViewController.swift
//  TripSync
//
//  Smart search: Find cities (destinations) or POIs first, then organize
//

import UIKit
import CoreLocation
import MapKit

class UnifiedSearchViewController: UIViewController {
    
    // MARK: - Properties
    
    private let tripBuilder: TripBuilder
    private var searchResults: [SearchResultItem] = []
    private var selectedItems: [SearchResultItem] = []
    private var searchWorkItem: DispatchWorkItem?
    
    // Group selected POIs by date
    private var poisByDate: [Date: [SearchResultItem]] = [:]
    private var sortedDates: [Date] = []
    private var unscheduledPOIs: [SearchResultItem] = [] // POIs without assigned date/time
    
    private let googlePlacesService = GooglePlacesService.shared
    private let osmService = OpenStreetMapService.shared
    
    // MARK: - UI Components
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search places to visit..."
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = false
        // Default to Vietnam region
        let vietnamRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 16.0, longitude: 106.0),
            span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 10.0)
        )
        map.setRegion(vietnamRegion, animated: false)
        return map
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        table.register(SelectedItemCell.self, forCellReuseIdentifier: "SelectedItemCell")
        return table
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let manualEntryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add Custom Place", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        return button
    }()
    
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
        
        print("🌐 [UNIFIED SEARCH] ====== VIEW LOADED ======")
        print("📅 [UNIFIED SEARCH] Trip: \(tripBuilder.startDate) to \(tripBuilder.endDate)")
        print("🏠 [UNIFIED SEARCH] Home Country: \(tripBuilder.homeCountry ?? "Not set")")
        print("💰 [UNIFIED SEARCH] Base Currency: \(tripBuilder.baseCurrency ?? "Not set")")
        print("============================================")
        
        title = "Add Places to Visit"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupActions()
        setupMapView()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        [searchBar, mapView, tableView, manualEntryButton, continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Map view takes 40% of available height (no segmented control gap)
            mapView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.35),
            
            tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: manualEntryButton.topAnchor, constant: -8),
            
            manualEntryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            manualEntryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            manualEntryButton.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -8),
            manualEntryButton.heightAnchor.constraint(equalToConstant: 44),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
    }
    
    private func setupActions() {
        manualEntryButton.addTarget(self, action: #selector(manualEntryTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func manualEntryTapped() {
        // Show coordinate picker for custom location
        let picker = CoordinatePickerViewController()
        picker.delegate = self
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }
    
    @objc private func continueTapped() {
        print("➡️ [UNIFIED SEARCH] Continue button tapped")
        print("   Selected items: \(selectedItems.count)")
        print("   Search results: \(searchResults.count)")
        
        // Organize selected items into destinations and POIs
        organizeAndContinue()
    }
    
    // MARK: - Search
    
    private func performSearch(query: String) {
        searchWorkItem?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            Task {
                await self?.executeSearch(query: query)
            }
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func executeSearch(query: String) async {
        // Search using Google Places - accept all results, filter client-side
        // Type filtering in autocomplete API is just a hint and often returns admin areas anyway
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            googlePlacesService.autocomplete(
                query: query,
                types: [], // Empty array = all types (let client-side filtering handle it)
                country: "vn"
            ) { [weak self] result in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                switch result {
                case .success(let places):
                    // Convert to SearchResultItem
                    Task {
                        let items = await self.convertPlacesToSearchResults(places)
                        
                        await MainActor.run {
                            self.searchResults = items
                            self.tableView.reloadData()
                            self.updateMapWithResults()
                            continuation.resume()
                        }
                    }
                    
                case .failure(let error):
                    Task {
                        await MainActor.run {
                            self.showError("Search failed: \(error.localizedDescription)")
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Map Updates
    
    private func updateMapWithResults() {
        // Remove existing annotations except selected items
        let annotationsToRemove = mapView.annotations.filter { annotation in
            guard let searchAnnotation = annotation as? SearchResultAnnotation else {
                return false
            }
            return !selectedItems.contains(where: { $0.id == searchAnnotation.item.id })
        }
        mapView.removeAnnotations(annotationsToRemove)
        
        // Add annotations for search results that have coordinates
        var newAnnotations: [SearchResultAnnotation] = []
        
        for item in searchResults {
            // Only add if not already selected
            if selectedItems.contains(where: { $0.id == item.id }) {
                continue
            }
            
            if let coordinate = item.coordinate {
                let annotation = SearchResultAnnotation(item: item, coordinate: coordinate)
                newAnnotations.append(annotation)
            }
        }
        
        mapView.addAnnotations(newAnnotations)
        
        // Adjust map to show all annotations if there are any
        if !mapView.annotations.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
    }
    
    private func updateMapWithSelectedItems() {
        // Remove all annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add selected items as annotations
        var annotations: [SearchResultAnnotation] = []
        
        for item in selectedItems {
            if let coordinate = item.coordinate {
                let annotation = SearchResultAnnotation(item: item, coordinate: coordinate, isSelected: true)
                annotations.append(annotation)
            }
        }
        
        // Add search results (if showing search)
        if !searchResults.isEmpty {
            for item in searchResults {
                if !selectedItems.contains(where: { $0.id == item.id }),
                   let coordinate = item.coordinate {
                    let annotation = SearchResultAnnotation(item: item, coordinate: coordinate)
                    annotations.append(annotation)
                }
            }
        }
        
        mapView.addAnnotations(annotations)
        
        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    private func convertPlacesToSearchResults(_ places: [GooglePlaceResult]) async -> [SearchResultItem] {
        print("📋 [UNIFIED SEARCH] Processing \(places.count) autocomplete results...")
        print("� [UNIFIED SEARCH] Fetching coordinates from Place Details API...")
        
        // Use DispatchGroup to fetch all place details in parallel
        return await withCheckedContinuation { continuation in
            let group = DispatchGroup()
            var resultsWithCoordinates: [GooglePlaceResult] = []
            
            for place in places {
                group.enter()
                
                // Fetch place details to get coordinates
                googlePlacesService.placeDetails(placeId: place.placeId) { result in
                    defer { group.leave() }
                    
                    switch result {
                    case .success(let detailedPlace):
                        // Check if coordinates are valid
                        if detailedPlace.coordinates.latitude != 0 || detailedPlace.coordinates.longitude != 0 {
                            print("✅ [UNIFIED SEARCH] Got coordinates for '\(detailedPlace.name)': \(detailedPlace.coordinates.latitude), \(detailedPlace.coordinates.longitude)")
                            resultsWithCoordinates.append(detailedPlace)
                        } else {
                            print("⚠️ [UNIFIED SEARCH] Place '\(place.name)' has no coordinates")
                        }
                    case .failure(let error):
                        print("❌ [UNIFIED SEARCH] Failed to get details for '\(place.name)': \(error)")
                    }
                }
            }
            
            // Wait for all details requests to complete
            group.notify(queue: .main) {
                print("📊 [UNIFIED SEARCH] Got coordinates for \(resultsWithCoordinates.count)/\(places.count) places")
                
                // Convert to SearchResultItem
                var items: [SearchResultItem] = []
                
                for detailedPlace in resultsWithCoordinates {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: detailedPlace.coordinates.latitude,
                        longitude: detailedPlace.coordinates.longitude
                    )
                    
                    let modelCoordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let matchedProvince = Vietnam2025.findProvince(near: modelCoordinate)
                    
                    let item = SearchResultItem(
                        id: detailedPlace.placeId,
                        name: detailedPlace.name,
                        address: detailedPlace.formattedAddress,
                        type: .poi,
                        placeId: detailedPlace.placeId,
                        matchedProvince: matchedProvince,
                        coordinate: coordinate,
                        detailedInfo: detailedPlace,
                        assignedDate: nil,
                        assignedTime: nil
                    )
                    
                    items.append(item)
                    print("✅ [UNIFIED SEARCH] Created item '\(item.name)' in \(matchedProvince?.name ?? "Unknown")")
                }
                
                print("🎯 [UNIFIED SEARCH] Final results: \(items.count) POIs with valid coordinates")
                continuation.resume(returning: items)
            }
        }
    }
    
    private func getSearchTypes() -> [String] {
        // Removed - no longer using segmented control
        return []
    }
    
    // MARK: - Organization
    
    private func organizeAndContinue() {
        print("🗂️ [UNIFIED SEARCH] ====== ORGANIZING POIs ======")
        print("   Total selected items: \(selectedItems.count)")
        
        // NEW FLOW: Group POIs by province, create TripRegions automatically
        // Each region gets POIs assigned to it based on province matching
        
        var regionsByProvince: [String: [SearchResultItem]] = [:]
        var ungroupedPOIs: [SearchResultItem] = []
        
        // Group POIs by province
        for item in selectedItems {
            if let province = item.matchedProvince {
                let provinceName = province.name
                if regionsByProvince[provinceName] == nil {
                    regionsByProvince[provinceName] = []
                }
                regionsByProvince[provinceName]?.append(item)
                print("   ✅ '\(item.name)' → \(provinceName)")
            } else {
                ungroupedPOIs.append(item)
                print("   ⚠️ '\(item.name)' → No province match")
            }
        }
        
        // Convert to OrganizedDestination format
        var destinations: [OrganizedDestination] = []
        
        for (provinceName, pois) in regionsByProvince {
            // Find the province data
            if let province = pois.first?.matchedProvince {
                destinations.append(OrganizedDestination(
                    name: provinceName,
                    province: province,
                    pois: pois
                ))
            }
        }
        
        print("📊 [UNIFIED SEARCH] Created \(destinations.count) regions from \(selectedItems.count) POIs")
        print("   └─ Ungrouped: \(ungroupedPOIs.count)")
        print("   └─ Navigating to TripOrganizationViewController...")
        print("=============================================")
        
        // Show organization preview (or skip to trip creation)
        showOrganizationPreview(destinations: destinations, ungroupedPOIs: ungroupedPOIs)
    }
    
    private func showOrganizationPreview(destinations: [OrganizedDestination], ungroupedPOIs: [SearchResultItem]) {
        let previewVC = TripOrganizationViewController(
            tripBuilder: tripBuilder,
            destinations: destinations,
            ungroupedPOIs: ungroupedPOIs
        )
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    // MARK: - Helpers
    
    private func zoomToItem(_ item: SearchResultItem) {
        guard let coordinate = item.coordinate else {
            print("⚠️ [MAP] Cannot zoom to item without coordinates: \(item.name)")
            return
        }
        
        // Determine zoom level based on item type
        let span: MKCoordinateSpan
        switch item.type {
        case .poi:
            // Closer view for POIs (show ~5km radius)
            span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        case .custom:
            // Medium view for custom locations
            span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        }
        
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        print("🗺️ [MAP] Zoomed to POI: \(item.name)")
    }
    
    private func updateContinueButton() {
        continueButton.isEnabled = !selectedItems.isEmpty
        continueButton.alpha = selectedItems.isEmpty ? 0.5 : 1.0
        
        let count = selectedItems.count
        continueButton.setTitle("Continue with \(count) Item\(count == 1 ? "" : "s")", for: .normal)
    }
    
    // MARK: - Date Picker & POI Assignment
    
    private func showDatePickerForPOI(_ item: SearchResultItem) {
        let modal = DatePickerModalViewController(
            poiName: item.name,
            poiAddress: item.address,
            tripStartDate: tripBuilder.startDate,
            tripEndDate: tripBuilder.endDate
        )
        modal.delegate = self
        
        // Store the item temporarily for the callback
        objc_setAssociatedObject(modal, "selectedPOI", item, .OBJC_ASSOCIATION_RETAIN)
        
        present(modal, animated: true)
    }
    
    private func showEditOptionsForPOI(_ item: SearchResultItem) {
        let alert = UIAlertController(title: item.name, message: "What would you like to do?", preferredStyle: .actionSheet)
        
        // If scheduled, allow changing date/time
        if item.assignedDate != nil {
            alert.addAction(UIAlertAction(title: "Change Date/Time", style: .default) { [weak self] _ in
                self?.showDatePickerForPOI(item)
            })
            
            alert.addAction(UIAlertAction(title: "Remove Schedule (Keep Unscheduled)", style: .default) { [weak self] _ in
                self?.addUnscheduledPOI(item)
            })
        } else {
            // If unscheduled, allow scheduling
            alert.addAction(UIAlertAction(title: "Schedule Visit", style: .default) { [weak self] _ in
                self?.showDatePickerForPOI(item)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Remove from Trip", style: .destructive) { [weak self] _ in
            self?.removePOI(item)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func assignPOIToDate(_ item: SearchResultItem, date: Date, time: Date) {
        // Remove from unscheduled if it was there
        unscheduledPOIs.removeAll(where: { $0.id == item.id })
        
        // Remove if already assigned (in case re-assigning)
        selectedItems.removeAll(where: { $0.id == item.id })
        
        // Create updated item with date/time
        var updatedItem = item
        updatedItem.assignedDate = date
        updatedItem.assignedTime = time
        
        // Add to selected items
        selectedItems.append(updatedItem)
        
        // Refresh date grouping
        refreshDateGrouping()
        
        // Update UI
        tableView.reloadData()
        updateContinueButton()
        updateMapWithSelectedItems()
        
        // Zoom to POI
        zoomToItem(updatedItem)
        
        print("✅ [POI] Scheduled '\(item.name)' for \(formatDate(date)) at \(formatTime(time))")
    }
    
    private func addUnscheduledPOI(_ item: SearchResultItem) {
        // Remove from scheduled if it was there
        selectedItems.removeAll(where: { $0.id == item.id })
        refreshDateGrouping()
        
        // Create item without date/time
        var unscheduledItem = item
        unscheduledItem.assignedDate = nil
        unscheduledItem.assignedTime = nil
        
        // Add to unscheduled list
        if !unscheduledPOIs.contains(where: { $0.id == item.id }) {
            unscheduledPOIs.append(unscheduledItem)
            selectedItems.append(unscheduledItem)
        }
        
        // Update UI
        tableView.reloadData()
        updateContinueButton()
        updateMapWithSelectedItems()
        
        // Zoom to POI
        zoomToItem(unscheduledItem)
        
        print("✅ [POI] Added '\(item.name)' to unscheduled list")
    }
    
    private func removePOI(_ item: SearchResultItem) {
        selectedItems.removeAll(where: { $0.id == item.id })
        unscheduledPOIs.removeAll(where: { $0.id == item.id })
        
        // Refresh date grouping
        refreshDateGrouping()
        
        tableView.reloadData()
        updateContinueButton()
        updateMapWithSelectedItems()
    }
    
    private func refreshDateGrouping() {
        // Clear existing grouping
        poisByDate.removeAll()
        unscheduledPOIs.removeAll()
        
        // Group by date or unscheduled
        let calendar = Calendar.current
        for item in selectedItems {
            if let assignedDate = item.assignedDate {
                // Normalize to start of day
                let dayStart = calendar.startOfDay(for: assignedDate)
                
                if poisByDate[dayStart] == nil {
                    poisByDate[dayStart] = []
                }
                poisByDate[dayStart]?.append(item)
            } else {
                // No date assigned - goes to unscheduled
                unscheduledPOIs.append(item)
            }
        }
        
        // Sort dates
        sortedDates = poisByDate.keys.sorted()
        
        // Sort POIs within each date by time
        for date in sortedDates {
            poisByDate[date]?.sort { first, second in
                guard let time1 = first.assignedTime, let time2 = second.assignedTime else {
                    return false
                }
                let calendar = Calendar.current
                let hour1 = calendar.component(.hour, from: time1)
                let minute1 = calendar.component(.minute, from: time1)
                let hour2 = calendar.component(.hour, from: time2)
                let minute2 = calendar.component(.minute, from: time2)
                
                if hour1 != hour2 {
                    return hour1 < hour2
                } else {
                    return minute1 < minute2
                }
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - DatePickerModalDelegate

extension UnifiedSearchViewController: DatePickerModalDelegate {
    func datePickerDidConfirm(_ controller: DatePickerModalViewController, date: Date, time: Date) {
        // Retrieve the associated POI
        if let item = objc_getAssociatedObject(controller, "selectedPOI") as? SearchResultItem {
            assignPOIToDate(item, date: date, time: time)
        }
    }
    
    func datePickerDidSkip(_ controller: DatePickerModalViewController) {
        // Add POI without scheduling
        if let item = objc_getAssociatedObject(controller, "selectedPOI") as? SearchResultItem {
            addUnscheduledPOI(item)
        }
    }
    
    func datePickerDidCancel(_ controller: DatePickerModalViewController) {
        // Nothing to do
    }
}

// MARK: - UISearchBarDelegate

extension UnifiedSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension UnifiedSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section 0-N: Selected POIs grouped by date
        // Section N+1: Unscheduled POIs (if any)
        // Last section: Search results
        let scheduledSections = sortedDates.count
        let unscheduledSection = unscheduledPOIs.isEmpty ? 0 : 1
        return scheduledSections + unscheduledSection + 1 // +1 for search results
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        let searchIndex = unscheduledPOIs.isEmpty ? scheduledSections : scheduledSections + 1
        
        if section < scheduledSections {
            // Scheduled POIs grouped by date
            let date = sortedDates[section]
            return poisByDate[date]?.count ?? 0
        } else if section == unscheduledIndex && !unscheduledPOIs.isEmpty {
            // Unscheduled POIs
            return unscheduledPOIs.count
        } else {
            // Search results
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        let searchIndex = unscheduledPOIs.isEmpty ? scheduledSections : scheduledSections + 1
        
        if section < scheduledSections {
            // Scheduled POIs grouped by date
            let date = sortedDates[section]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dayNumber = Calendar.current.dateComponents([.day], from: tripBuilder.startDate, to: date).day! + 1
            let count = poisByDate[date]?.count ?? 0
            return "📅 \(dateFormatter.string(from: date)) (Day \(dayNumber)) - \(count) place\(count == 1 ? "" : "s")"
        } else if section == unscheduledIndex && !unscheduledPOIs.isEmpty {
            // Unscheduled section
            return "📍 Unscheduled (\(unscheduledPOIs.count))"
        } else {
            // Search results
            return searchResults.isEmpty ? nil : "Search Results"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        let searchIndex = unscheduledPOIs.isEmpty ? scheduledSections : scheduledSections + 1
        
        if indexPath.section < scheduledSections {
            // Scheduled POI cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedItemCell", for: indexPath) as! SelectedItemCell
            let date = sortedDates[indexPath.section]
            if let pois = poisByDate[date], indexPath.row < pois.count {
                cell.configure(with: pois[indexPath.row])
            }
            return cell
        } else if indexPath.section == unscheduledIndex && !unscheduledPOIs.isEmpty {
            // Unscheduled POI cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedItemCell", for: indexPath) as! SelectedItemCell
            cell.configure(with: unscheduledPOIs[indexPath.row])
            return cell
        } else {
            // Search result cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
            let item = searchResults[indexPath.row]
            let isSelected = selectedItems.contains(where: { $0.id == item.id })
            cell.configure(with: item, isSelected: isSelected)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        let searchIndex = unscheduledPOIs.isEmpty ? scheduledSections : scheduledSections + 1
        
        print("👆 [UNIFIED SEARCH] User tapped row at section \(indexPath.section), row \(indexPath.row)")
        print("   Scheduled sections: \(scheduledSections)")
        print("   Unscheduled index: \(unscheduledIndex)")
        print("   Search index: \(searchIndex)")
        
        if indexPath.section < scheduledSections {
            // Tapped scheduled POI - show edit options
            let date = sortedDates[indexPath.section]
            if let pois = poisByDate[date], indexPath.row < pois.count {
                let poi = pois[indexPath.row]
                print("📝 [UNIFIED SEARCH] Tapped scheduled POI: \(poi.name)")
                showEditOptionsForPOI(poi)
            }
        } else if indexPath.section == unscheduledIndex && !unscheduledPOIs.isEmpty {
            // Tapped unscheduled POI - show edit options
            let poi = unscheduledPOIs[indexPath.row]
            print("📝 [UNIFIED SEARCH] Tapped unscheduled POI: \(poi.name)")
            showEditOptionsForPOI(poi)
        } else if indexPath.section == searchIndex {
            // Tapped search result - show date picker modal
            let item = searchResults[indexPath.row]
            print("🔍 [UNIFIED SEARCH] Tapped search result: \(item.name)")
            print("   Province: \(item.matchedProvince?.name ?? "Unknown")")
            print("   Coordinates: \(item.coordinate?.latitude ?? 0), \(item.coordinate?.longitude ?? 0)")
            showDatePickerForPOI(item)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        
        // Can delete scheduled or unscheduled POIs (not search results)
        return indexPath.section <= unscheduledIndex
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        
        let scheduledSections = sortedDates.count
        let unscheduledIndex = scheduledSections
        
        if indexPath.section < scheduledSections {
            // Delete from scheduled
            let date = sortedDates[indexPath.section]
            if let pois = poisByDate[date], indexPath.row < pois.count {
                let removedPOI = pois[indexPath.row]
                removePOI(removedPOI)
            }
        } else if indexPath.section == unscheduledIndex && !unscheduledPOIs.isEmpty {
            // Delete from unscheduled
            let removedPOI = unscheduledPOIs[indexPath.row]
            removePOI(removedPOI)
        }
    }
}

// MARK: - MKMapViewDelegate

extension UnifiedSearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let searchAnnotation = annotation as? SearchResultAnnotation else {
            return nil
        }
        
        let identifier = "SearchResultPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // Add info button to callout
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = infoButton
        } else {
            annotationView?.annotation = annotation
        }
        
        // Customize based on item type, selection, and schedule status
        let item = searchAnnotation.item
        
        if searchAnnotation.isSelected {
            // Selected POI - check if scheduled or not
            if item.assignedDate != nil {
                // Scheduled POI - solid green
                annotationView?.markerTintColor = .systemGreen
                annotationView?.glyphImage = UIImage(systemName: "calendar.circle.fill")
            } else {
                // Unscheduled POI - orange
                annotationView?.markerTintColor = .systemOrange
                annotationView?.glyphImage = UIImage(systemName: "clock.fill")
            }
        } else {
            // Search result - default color
            annotationView?.markerTintColor = .systemBlue
            annotationView?.glyphImage = UIImage(systemName: "star.fill")
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let searchAnnotation = view.annotation as? SearchResultAnnotation else {
            return
        }
        
        let item = searchAnnotation.item
        
        // Toggle selection
        if let existingIndex = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: existingIndex)
        } else {
            selectedItems.append(item)
        }
        
        tableView.reloadData()
        updateContinueButton()
        updateMapWithSelectedItems()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Zoom to annotation when tapped
        guard let searchAnnotation = view.annotation as? SearchResultAnnotation else {
            return
        }
        
        zoomToItem(searchAnnotation.item)
    }
}

// MARK: - CoordinatePickerDelegate

extension UnifiedSearchViewController: CoordinatePickerDelegate {
    func coordinatePickerDidSelectLocation(
        _ picker: CoordinatePickerViewController,
        coordinate: CLLocationCoordinate2D,
        name: String,
        address: String
    ) {
        // Add custom location to selected items
        let modelCoordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let province = Vietnam2025.findProvince(near: modelCoordinate)
        
        let customItem = SearchResultItem(
            id: UUID().uuidString,
            name: name,
            address: address,
            type: .custom,
            placeId: nil,
            matchedProvince: province,
            coordinate: coordinate
        )
        
        selectedItems.append(customItem)
        tableView.reloadData()
        updateContinueButton()
        updateMapWithSelectedItems()
    }
}

// MARK: - Models

struct SearchResultItem {
    let id: String
    let name: String
    let address: String
    let type: ItemType
    let placeId: String?
    let matchedProvince: ProvinceInfo?
    var coordinate: CLLocationCoordinate2D?
    var detailedInfo: GooglePlaceResult? // Full details from API
    var assignedDate: Date? // Date when POI will be visited
    var assignedTime: Date? // Specific time for visit
    
    enum ItemType {
        case poi        // Points of Interest only
        case custom     // Manual entries
        
        var icon: String {
            switch self {
            case .poi: return "star.circle.fill"
            case .custom: return "location.circle.fill"
            }
        }
        
        var color: UIColor {
            switch self {
            case .poi: return .systemOrange
            case .custom: return .systemPurple
            }
        }
    }
}

struct POIWithDate {
    let item: SearchResultItem
    let date: Date
    let time: Date
}

struct OrganizedDestination {
    let name: String
    let province: ProvinceInfo?
    var pois: [SearchResultItem]
}

// MARK: - Map Annotation

class SearchResultAnnotation: NSObject, MKAnnotation {
    let item: SearchResultItem
    let coordinate: CLLocationCoordinate2D
    let isSelected: Bool
    
    var title: String? {
        return item.name
    }
    
    var subtitle: String? {
        return item.matchedProvince?.name ?? item.address
    }
    
    init(item: SearchResultItem, coordinate: CLLocationCoordinate2D, isSelected: Bool = false) {
        self.item = item
        self.coordinate = coordinate
        self.isSelected = isSelected
        super.init()
    }
}

// MARK: - Custom Cells

class SearchResultCell: UITableViewCell {
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let provinceBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(provinceBadge)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            provinceBadge.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),
            provinceBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            provinceBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            provinceBadge.heightAnchor.constraint(equalToConstant: 20),
            provinceBadge.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: SearchResultItem, isSelected: Bool) {
        iconView.image = UIImage(systemName: item.type.icon)
        iconView.tintColor = item.type.color
        
        titleLabel.text = item.name
        subtitleLabel.text = item.address
        
        if let province = item.matchedProvince {
            provinceBadge.isHidden = false
            provinceBadge.text = " \(province.name) "
        } else {
            provinceBadge.isHidden = true
        }
        
        accessoryType = isSelected ? .checkmark : .none
    }
}

class SelectedItemCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: SearchResultItem) {
        var config = defaultContentConfiguration()
        config.text = item.name
        config.secondaryText = item.matchedProvince?.name ?? item.address
        config.image = UIImage(systemName: item.type.icon)
        config.imageProperties.tintColor = item.type.color
        contentConfiguration = config
    }
}
