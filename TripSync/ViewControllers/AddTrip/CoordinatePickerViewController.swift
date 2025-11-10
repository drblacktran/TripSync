//
//  CoordinatePickerViewController.swift
//  TripSync
//
//  Created on 7/11/2025.
//  Map-based coordinate picker with search and reverse geocoding
//

import UIKit
import MapKit
import CoreLocation

protocol CoordinatePickerDelegate: AnyObject {
    func coordinatePickerDidSelectLocation(
        _ picker: CoordinatePickerViewController,
        coordinate: CLLocationCoordinate2D,
        name: String,
        address: String
    )
}

class CoordinatePickerViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CoordinatePickerDelegate?
    
    private var mapView: MKMapView!
    private var searchBar: UISearchBar!
    private var searchResultsTable: UITableView!
    private var confirmButton: UIButton!
    private var accuracyLabel: UILabel!
    private var instructionLabel: UILabel!
    
    private var selectedAnnotation: MKPointAnnotation?
    private var searchResults: [OpenStreetMapService.SearchResult] = []
    private var searchWorkItem: DispatchWorkItem?
    
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedName: String?
    private var selectedAddress: String?
    
    private let osmService = OpenStreetMapService.shared
    private let locationManager = CLLocationManager()
    
    // Initial region (can be set before presenting)
    var initialRegion: MKCoordinateRegion?
    var initialCoordinate: CLLocationCoordinate2D?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocationManager()
        setupInitialRegion()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Select Location"
        view.backgroundColor = .systemBackground
        
        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Search bar
        searchBar = UISearchBar()
        searchBar.placeholder = "Search for a place"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Map view
        mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap gesture for pin dropping
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        view.addSubview(mapView)
        
        // Instruction label (overlay on map)
        instructionLabel = UILabel()
        instructionLabel.text = "Tap anywhere on the map to drop a pin"
        instructionLabel.textAlignment = .center
        instructionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        instructionLabel.textColor = .white
        instructionLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Accuracy label (overlay on map)
        accuracyLabel = UILabel()
        accuracyLabel.text = "GPS Accuracy: Unknown"
        accuracyLabel.textAlignment = .center
        accuracyLabel.font = .systemFont(ofSize: 12)
        accuracyLabel.textColor = .secondaryLabel
        accuracyLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        accuracyLabel.layer.cornerRadius = 6
        accuracyLabel.clipsToBounds = true
        accuracyLabel.isHidden = true
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(accuracyLabel)
        
        // Search results table
        searchResultsTable = UITableView()
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        searchResultsTable.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        searchResultsTable.isHidden = true
        searchResultsTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultsTable)
        
        // Confirm button
        confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm Location", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.isEnabled = false
        confirmButton.alpha = 0.5
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmButton)
        
        // Layout
        NSLayoutConstraint.activate([
            // Search bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Map view
            mapView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
            instructionLabel.heightAnchor.constraint(equalToConstant: 36),
            
            // Accuracy label
            accuracyLabel.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -12),
            accuracyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            accuracyLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
            accuracyLabel.heightAnchor.constraint(equalToConstant: 28),
            
            // Search results table
            searchResultsTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Confirm button
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupInitialRegion() {
        if let region = initialRegion {
            mapView.setRegion(region, animated: false)
        } else if let coordinate = initialCoordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapView.setRegion(region, animated: false)
        } else {
            // Default to world view
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
            )
            mapView.setRegion(region, animated: false)
        }
        
        // Request location permission
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmTapped() {
        guard let coordinate = selectedCoordinate,
              let name = selectedName,
              let address = selectedAddress else {
            return
        }
        
        delegate?.coordinatePickerDidSelectLocation(
            self,
            coordinate: coordinate,
            name: name,
            address: address
        )
        dismiss(animated: true)
    }
    
    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        dropPin(at: coordinate)
    }
    
    // MARK: - Pin Management
    
    private func dropPin(at coordinate: CLLocationCoordinate2D) {
        // Remove existing annotation
        if let existing = selectedAnnotation {
            mapView.removeAnnotation(existing)
        }
        
        // Create new annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Selected Location"
        
        mapView.addAnnotation(annotation)
        selectedAnnotation = annotation
        
        // Store coordinate
        selectedCoordinate = coordinate
        
        // Hide instruction
        instructionLabel.isHidden = true
        
        // Show loading state
        confirmButton.setTitle("Loading address...", for: .normal)
        confirmButton.isEnabled = false
        confirmButton.alpha = 0.5
        
        // Reverse geocode
        Task {
            await reverseGeocodeAndUpdate(coordinate: coordinate)
        }
    }
    
    private func reverseGeocodeAndUpdate(coordinate: CLLocationCoordinate2D) async {
        do {
            let result = try await osmService.reverseGeocode(coordinate: coordinate)
            
            await MainActor.run {
                // Update annotation
                selectedAnnotation?.title = osmService.getShortName(result)
                selectedAnnotation?.subtitle = osmService.formatAddress(result)
                
                // Store data
                selectedName = osmService.getShortName(result)
                selectedAddress = osmService.formatAddress(result)
                
                // Enable confirm button
                confirmButton.setTitle("Confirm Location", for: .normal)
                confirmButton.isEnabled = true
                confirmButton.alpha = 1.0
                
                // Show annotation callout
                mapView.selectAnnotation(selectedAnnotation!, animated: true)
            }
        } catch {
            await MainActor.run {
                // Fallback to coordinates if reverse geocoding fails
                selectedName = "Custom Location"
                selectedAddress = String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
                
                selectedAnnotation?.title = selectedName
                selectedAnnotation?.subtitle = selectedAddress
                
                confirmButton.setTitle("Confirm Location", for: .normal)
                confirmButton.isEnabled = true
                confirmButton.alpha = 1.0
                
                showError("Could not get address for this location. You can still use the coordinates.")
            }
        }
    }
    
    // MARK: - Search
    
    private func performSearch(query: String) {
        // Cancel previous search
        searchWorkItem?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            searchResultsTable.reloadData()
            searchResultsTable.isHidden = true
            return
        }
        
        // Create new work item with debouncing
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task {
                await self.executeSearch(query: query)
            }
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func executeSearch(query: String) async {
        do {
            // Get current map region for better results
            let region = await MainActor.run { mapView.region }
            
            let viewBox = (
                minLon: region.center.longitude - region.span.longitudeDelta / 2,
                minLat: region.center.latitude - region.span.latitudeDelta / 2,
                maxLon: region.center.longitude + region.span.longitudeDelta / 2,
                maxLat: region.center.latitude + region.span.latitudeDelta / 2
            )
            
            let results = try await osmService.search(
                query: query,
                viewBox: viewBox,
                limit: 10
            )
            
            await MainActor.run {
                self.searchResults = results
                self.searchResultsTable.reloadData()
                self.searchResultsTable.isHidden = results.isEmpty
            }
        } catch {
            await MainActor.run {
                self.showError("Search failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension CoordinatePickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else {
            return nil // Use default view for user location
        }
        
        let identifier = "PinAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.markerTintColor = .systemRed
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

// MARK: - UISearchBarDelegate

extension CoordinatePickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchResults = []
        searchResultsTable.reloadData()
        searchResultsTable.isHidden = true
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CoordinatePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        let result = searchResults[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = osmService.getShortName(result)
        config.secondaryText = osmService.formatAddress(result)
        config.secondaryTextProperties.font = .systemFont(ofSize: 13)
        config.secondaryTextProperties.color = .secondaryLabel
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result = searchResults[indexPath.row]
        
        // Hide search results and keyboard
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchResults = []
        searchResultsTable.reloadData()
        searchResultsTable.isHidden = true
        
        // Drop pin at selected location
        let coordinate = result.coordinate
        dropPin(at: coordinate)
        
        // Update with search result data (faster than reverse geocoding)
        selectedName = osmService.getShortName(result)
        selectedAddress = osmService.formatAddress(result)
        
        selectedAnnotation?.title = selectedName
        selectedAnnotation?.subtitle = selectedAddress
        
        confirmButton.setTitle("Confirm Location", for: .normal)
        confirmButton.isEnabled = true
        confirmButton.alpha = 1.0
        
        // Zoom to location
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: true)
        
        // Show callout
        mapView.selectAnnotation(selectedAnnotation!, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate

extension CoordinatePickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update accuracy label
        let accuracy = location.horizontalAccuracy
        if accuracy >= 0 {
            accuracyLabel.isHidden = false
            if accuracy <= 10 {
                accuracyLabel.text = "GPS Accuracy: Excellent (±\(Int(accuracy))m)"
                accuracyLabel.textColor = .systemGreen
            } else if accuracy <= 50 {
                accuracyLabel.text = "GPS Accuracy: Good (±\(Int(accuracy))m)"
                accuracyLabel.textColor = .systemBlue
            } else if accuracy <= 100 {
                accuracyLabel.text = "GPS Accuracy: Fair (±\(Int(accuracy))m)"
                accuracyLabel.textColor = .systemOrange
            } else {
                accuracyLabel.text = "GPS Accuracy: Poor (±\(Int(accuracy))m)"
                accuracyLabel.textColor = .systemRed
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
        }
    }
}
