//
//  POISearchMapViewController.swift
//  TripSync
//
//  POI search with map view showing existing POIs (blue pins) and search results (green pins)
//

import UIKit
import MapKit

protocol POISearchMapDelegate: AnyObject {
    func didSelectPOI(_ poi: PointOfInterest, forDate date: Date)
}

class POISearchMapViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: POISearchMapDelegate?
    private let tripBuilder: TripBuilder
    private let selectedDate: Date
    private var existingPOIs: [PointOfInterest] = []
    private var searchResults: [PointOfInterest] = []
    private var existingAnnotations: Set<POIAnnotation> = []  // Track existing POI annotations
    
    private let googlePlacesService = GooglePlacesService()
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    
    // Map view (40% of screen)
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = false
        map.mapType = .standard
        return map
    }()
    
    // Search bar
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for places..."
        bar.searchBarStyle = .minimal
        return bar
    }()
    
    // Results table (60% of screen)
    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .systemBackground
        table.separatorStyle = .singleLine
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.register(POISearchResultCell.self, forCellReuseIdentifier: "POICell")
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Search for places to add to your trip"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Init
    
    init(tripBuilder: TripBuilder, selectedDate: Date) {
        self.tripBuilder = tripBuilder
        self.selectedDate = selectedDate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Place"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupUI()
        loadExistingPOIs()
        setupInitialMapRegion()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        mapView.delegate = self
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(mapView)
        containerView.addSubview(searchBar)
        containerView.addSubview(tableView)
        containerView.addSubview(emptyStateLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Map view - 40% of container height
            mapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.4),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: mapView.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Table view - remaining 60%
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Empty state
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadExistingPOIs() {
        // Get POIs from the selected day's timeline
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        if let timeline = tripBuilder.timelines[normalizedDate] {
            existingPOIs = timeline.blocks.map { $0.poi }
        }
        
        // Add blue pins for existing POIs
        updateMapAnnotations()
    }
    
    private func setupInitialMapRegion() {
        if !existingPOIs.isEmpty {
            // Zoom to region containing existing POIs
            zoomToExistingPOIs()
        } else {
            // Default to Vietnam (since that's the target market)
            let vietnamRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 16.0, longitude: 106.0),
                span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
            )
            mapView.setRegion(vietnamRegion, animated: false)
        }
    }
    
    private func zoomToExistingPOIs() {
        guard !existingPOIs.isEmpty else { return }
        
        var minLat = existingPOIs[0].coordinates.latitude
        var maxLat = existingPOIs[0].coordinates.latitude
        var minLon = existingPOIs[0].coordinates.longitude
        var maxLon = existingPOIs[0].coordinates.longitude
        
        for poi in existingPOIs {
            minLat = min(minLat, poi.coordinates.latitude)
            maxLat = max(maxLat, poi.coordinates.latitude)
            minLon = min(minLon, poi.coordinates.longitude)
            maxLon = max(maxLon, poi.coordinates.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,  // Add 50% padding
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    private func updateMapAnnotations() {
        // Remove all annotations
        mapView.removeAnnotations(mapView.annotations)
        existingAnnotations.removeAll()
        
        // Add blue pins for existing POIs
        for poi in existingPOIs {
            let coord = CLLocationCoordinate2D(
                latitude: poi.coordinates.latitude,
                longitude: poi.coordinates.longitude
            )
            let annotation = POIAnnotation(poi: poi, coordinate: coord)
            existingAnnotations.insert(annotation)
            mapView.addAnnotation(annotation)
        }
        
        // Add green pins for search results
        for poi in searchResults {
            let coord = CLLocationCoordinate2D(
                latitude: poi.coordinates.latitude,
                longitude: poi.coordinates.longitude
            )
            let annotation = POIAnnotation(poi: poi, coordinate: coord)
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            tableView.reloadData()
            updateMapAnnotations()
            emptyStateLabel.isHidden = false
            return
        }
        
        print("🔍 [POI SEARCH] Starting search for: '\(query)'")
        emptyStateLabel.text = "Searching..."
        emptyStateLabel.isHidden = false
        
        // Get center coordinate for search (use map center or existing POIs)
        let searchCenter: CLLocationCoordinate2D
        if !existingPOIs.isEmpty {
            let avgLat = existingPOIs.map { $0.coordinates.latitude }.reduce(0, +) / Double(existingPOIs.count)
            let avgLon = existingPOIs.map { $0.coordinates.longitude }.reduce(0, +) / Double(existingPOIs.count)
            searchCenter = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
            print("🗺️ [POI SEARCH] Using existing POIs center: \(avgLat), \(avgLon)")
        } else {
            searchCenter = mapView.region.center
            print("🗺️ [POI SEARCH] Using map center: \(searchCenter.latitude), \(searchCenter.longitude)")
        }
        
        googlePlacesService.autocomplete(
            query: query
        ) { [weak self] result in
            DispatchQueue.main.async {
                print("📥 [POI SEARCH] Received autocomplete result")
                switch result {
                case .success(let places):
                    print("✅ [POI SEARCH] Found \(places.count) places from API")
                    self?.handleSearchResults(places)
                case .failure(let error):
                    print("❌ [POI SEARCH] Search error: \(error)")
                    self?.emptyStateLabel.text = "Search failed. Please try again."
                }
            }
        }
    }
    
    private func handleSearchResults(_ places: [GooglePlaceResult]) {
        print("🔄 [POI SEARCH] Processing \(places.count) autocomplete results...")
        print("📍 [POI SEARCH] Fetching coordinates from Place Details API...")
        
        // Autocomplete doesn't return coordinates - need to fetch details for each place
        let group = DispatchGroup()
        var resultsWithCoordinates: [GooglePlaceResult] = []
        
        for place in places {
            group.enter()
            
            // Fetch place details to get coordinates
            GooglePlacesService.shared.placeDetails(placeId: place.placeId) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let detailedPlace):
                    // Check if coordinates are valid
                    if detailedPlace.coordinates.latitude != 0 || detailedPlace.coordinates.longitude != 0 {
                        print("✅ [POI SEARCH] Got coordinates for '\(detailedPlace.name)': \(detailedPlace.coordinates.latitude), \(detailedPlace.coordinates.longitude)")
                        resultsWithCoordinates.append(detailedPlace)
                    } else {
                        print("⚠️ [POI SEARCH] Place '\(place.name)' has no coordinates")
                    }
                case .failure(let error):
                    print("❌ [POI SEARCH] Failed to get details for '\(place.name)': \(error)")
                }
            }
        }
        
        // Wait for all details requests to complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            print("📊 [POI SEARCH] Got coordinates for \(resultsWithCoordinates.count)/\(places.count) places")
            
            // Convert GooglePlaceResult to PointOfInterest
            self.searchResults = resultsWithCoordinates.map { place in
                var poi = PointOfInterest(
                    name: place.name,
                    category: POICategory.from(googleTypes: place.types),
                    coordinates: place.coordinates
                )
                poi.address = place.formattedAddress
                
                print("✅ [POI SEARCH] Created POI '\(poi.name)' at \(poi.coordinates.latitude), \(poi.coordinates.longitude)")
                return poi
            }
            
            print("📊 [POI SEARCH] Final results: \(self.searchResults.count) POIs")
            
            self.emptyStateLabel.isHidden = !self.searchResults.isEmpty
            if self.searchResults.isEmpty {
                self.emptyStateLabel.text = "No results found"
                print("⚠️ [POI SEARCH] No valid POIs after coordinate fetch")
            } else {
                print("🎯 [POI SEARCH] Reloading table with \(self.searchResults.count) results")
            }
            
            self.tableView.reloadData()
            self.updateMapAnnotations()
            
            // Zoom to show search results if available
            if !self.searchResults.isEmpty {
                print("🗺️ [POI SEARCH] Zooming to show results")
                self.zoomToAllPOIs()
            }
        }
    }
    
    private func zoomToAllPOIs() {
        let allPOIs = existingPOIs + searchResults
        guard !allPOIs.isEmpty else { return }
        
        var minLat = allPOIs[0].coordinates.latitude
        var maxLat = allPOIs[0].coordinates.latitude
        var minLon = allPOIs[0].coordinates.longitude
        var maxLon = allPOIs[0].coordinates.longitude
        
        for poi in allPOIs {
            minLat = min(minLat, poi.coordinates.latitude)
            maxLat = max(maxLat, poi.coordinates.latitude)
            minLon = min(minLon, poi.coordinates.longitude)
            maxLon = max(maxLon, poi.coordinates.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension POISearchMapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Debounce search
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedSearch), object: nil)
        perform(#selector(delayedSearch), with: nil, afterDelay: 0.5)
    }
    
    @objc private func delayedSearch() {
        performSearch(query: searchBar.text ?? "")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(query: searchBar.text ?? "")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchResults = []
        tableView.reloadData()
        updateMapAnnotations()
        emptyStateLabel.isHidden = false
        emptyStateLabel.text = "Search for places to add to your trip"
    }
}

// MARK: - UITableViewDataSource

extension POISearchMapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = searchResults.count
        print("📋 [POI SEARCH] Table asking for row count: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🔨 [POI SEARCH] Creating cell for row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath) as! POISearchResultCell
        let poi = searchResults[indexPath.row]
        cell.configure(with: poi)
        print("✅ [POI SEARCH] Configured cell with: \(poi.name)")
        return cell
    }
}

// MARK: - UITableViewDelegate

extension POISearchMapViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedPOI = searchResults[indexPath.row]
        
        print("🎯 [POI SELECTION] User selected POI:")
        print("   Name: \(selectedPOI.name)")
        print("   Category: \(selectedPOI.category.rawValue)")
        print("   Coordinates: \(selectedPOI.coordinates.latitude), \(selectedPOI.coordinates.longitude)")
        print("   Address: \(selectedPOI.address ?? "No address")")
        
        // Find province
        let coordinate = Coordinate(
            latitude: selectedPOI.coordinates.latitude,
            longitude: selectedPOI.coordinates.longitude
        )
        if let province = Vietnam2025.findProvince(near: coordinate) {
            print("   📍 Province: \(province.name)")
        } else {
            print("   ⚠️ No province match found")
        }
        
        print("   📅 Date: \(formatDate(selectedDate))")
        print("   ✅ Dismissing search modal first...")
        
        // Dismiss FIRST, then notify delegate in completion
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            print("   🔔 Search modal dismissed, notifying delegate...")
            self.delegate?.didSelectPOI(selectedPOI, forDate: self.selectedDate)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - MKMapViewDelegate

extension POISearchMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let poiAnnotation = annotation as? POIAnnotation else { return nil }
        
        let isExisting = existingAnnotations.contains(poiAnnotation)
        let identifier = isExisting ? "ExistingPOI" : "SearchResult"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // Add "Add" button for search results
            if !isExisting {
                let button = UIButton(type: .contactAdd)
                annotationView?.rightCalloutAccessoryView = button
            }
        } else {
            annotationView?.annotation = annotation
        }
        
        // Color coding: Blue for existing, Green for search results
        annotationView?.markerTintColor = isExisting ? .systemBlue : .systemGreen
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let poiAnnotation = view.annotation as? POIAnnotation else { return }
        
        // Only allow adding search results (not existing POIs)
        guard !existingAnnotations.contains(poiAnnotation) else { return }
        
        // User tapped "Add" button on search result pin
        delegate?.didSelectPOI(poiAnnotation.poi, forDate: selectedDate)
        dismiss(animated: true)
    }
}

// MARK: - POISearchResultCell

class POISearchResultCell: UITableViewCell {
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemOrange
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private let categoryBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private let provinceBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .systemGreen
        label.textAlignment = .center
        label.layer.cornerRadius = 4
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
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(categoryBadge)
        contentView.addSubview(provinceBadge)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        provinceBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: -8),
            
            categoryBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            categoryBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            categoryBadge.heightAnchor.constraint(equalToConstant: 24),
            
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            provinceBadge.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 6),
            provinceBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            provinceBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            provinceBadge.heightAnchor.constraint(equalToConstant: 20),
            provinceBadge.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
        ])
    }
    
    func configure(with poi: PointOfInterest) {
        // Set icon based on category
        let iconName: String
        switch poi.category {
        case .restaurant: iconName = "fork.knife.circle.fill"
        case .accommodation: iconName = "bed.double.circle.fill"
        case .attraction: iconName = "star.circle.fill"
        case .museum: iconName = "building.columns.circle.fill"
        case .park, .nature: iconName = "tree.circle.fill"
        case .shopping, .market: iconName = "cart.circle.fill"
        case .entertainment, .nightlife: iconName = "theatermasks.circle.fill"
        case .transportation: iconName = "car.circle.fill"
        case .cafe: iconName = "cup.and.saucer.fill"
        case .beach: iconName = "figure.surfing"
        case .viewpoint: iconName = "binoculars.fill"
        case .religious: iconName = "building.fill"
        case .cultural: iconName = "paintpalette.fill"
        case .medical: iconName = "cross.circle.fill"
        case .other: iconName = "mappin.circle.fill"
        }
        iconView.image = UIImage(systemName: iconName)
        
        nameLabel.text = poi.name
        addressLabel.text = poi.address ?? "No address available"
        categoryBadge.text = " \(poi.category.rawValue.capitalized) "
        
        // Show province/region if available
        if let province = findProvince(for: poi) {
            provinceBadge.isHidden = false
            provinceBadge.text = " 📍 \(province.name) "
            print("🗺️ [CELL] POI '\(poi.name)' matched to province: \(province.name)")
        } else {
            provinceBadge.isHidden = true
            print("⚠️ [CELL] POI '\(poi.name)' has no province match")
        }
    }
    
    private func findProvince(for poi: PointOfInterest) -> ProvinceInfo? {
        let coordinate = Coordinate(
            latitude: poi.coordinates.latitude,
            longitude: poi.coordinates.longitude
        )
        return Vietnam2025.findProvince(near: coordinate)
    }
}

