//
//  TripMapViewController.swift
//  TripSync
//
//  Created by Tien Tran on 9/10/2025.
//

import UIKit
import MapKit
import CoreLocation

class TripMapViewController: UIViewController {

    // MARK: - Properties
    private var trip: Trip
    private var mapView: MKMapView!
    private var locationManager: CLLocationManager!

    // Map annotations and overlays
    private var dayAnnotations: [DayAnnotation] = []
    private var poiAnnotations: [POIAnnotation] = []
    private var routeOverlays: [MKOverlay] = []

    // Route caching to prevent API throttling
    private var routeCache: [String: MKPolyline] = [:]
    private var isCachingEnabled = true

    // UI Controls
    private var mapControlsContainer: UIView!
    private var layerToggleButton: UIButton!  // POI toggle - bottom left
    private var showCurrentLocationButton: UIButton!  // My Location - bottom right
    private var daySegmentedControl: UISegmentedControl!
    private var scrollView: UIScrollView!
    private var detailsTableView: UITableView!  // Day details table
    private var detailsTableHeightConstraint: NSLayoutConstraint!
    private var titleLabel: UILabel!  // Title below nav bar

    // Current state
    private var showPOIs = true
    private var showRoutes = true
    private var selectedDayIndex: Int = 0
    private var tripDays: [String] = []
    private var currentDayActivities: [(name: String, startTime: String, endTime: String)] = []

    // Table view item types
    private enum TableViewItem {
        case activity(name: String, startTime: String, endTime: String)
        case transport(mode: String, duration: String)
    }
    private var tableViewItems: [TableViewItem] = []

    // MARK: - Initialization
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTripDays()
        setupUI()
        setupMapView()
        setupLocationManager()
        setupMapControls()
        loadTripOnMap()
        setDefaultDaySelection()
    }

    private func setupTripDays() {
        let calendar = Calendar.current

        // Force exactly 5 days for Vietnam trip
        let tripDuration: Int
        if trip.title.contains("Vietnam") {
            tripDuration = 5  // Force 5 days for Vietnam
            print("🔧 [MAP] Forcing Vietnam trip to 5 days")
        } else {
            tripDuration = (calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0) + 1
        }

        // Create day labels
        tripDays = (0..<tripDuration).map { dayIndex in
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Day \(dayIndex + 1)\n\(formatter.string(from: dayDate))"
        }

        print("📅 [MAP] Setup \(tripDays.count) days for segmented control")
    }

    private func setDefaultDaySelection() {
        let today = Date()
        let calendar = Calendar.current

        // Check if today falls within the trip dates
        if today >= trip.startDate && today <= trip.endDate {
            // Calculate which day of the trip today is
            let daysFromStart = calendar.dateComponents([.day], from: trip.startDate, to: today).day ?? 0
            selectedDayIndex = max(0, min(daysFromStart, tripDays.count - 1))
            print("📅 [MAP] Selected current trip day: Day \(selectedDayIndex + 1)")
        } else {
            // Default to first day
            selectedDayIndex = 0
            print("📅 [MAP] Defaulted to first day: Day 1")
        }

        if daySegmentedControl != nil {
            daySegmentedControl.selectedSegmentIndex = selectedDayIndex
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start location updates if user has granted permission
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    let status = self.locationManager.authorizationStatus
                    if status == .authorizedWhenInUse || status == .authorizedAlways {
                        self.locationManager.startUpdatingLocation()
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        title = trip.title  // Remove Day 1 coords, just show trip title
        view.backgroundColor = .systemBackground

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // Add settings button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )

        // Add date button below navigation bar
        setupDateButton()

        // Add directional navigation controls
        setupDirectionalControls()
    }

    private func setupDateButton() {
        // Title label showing trip name
        titleLabel = UILabel()
        titleLabel.text = trip.title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Date label below title
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateRange = "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
        dateLabel.text = dateRange
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupDirectionalControls() {
        // Create container for directional buttons
        let directionalContainer = UIView()
        directionalContainer.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        directionalContainer.layer.cornerRadius = 12
        directionalContainer.layer.shadowColor = UIColor.black.cgColor
        directionalContainer.layer.shadowOpacity = 0.1
        directionalContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        directionalContainer.layer.shadowRadius = 4
        directionalContainer.translatesAutoresizingMaskIntoConstraints = false

        // Create directional buttons with proper sizing
        let buttonSize: CGFloat = 44

        // Up button (zoom in)
        let upButton = createDirectionalButton(
            systemName: "plus.magnifyingglass",
            backgroundColor: .systemBlue,
            action: #selector(zoomInTapped)
        )

        // Down button (zoom out)
        let downButton = createDirectionalButton(
            systemName: "minus.magnifyingglass",
            backgroundColor: .systemBlue,
            action: #selector(zoomOutTapped)
        )

        // Left button (previous day)
        let leftButton = createDirectionalButton(
            systemName: "chevron.left",
            backgroundColor: .systemGreen,
            action: #selector(previousDayTapped)
        )

        // Right button (next day)
        let rightButton = createDirectionalButton(
            systemName: "chevron.right",
            backgroundColor: .systemGreen,
            action: #selector(nextDayTapped)
        )

        // Add buttons to container
        directionalContainer.addSubview(upButton)
        directionalContainer.addSubview(downButton)
        directionalContainer.addSubview(leftButton)
        directionalContainer.addSubview(rightButton)

        view.addSubview(directionalContainer)

        // Set up constraints for cross layout
        NSLayoutConstraint.activate([
            // Container constraints
            directionalContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            directionalContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            directionalContainer.widthAnchor.constraint(equalToConstant: buttonSize * 3),
            directionalContainer.heightAnchor.constraint(equalToConstant: buttonSize * 3),

            // Up button (top center)
            upButton.centerXAnchor.constraint(equalTo: directionalContainer.centerXAnchor),
            upButton.topAnchor.constraint(equalTo: directionalContainer.topAnchor, constant: 8),
            upButton.widthAnchor.constraint(equalToConstant: buttonSize),
            upButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // Down button (bottom center)
            downButton.centerXAnchor.constraint(equalTo: directionalContainer.centerXAnchor),
            downButton.bottomAnchor.constraint(equalTo: directionalContainer.bottomAnchor, constant: -8),
            downButton.widthAnchor.constraint(equalToConstant: buttonSize),
            downButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // Left button (middle left)
            leftButton.leadingAnchor.constraint(equalTo: directionalContainer.leadingAnchor, constant: 8),
            leftButton.centerYAnchor.constraint(equalTo: directionalContainer.centerYAnchor),
            leftButton.widthAnchor.constraint(equalToConstant: buttonSize),
            leftButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // Right button (middle right)
            rightButton.trailingAnchor.constraint(equalTo: directionalContainer.trailingAnchor, constant: -8),
            rightButton.centerYAnchor.constraint(equalTo: directionalContainer.centerYAnchor),
            rightButton.widthAnchor.constraint(equalToConstant: buttonSize),
            rightButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
    }

    private func createDirectionalButton(systemName: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.backgroundColor = backgroundColor.withAlphaComponent(0.1)
        button.tintColor = backgroundColor
        button.layer.cornerRadius = 22 // buttonSize / 2
        button.layer.borderWidth = 1
        button.layer.borderColor = backgroundColor.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Directional Button Actions
    @objc private func zoomInTapped() {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(
            center: currentRegion.center,
            latitudinalMeters: currentRegion.span.latitudeDelta * 111000 * 0.5, // Zoom in by 50%
            longitudinalMeters: currentRegion.span.longitudeDelta * 111000 * 0.5
        )
        mapView.setRegion(newRegion, animated: true)
        print("🔍 [MAP] Zoomed in")
    }

    @objc private func zoomOutTapped() {
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(
            center: currentRegion.center,
            latitudinalMeters: currentRegion.span.latitudeDelta * 111000 * 2.0, // Zoom out by 100%
            longitudinalMeters: currentRegion.span.longitudeDelta * 111000 * 2.0
        )
        mapView.setRegion(newRegion, animated: true)
        print("🔍 [MAP] Zoomed out")
    }

    @objc private func previousDayTapped() {
        guard daySegmentedControl.selectedSegmentIndex > 1 else { return } // Can't go before "All" and Day 1

        daySegmentedControl.selectedSegmentIndex -= 1
        dayChanged()
        print("📅 [MAP] Previous day selected")
    }

    @objc private func nextDayTapped() {
        guard daySegmentedControl.selectedSegmentIndex < daySegmentedControl.numberOfSegments - 1 else { return }

        daySegmentedControl.selectedSegmentIndex += 1
        dayChanged()
        print("📅 [MAP] Next day selected")
    }

    private func setupMapView() {
        mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.showsScale = true

        // Enable 3D
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true

        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    private func setupMapControls() {
        // Container for day segment control at bottom
        mapControlsContainer = UIView()
        mapControlsContainer.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        mapControlsContainer.layer.cornerRadius = 12
        mapControlsContainer.layer.shadowColor = UIColor.black.cgColor
        mapControlsContainer.layer.shadowOpacity = 0.1
        mapControlsContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        mapControlsContainer.layer.shadowRadius = 4
        mapControlsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add to view hierarchy BEFORE creating constraints that reference it
        view.addSubview(mapControlsContainer)

        // Now setup details table view (mapControlsContainer is in view hierarchy)
        setupDetailsTableView()

        // Day segment with scroll view for many days
        setupDaySegmentedControl()

        // Add scrollView to container
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        mapControlsContainer.addSubview(scrollView)

        // POI toggle button - bottom left corner (Maps app style)
        layerToggleButton = createMapStyleButton(
            systemName: "mappin.circle.fill",
            backgroundColor: .systemBackground
        )
        layerToggleButton.addTarget(self, action: #selector(togglePOIs), for: .touchUpInside)
        view.addSubview(layerToggleButton)

        // My Location button - bottom right corner (Maps app style)
        showCurrentLocationButton = createMapStyleButton(
            systemName: "location.fill",
            backgroundColor: .systemBackground
        )
        showCurrentLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)
        view.addSubview(showCurrentLocationButton)

        NSLayoutConstraint.activate([
            // Day segment container at bottom center
            mapControlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            mapControlsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapControlsContainer.widthAnchor.constraint(equalToConstant: 290), // Fixed width that fits screen
            mapControlsContainer.heightAnchor.constraint(equalToConstant: 44),

            // ScrollView inside container
            scrollView.topAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: mapControlsContainer.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: mapControlsContainer.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: mapControlsContainer.bottomAnchor, constant: -6),

            // POI toggle button - bottom left
            layerToggleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            layerToggleButton.bottomAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: -12),
            layerToggleButton.widthAnchor.constraint(equalToConstant: 44),
            layerToggleButton.heightAnchor.constraint(equalToConstant: 44),

            // My Location button - bottom right
            showCurrentLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            showCurrentLocationButton.bottomAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: -12),
            showCurrentLocationButton.widthAnchor.constraint(equalToConstant: 44),
            showCurrentLocationButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func createMapStyleButton(systemName: String, backgroundColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.backgroundColor = backgroundColor
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupDetailsTableView() {
        detailsTableView = UITableView()
        detailsTableView.delegate = self
        detailsTableView.dataSource = self

        // Register both cell types
        detailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
        detailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TransportCell")

        detailsTableView.backgroundColor = .systemBackground
        detailsTableView.layer.cornerRadius = 12
        detailsTableView.layer.masksToBounds = true
        detailsTableView.isHidden = true  // Hidden by default
        detailsTableView.separatorStyle = .none
        detailsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailsTableView)

        // Create constraint with lower priority to avoid conflicts
        detailsTableHeightConstraint = detailsTableView.heightAnchor.constraint(equalToConstant: 0)
        detailsTableHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            detailsTableView.bottomAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: -16),
            detailsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            detailsTableHeightConstraint
        ])
    }

    private func setupDaySegmentedControl() {
        // Create segmented control with day items including "All" option
        let maxDays = tripDays.count // Use actual trip days count (5 for Vietnam)
        var dayItems: [String] = ["All"]  // Start with "All" option

        for index in 0..<maxDays {
            dayItems.append("Day \(index + 1)")
        }

        // Create scroll view container for segmented control
        // NOTE: Scroll view not working - to be fixed later
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        daySegmentedControl = UISegmentedControl(items: dayItems)
        daySegmentedControl.selectedSegmentIndex = selectedDayIndex + 1  // +1 because "All" is at index 0
        daySegmentedControl.addTarget(self, action: #selector(dayChanged), for: .valueChanged)
        daySegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        // Add segmented control to scroll view
        scrollView.addSubview(daySegmentedControl)

        // Configure scroll view content with explicit width for content size
        NSLayoutConstraint.activate([
            daySegmentedControl.topAnchor.constraint(equalTo: scrollView.topAnchor),
            daySegmentedControl.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            daySegmentedControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            daySegmentedControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            daySegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            // Set minimum width to ensure scrollView has content size
            daySegmentedControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])

        print("📅 [MAP] Day segmented control with scroll view setup with \(dayItems.count) items (\(maxDays) days + All), selected: \(daySegmentedControl.titleForSegment(at: daySegmentedControl.selectedSegmentIndex) ?? "Unknown")")
    }


    // MARK: - Trip Loading
    private func loadTripOnMap() {
        print("🗺️ [MAP] Loading trip on map: \(trip.title)")
        print("📍 [MAP] Trip has \(trip.regions.count) regions")

        clearMapAnnotations()
        createDayAnnotations()
        createPOIAnnotations()

        // Check if we have any POIs to display
        if poiAnnotations.isEmpty {
            print("⚠️ [MAP] No POIs found for this trip")
            showNoPOIsAlert()
        }

        createRouteOverlays()

        // Zoom to first activity if available, otherwise zoom to trip
        if let firstPOI = poiAnnotations.first {
            zoomToFirstActivity(coordinate: firstPOI.coordinate)
        } else {
            zoomToTrip()
        }
    }

    private func showNoPOIsAlert() {
        let alert = UIAlertController(
            title: "No Activities Found",
            message: "This trip doesn't have any points of interest or activities added yet. Add some activities to see them on the map!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func zoomToFirstActivity(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,  // 5km zoom for first activity
            longitudinalMeters: 5000
        )
        mapView.setRegion(region, animated: true)
        print("🎯 [MAP] Zoomed to first activity")
    }

    private func clearMapAnnotations() {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)
        dayAnnotations.removeAll()
        poiAnnotations.removeAll()
        routeOverlays.removeAll()
    }

    private func createDayAnnotations() {
        let calendar = Calendar.current

        // Force exactly 5 days for Vietnam trip to match setupTripDays
        let tripDuration: Int
        if trip.title.contains("Vietnam") {
            tripDuration = 5  // Force 5 days for Vietnam
            print("🔧 [MAP] Forcing Vietnam annotations to 5 days")
        } else {
            tripDuration = (calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0) + 1
        }

        print("📅 [MAP] Creating annotations for \(tripDuration) days")

        for dayIndex in 0..<tripDuration {
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate

            // Get the primary region for this day
            let regionForDay = getRegionForDay(dayIndex)

            if let region = regionForDay, let coordinates = region.coordinates {
                let dayAnnotation = DayAnnotation(
                    dayNumber: dayIndex + 1,
                    date: dayDate,
                    region: region,
                    coordinate: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
                )

                dayAnnotations.append(dayAnnotation)
                mapView.addAnnotation(dayAnnotation)

                print("📍 [MAP] Added Day \(dayIndex + 1) annotation at \(coordinates.latitude), \(coordinates.longitude) - \(region.name)")
            }
        }
    }

    private func getRegionForDay(_ dayIndex: Int) -> TripRegion? {
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate

        // Check main regions first
        for region in trip.regions {
            // Use < for departure to prevent overlap (departure is exclusive)
            if dayDate >= region.arrivalDate && dayDate < region.departureDate {
                // Check if this region has subregions
                if !region.subRegions.isEmpty {
                    // Find the appropriate subregion for this day (each day should map to one city)
                    for subRegion in region.subRegions {
                        // Use < for departure to prevent day overlap between cities
                        if dayDate >= subRegion.arrivalDate && dayDate < subRegion.departureDate {
                            print("🗓️ [MAP] Day \(dayIndex) matched to \(subRegion.name)")
                            return subRegion
                        }
                    }
                    // If no specific subregion matches, return the first subregion
                    print("⚠️ [MAP] Day \(dayIndex) - no exact match, returning first subregion")
                    return region.subRegions.first
                }
                return region
            }
        }

        // Fallback: return the first available region
        print("⚠️ [MAP] Day \(dayIndex) - using fallback region")
        return trip.regions.first?.subRegions.first ?? trip.regions.first
    }

    private func createPOIAnnotations() {
        let allPOIs = trip.regions.flatMap { region in
            region.pointsOfInterest + region.subRegions.flatMap { $0.pointsOfInterest }
        }

        print("📍 [MAP] Creating annotations for \(allPOIs.count) POIs")

        for poi in allPOIs {
            let poiAnnotation = POIAnnotation(
                poi: poi,
                coordinate: CLLocationCoordinate2D(latitude: poi.coordinates.latitude, longitude: poi.coordinates.longitude)
            )

            poiAnnotations.append(poiAnnotation)
            if showPOIs {
                mapView.addAnnotation(poiAnnotation)
            }
        }
    }

    private func createRouteOverlays() {
        print("🛣️ [MAP] Creating route overlays")

        // Check if we have enough annotations
        guard dayAnnotations.count >= 2 else {
            print("⚠️ [MAP] Not enough day annotations to create routes (need at least 2, have \(dayAnnotations.count))")
            return
        }

        // Create routes between day locations
        for i in 0..<(dayAnnotations.count - 1) {
            let startAnnotation = dayAnnotations[i]
            let endAnnotation = dayAnnotations[i + 1]

            createRouteOverlay(
                from: startAnnotation.coordinate,
                to: endAnnotation.coordinate,
                transportMode: getTransportModeForRoute(from: startAnnotation.region, to: endAnnotation.region),
                day: i + 1
            )
        }

        // Create routes within each day (between POIs)
        createPOIRoutes()
    }

    private func getTransportModeForRoute(from: TripRegion, to: TripRegion) -> TransportMode {
        // First check if from region has a transportation method to 'to' region
        if let transport = from.transportationMethods.first(where: { $0.toLocation == to.name }) {
            print("🚗 [MAP] Using transportation mode from region data: \(transport.mode.rawValue)")
            return transport.mode
        }

        // Check if it's international travel
        if from.country != to.country {
            return .flight
        }

        // Fallback to car for domestic travel
        return .car
    }

    private func createRouteOverlay(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transportMode: TransportMode, day: Int) {

        if transportMode == .flight {
            // Create a "bird's eye" curved line for flights
            let flightPath = createFlightPath(from: from, to: to)
            mapView.addOverlay(flightPath)
            routeOverlays.append(flightPath)
            print("✈️ [MAP] Added flight path for Day \(day)")
        } else {
            // For ground transportation, request actual route
            requestGroundRoute(from: from, to: to, transportMode: transportMode, day: day)
        }
    }

    private func createFlightPath(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> FlightPathOverlay {
        return FlightPathOverlay(startCoordinate: from, endCoordinate: to)
    }

    private func requestGroundRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transportMode: TransportMode, day: Int) {
        // Generate cache key based on coordinates and transport mode
        let cacheKey = "\(from.latitude),\(from.longitude)-\(to.latitude),\(to.longitude)-\(transportMode.rawValue)"

        // Check cache first to prevent API throttling
        if isCachingEnabled, let cachedPolyline = routeCache[cacheKey] {
            print("💾 [CACHE] Using cached route for Day \(day) (\(transportMode.rawValue))")
            let routeOverlay = RouteOverlay(polyline: cachedPolyline, transportMode: transportMode)
            mapView.addOverlay(routeOverlay)
            routeOverlays.append(routeOverlay)
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))

        // Set transport type based on mode
        switch transportMode {
        case .car, .taxi, .rideshare:
            request.transportType = .automobile
        case .walking:
            request.transportType = .walking
        case .publicTransport, .bus, .train:
            request.transportType = .transit
        default:
            request.transportType = .automobile
        }

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            if let error = error {
                print("❌ [MAP] Route calculation failed for Day \(day): \(error.localizedDescription)")
                // Fallback to straight line
                DispatchQueue.main.async {
                    self?.createStraightLineRoute(from: from, to: to, transportMode: transportMode)
                }
                return
            }

            guard let route = response?.routes.first else {
                print("⚠️ [MAP] No route found for Day \(day), using straight line")
                DispatchQueue.main.async {
                    self?.createStraightLineRoute(from: from, to: to, transportMode: transportMode)
                }
                return
            }

            DispatchQueue.main.async {
                // Cache the polyline for future use
                self?.routeCache[cacheKey] = route.polyline
                print("💾 [CACHE] Stored route in cache (total: \(self?.routeCache.count ?? 0) routes)")

                let routeOverlay = RouteOverlay(polyline: route.polyline, transportMode: transportMode)
                self?.mapView.addOverlay(routeOverlay)
                self?.routeOverlays.append(routeOverlay)
                print("🛣️ [MAP] Added \(transportMode.rawValue) route for Day \(day)")
            }
        }
    }

    private func createStraightLineRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transportMode: TransportMode) {
        let coordinates = [from, to]
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        // Cache the straight line route too
        let cacheKey = "\(from.latitude),\(from.longitude)-\(to.latitude),\(to.longitude)-\(transportMode.rawValue)"
        if isCachingEnabled {
            routeCache[cacheKey] = polyline
            print("💾 [CACHE] Stored fallback straight line route (total: \(routeCache.count) routes)")
        }

        let routeOverlay = RouteOverlay(polyline: polyline, transportMode: transportMode)
        mapView.addOverlay(routeOverlay)
        routeOverlays.append(routeOverlay)
    }

    private func createPOIRoutes() {
        // Create routes between POIs within each day
        for dayAnnotation in dayAnnotations {
            let dayPOIs = poiAnnotations.filter { poiAnnotation in
                // Simple logic: POIs within 5km of day center
                let distance = CLLocation(latitude: dayAnnotation.coordinate.latitude, longitude: dayAnnotation.coordinate.longitude)
                    .distance(from: CLLocation(latitude: poiAnnotation.coordinate.latitude, longitude: poiAnnotation.coordinate.longitude))
                return distance < 5000 // 5km radius
            }

            // Connect POIs in sequence for walking/short routes - with safe bounds checking
            guard dayPOIs.count >= 2 else { continue } // Need at least 2 POIs to create routes

            for i in 0..<(dayPOIs.count - 1) {
                let fromPOI = dayPOIs[i]
                let toPOI = dayPOIs[i + 1]

                // Use walking for POI-to-POI routes
                createRouteOverlay(
                    from: fromPOI.coordinate,
                    to: toPOI.coordinate,
                    transportMode: .walking,
                    day: dayAnnotation.dayNumber
                )
            }
        }
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func settingsTapped() {
        showMapSettings()
    }

    @objc private func dayChanged() {
        let segmentIndex = daySegmentedControl.selectedSegmentIndex

        if segmentIndex == 0 {
            // "All" option selected
            selectedDayIndex = -1  // Special value for "All"
            print("📅 [MAP] Day selection changed to: All Days")
            showAllDaysView()
        } else {
            // Specific day selected (subtract 1 because "All" is at index 0)
            selectedDayIndex = segmentIndex - 1
            print("📅 [MAP] Day selection changed to: Day \(selectedDayIndex + 1)")
            filterMapContentByDay()
        }
    }

    private func showAllDaysView() {
        // Clear current annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        // Hide details table view
        detailsTableView.isHidden = true
        detailsTableHeightConstraint.constant = 0

        // Show all day annotations (with numbers)
        for annotation in dayAnnotations {
            mapView.addAnnotation(annotation)
        }

        // Show all POIs if enabled (NO ROUTES in All Days view)
        if showPOIs {
            for poi in poiAnnotations {
                mapView.addAnnotation(poi)
            }
        }

        // Zoom out to show entire trip
        zoomToTrip()

        print("🌍 [MAP] Showing all days view with \(dayAnnotations.count) day annotations and \(poiAnnotations.count) POIs - NO ROUTES")
    }

    private func filterMapContentByDay() {
        // Clear current annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        // Show details table for the selected day
        loadDayActivities(for: selectedDayIndex)
        showDetailsTable()

        // Determine zoom level based on map context
        let zoomLevel = determineZoomLevel()

        switch zoomLevel {
        case .country:
            showCountryLevelView()
        case .cities:
            showCitiesLevelView()
        case .local:
            showLocalLevelView()
        }
    }

    private func loadDayActivities(for dayIndex: Int) {
        currentDayActivities.removeAll()
        tableViewItems.removeAll()

        guard dayIndex < tripDays.count else { return }

        // Get region for this day
        guard let dayRegion = getRegionForDay(dayIndex) else { return }

        // Calculate the date for this day
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        // Get POIs for this day (within 50km of day center)
        let dayPOIs = poiAnnotations.filter { poi in
            guard let regionCoords = dayRegion.coordinates else { return false }
            let distance = calculateDistance(
                from: poi.coordinate,
                to: CLLocationCoordinate2D(latitude: regionCoords.latitude, longitude: regionCoords.longitude)
            )
            return distance < 50000
        }

        print("📅 [MAP] Loading Day \(dayIndex + 1) activities - \(dateFormatter.string(from: dayDate))")
        print("📍 [MAP] Region: \(dayRegion.name) - \(dayPOIs.count) POIs found")

        // Build table view items with activities and transport between them
        for (index, poiAnnotation) in dayPOIs.enumerated() {
            let startHour = 9 + (index * 2)
            let endHour = startHour + 2

            // Log POI coordinates and details
            print("   📍 POI \(index + 1): \(poiAnnotation.poi.name)")
            print("      Coords: \(poiAnnotation.coordinate.latitude), \(poiAnnotation.coordinate.longitude)")
            print("      Time: \(String(format: "%02d:00", startHour)) - \(String(format: "%02d:00", endHour))")

            // Add activity item
            tableViewItems.append(.activity(
                name: poiAnnotation.poi.name,
                startTime: String(format: "%02d:00", startHour),
                endTime: String(format: "%02d:00", endHour)
            ))

            // Add transport cell between activities (except after the last one)
            if index < dayPOIs.count - 1 {
                tableViewItems.append(.transport(mode: "🚶‍♂️ Walking", duration: "~10 min"))
            }
        }
    }

    private func showDetailsTable() {
        let rowCount = tableViewItems.count
        // Activity cells are 70px, transport cells are 40px
        let activityCount = tableViewItems.filter {
            if case .activity = $0 { return true }
            return false
        }.count
        let transportCount = tableViewItems.count - activityCount
        let tableHeight = min(CGFloat(activityCount * 70 + transportCount * 40), 250)  // Max 250px

        detailsTableHeightConstraint.constant = tableHeight
        detailsTableView.isHidden = rowCount == 0
        detailsTableView.reloadData()

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private enum ZoomLevel {
        case country    // Show entire trip when more than 2 regions
        case cities     // Show main cities when 2 big regions
        case local      // Show local POIs and details
    }

    private func determineZoomLevel() -> ZoomLevel {
        // If trip has multiple regions (international travel), start with country view
        if trip.regions.count > 2 {
            return .country
        }

        // If Vietnam trip has multiple cities, show cities level
        let vietnamRegion = trip.regions.first { $0.name.contains("Vietnam") }
        if let vietnam = vietnamRegion, vietnam.subRegions.count > 2 {
            return .cities
        }

        // Default to local view for detailed POIs
        return .local
    }

    private func showCountryLevelView() {
        // Show flight paths between countries/major regions
        for annotation in dayAnnotations {
            mapView.addAnnotation(annotation)
        }

        // Add flight path overlays with different colors
        createFlightPathOverlays()

        // Zoom to fit entire trip
        zoomToTrip()

        print("🌍 [MAP] Showing country-level view with flight paths")
    }

    private func showCitiesLevelView() {
        // Show selected day annotation and nearby cities
        if selectedDayIndex < dayAnnotations.count {
            let dayAnnotation = dayAnnotations[selectedDayIndex]
            mapView.addAnnotation(dayAnnotation)

            // Add nearby day annotations (±2 days)
            let nearbyRange = max(0, selectedDayIndex - 2)...min(dayAnnotations.count - 1, selectedDayIndex + 2)
            for index in nearbyRange {
                if index != selectedDayIndex {
                    mapView.addAnnotation(dayAnnotations[index])
                }
            }

            // Zoom to region showing multiple cities
            let region = MKCoordinateRegion(
                center: dayAnnotation.coordinate,
                latitudinalMeters: 500000, // 500km - shows multiple cities
                longitudinalMeters: 500000
            )
            mapView.setRegion(region, animated: true)
        }

        print("🏙️ [MAP] Showing cities-level view")
    }

    private func showLocalLevelView() {
        // Show detailed view with POIs for selected day (NO DAY MARKERS - only POIs)
        if selectedDayIndex < dayAnnotations.count {
            let dayAnnotation = dayAnnotations[selectedDayIndex]

            // Add POIs for this day if enabled
            if showPOIs {
                let dayRegion = getRegionForDay(selectedDayIndex)
                let dayPOIs = poiAnnotations.filter { poi in
                    guard let region = dayRegion else { return false }
                    let distance = calculateDistance(
                        from: poi.coordinate,
                        to: CLLocationCoordinate2D(
                            latitude: region.coordinates?.latitude ?? 0,
                            longitude: region.coordinates?.longitude ?? 0
                        )
                    )
                    return distance < 50000 // Within 50km
                }

                // Add POI annotations
                for poi in dayPOIs {
                    mapView.addAnnotation(poi)
                }

                // Draw routes BETWEEN POIs in this day
                if dayPOIs.count >= 2 {
                    for i in 0..<(dayPOIs.count - 1) {
                        let fromPOI = dayPOIs[i]
                        let toPOI = dayPOIs[i + 1]

                        // Use walking for POI-to-POI routes within same day
                        createRouteOverlay(
                            from: fromPOI.coordinate,
                            to: toPOI.coordinate,
                            transportMode: .walking,
                            day: selectedDayIndex + 1
                        )
                    }
                    print("🛣️ [MAP] Drew \(dayPOIs.count - 1) routes between POIs for Day \(selectedDayIndex + 1)")
                }

                // Zoom to FIRST POI instead of day center
                if let firstPOI = dayPOIs.first {
                    print("🎯 [MAP] Zooming to first POI: \(firstPOI.poi.name)")
                    print("   Coords: \(firstPOI.coordinate.latitude), \(firstPOI.coordinate.longitude)")
                    let region = MKCoordinateRegion(
                        center: firstPOI.coordinate,
                        latitudinalMeters: 10000, // 10km - closer zoom to first POI
                        longitudinalMeters: 10000
                    )
                    mapView.setRegion(region, animated: true)
                } else {
                    // Fallback to day center if no POIs
                    print("⚠️ [MAP] No POIs found, zooming to day center")
                    let region = MKCoordinateRegion(
                        center: dayAnnotation.coordinate,
                        latitudinalMeters: 25000,
                        longitudinalMeters: 25000
                    )
                    mapView.setRegion(region, animated: true)
                }
            } else {
                // POIs disabled, zoom to day center
                let region = MKCoordinateRegion(
                    center: dayAnnotation.coordinate,
                    latitudinalMeters: 25000,
                    longitudinalMeters: 25000
                )
                mapView.setRegion(region, animated: true)
            }
        }

        print("📍 [MAP] Showing local-level view with POIs and routes (NO DAY MARKERS)")
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    private func createFlightPathOverlays() {
        // Add international flight from Melbourne to Vietnam
        if let melbourneRegion = trip.regions.first(where: { $0.name.contains("Melbourne") }),
           let vietnamRegion = trip.regions.first(where: { $0.name.contains("Vietnam") }),
           let melbourneCoords = melbourneRegion.coordinates,
           let vietnamCoords = vietnamRegion.coordinates {

            let flightPath = FlightPathOverlay(
                startCoordinate: CLLocationCoordinate2D(latitude: melbourneCoords.latitude, longitude: melbourneCoords.longitude),
                endCoordinate: CLLocationCoordinate2D(latitude: vietnamCoords.latitude, longitude: vietnamCoords.longitude)
            )

            let renderer = FlightPathRenderer(overlay: flightPath)
            renderer.strokeColor = .systemRed // International flights = red
            renderer.lineWidth = 4.0
            renderer.lineDashPattern = [10, 5] // Dashed for flights

            mapView.addOverlay(flightPath)
            routeOverlays.append(flightPath)

            print("✈️ [MAP] Added international flight path (red)")
        }

        // Add domestic flight paths between distant Vietnamese cities
        let vietnamCities = trip.regions.first { $0.name.contains("Vietnam") }?.subRegions ?? []
        if vietnamCities.count > 1 {
            // HCMC to Hanoi flight (major domestic route)
            if let hcmc = vietnamCities.first(where: { $0.name.contains("Ho Chi Minh") }),
               let hanoi = vietnamCities.first(where: { $0.name.contains("Hanoi") }),
               let hcmcCoords = hcmc.coordinates,
               let hanoiCoords = hanoi.coordinates {

                let domesticFlight = FlightPathOverlay(
                    startCoordinate: CLLocationCoordinate2D(latitude: hcmcCoords.latitude, longitude: hcmcCoords.longitude),
                    endCoordinate: CLLocationCoordinate2D(latitude: hanoiCoords.latitude, longitude: hanoiCoords.longitude)
                )

                let renderer = FlightPathRenderer(overlay: domesticFlight)
                renderer.strokeColor = .systemBlue // Domestic flights = blue
                renderer.lineWidth = 3.0
                renderer.lineDashPattern = [8, 4]

                mapView.addOverlay(domesticFlight)
                routeOverlays.append(domesticFlight)

                print("✈️ [MAP] Added domestic flight path (blue)")
            }
        }
    }

    @objc private func togglePOIs() {
        showPOIs.toggle()

        if showPOIs {
            mapView.addAnnotations(poiAnnotations)
            layerToggleButton.setImage(UIImage(systemName: "mappin.circle.fill"), for: .normal)
            layerToggleButton.tintColor = .systemBlue
        } else {
            mapView.removeAnnotations(poiAnnotations)
            layerToggleButton.setImage(UIImage(systemName: "mappin.slash.circle"), for: .normal)
            layerToggleButton.tintColor = .systemGray
        }
    }

    @objc private func zoomToTrip() {
        guard !dayAnnotations.isEmpty else { return }

        let coordinates = dayAnnotations.map { $0.coordinate }
        let region = MKCoordinateRegion.regionThatFits(coordinates: coordinates)

        mapView.setRegion(region, animated: true)
        print("🎯 [MAP] Zoomed to fit entire trip")
    }

    @objc private func showCurrentLocation() {
        guard let userLocation = mapView.userLocation.location else {
            print("📍 [MAP] User location not available")
            return
        }

        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )

        mapView.setRegion(region, animated: true)
        print("📍 [MAP] Centered on user location")
    }

    private func showMapSettings() {
        let alert = UIAlertController(title: "Map Settings", message: "Customize your map view", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Standard Map", style: .default) { _ in
            self.mapView.mapType = .standard
        })

        alert.addAction(UIAlertAction(title: "Satellite", style: .default) { _ in
            self.mapView.mapType = .satellite
        })

        alert.addAction(UIAlertAction(title: "Hybrid", style: .default) { _ in
            self.mapView.mapType = .hybrid
        })

        alert.addAction(UIAlertAction(title: "Toggle Routes", style: .default) { _ in
            self.toggleRoutes()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func toggleRoutes() {
        showRoutes.toggle()

        if showRoutes {
            mapView.addOverlays(routeOverlays)
        } else {
            mapView.removeOverlays(routeOverlays)
        }
    }
}

// MARK: - MKMapViewDelegate
extension TripMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if let dayAnnotation = annotation as? DayAnnotation {
            return createDayAnnotationView(for: dayAnnotation)
        }

        if let poiAnnotation = annotation as? POIAnnotation {
            return createPOIAnnotationView(for: poiAnnotation)
        }

        return nil
    }

    private func createDayAnnotationView(for annotation: DayAnnotation) -> MKAnnotationView {
        let identifier = "DayAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

        annotationView.annotation = annotation
        annotationView.markerTintColor = UIColor.systemBlue
        annotationView.glyphText = "\(annotation.dayNumber)"
        annotationView.titleVisibility = .adaptive
        annotationView.subtitleVisibility = .adaptive
        annotationView.canShowCallout = true

        // Add detail disclosure
        let detailButton = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = detailButton

        return annotationView
    }

    private func createPOIAnnotationView(for annotation: POIAnnotation) -> MKAnnotationView {
        let identifier = "POIAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

        annotationView.annotation = annotation
        annotationView.markerTintColor = getColorForPOICategory(annotation.poi.category)
        annotationView.glyphImage = UIImage(systemName: getSystemImageForPOICategory(annotation.poi.category))
        annotationView.titleVisibility = .adaptive
        annotationView.canShowCallout = true

        return annotationView
    }

    private func getColorForPOICategory(_ category: POICategory) -> UIColor {
        switch category {
        case .restaurant, .cafe: return .systemOrange
        case .market, .shopping: return .systemPurple
        case .museum, .cultural: return .systemBrown
        case .attraction, .viewpoint: return .systemRed
        case .park, .nature, .beach: return .systemGreen
        case .religious: return .systemIndigo
        case .accommodation: return .systemBlue
        default: return .systemGray
        }
    }

    private func getSystemImageForPOICategory(_ category: POICategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .market, .shopping: return "bag"
        case .museum: return "building.columns"
        case .attraction: return "star"
        case .park, .nature: return "tree"
        case .cafe: return "cup.and.saucer"
        case .viewpoint: return "camera"
        case .beach: return "beach.umbrella"
        case .cultural: return "theatermasks"
        case .religious: return "building"
        case .accommodation: return "bed.double"
        default: return "mappin"
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let flightPath = overlay as? FlightPathOverlay {
            return createFlightPathRenderer(for: flightPath)
        }

        if let routeOverlay = overlay as? RouteOverlay {
            return createRouteRenderer(for: routeOverlay)
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    private func createFlightPathRenderer(for overlay: FlightPathOverlay) -> MKOverlayRenderer {
        let renderer = FlightPathRenderer(overlay: overlay)

        // Calculate distance to determine flight type and color
        let distance = calculateDistance(from: overlay.startCoordinate, to: overlay.endCoordinate)

        if distance > 2000000 { // > 2000km = International flight
            renderer.strokeColor = UIColor.systemRed
            renderer.lineWidth = 4.0
            renderer.lineDashPattern = [12, 6]
            print("✈️ [MAP] International flight path: \(Int(distance/1000))km - RED")
        } else if distance > 500000 { // > 500km = Domestic flight
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 3.0
            renderer.lineDashPattern = [8, 4]
            print("✈️ [MAP] Domestic flight path: \(Int(distance/1000))km - BLUE")
        } else { // < 500km = Short flight or regional
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 2.5
            renderer.lineDashPattern = [6, 3]
            print("✈️ [MAP] Regional flight path: \(Int(distance/1000))km - ORANGE")
        }

        return renderer
    }

    private func createRouteRenderer(for overlay: RouteOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay.polyline)

        switch overlay.transportMode {
        case .flight:
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 3.0
            renderer.lineDashPattern = [10, 5]
        case .car, .taxi, .rideshare:
            renderer.strokeColor = UIColor.systemRed
            renderer.lineWidth = 4.0
        case .walking:
            renderer.strokeColor = UIColor.systemGreen
            renderer.lineWidth = 2.0
            renderer.lineDashPattern = [5, 3]
        case .publicTransport, .bus, .train:
            renderer.strokeColor = UIColor.systemPurple
            renderer.lineWidth = 3.0
        default:
            renderer.strokeColor = UIColor.systemGray
            renderer.lineWidth = 2.0
        }

        renderer.alpha = 0.8
        return renderer
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let dayAnnotation = view.annotation as? DayAnnotation {
            showDayDetails(for: dayAnnotation)
        }
    }

    private func showDayDetails(for annotation: DayAnnotation) {
        let formatter = DateFormatter()
        formatter.dateStyle = .full

        let alert = UIAlertController(
            title: "Day \(annotation.dayNumber)",
            message: "\(formatter.string(from: annotation.date))\nRegion: \(annotation.region.name)\nCountry: \(annotation.region.country)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "View Details", style: .default) { _ in
            // TODO: Navigate to day detail view
            print("📅 [MAP] Navigate to Day \(annotation.dayNumber) details")
        })

        alert.addAction(UIAlertAction(title: "Close", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension TripMapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Update current location for real-time features
        guard let currentLocation = locations.last else { return }

        // Check if user is near any POIs (within 100m)
        checkProximityToPOIs(currentLocation: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [LOCATION] Failed to get location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            showCurrentLocationButton.isEnabled = true
        case .denied, .restricted:
            showCurrentLocationButton.isEnabled = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    private func checkProximityToPOIs(currentLocation: CLLocation) {
        for poiAnnotation in poiAnnotations {
            let poiLocation = CLLocation(latitude: poiAnnotation.coordinate.latitude, longitude: poiAnnotation.coordinate.longitude)
            let distance = currentLocation.distance(from: poiLocation)

            if distance < 100 { // Within 100 meters
                print("📍 [PROXIMITY] User is near POI: \(poiAnnotation.poi.name)")
                // TODO: Show proximity notification
                showPOIProximityNotification(poi: poiAnnotation.poi, distance: distance)
            }
        }
    }

    private func showPOIProximityNotification(poi: PointOfInterest, distance: Double) {
        // Only show if POI hasn't been visited yet
        guard poi.visitedDate == nil else { return }

        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "📍 You're near \(poi.name)",
                message: "Distance: \(Int(distance))m\nWould you like to check in?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Check In", style: .default) { _ in
                self.checkInToPOI(poi)
            })

            alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))

            self.present(alert, animated: true)
        }
    }

    private func checkInToPOI(_ poi: PointOfInterest) {
        print("✅ [CHECK-IN] User checked in to: \(poi.name)")
        // TODO: Update POI as visited and sync to Firebase

        // Show success message
        let alert = UIAlertController(
            title: "✅ Checked in!",
            message: "You've checked in to \(poi.name)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate (Day Details Table)
extension TripMapViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableViewItems[indexPath.row]

        switch item {
        case .activity(let name, let startTime, let endTime):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)

            // Reset cell state to prevent reuse issues
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.accessoryView = nil
            cell.accessoryType = .none

            var content = cell.defaultContentConfiguration()
            content.text = name
            content.secondaryText = "\(startTime) - \(endTime)"
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.textProperties.color = .label
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.font = .systemFont(ofSize: 14)

            cell.contentConfiguration = content
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.selectionStyle = .default

            return cell

        case .transport(let mode, let duration):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransportCell", for: indexPath)

            // Reset cell state to prevent reuse issues
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.accessoryView = nil
            cell.accessoryType = .none

            var content = cell.defaultContentConfiguration()
            content.text = mode
            content.secondaryText = duration
            content.textProperties.font = .systemFont(ofSize: 14)
            content.textProperties.color = .systemBlue
            content.secondaryTextProperties.color = .tertiaryLabel
            content.secondaryTextProperties.font = .systemFont(ofSize: 12)
            content.textToSecondaryTextVerticalPadding = 2

            cell.contentConfiguration = content
            cell.backgroundColor = .systemGroupedBackground
            cell.selectionStyle = .none

            // Add decorative border
            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: 20, y: 0, width: 2, height: 40)
            borderLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            borderLayer.name = "transportBorder"

            // Remove old border if exists to prevent duplication
            cell.contentView.layer.sublayers?.removeAll(where: { $0.name == "transportBorder" })
            cell.contentView.layer.addSublayer(borderLayer)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = tableViewItems[indexPath.row]

        switch item {
        case .activity:
            return 70
        case .transport:
            return 40
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = tableViewItems[indexPath.row]

        if case .activity(let name, _, _) = item {
            print("📍 [MAP] Selected activity: \(name)")
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

// MARK: - Extension for Region Fitting
extension MKCoordinateRegion {
    static func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }

        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3, // Add 30% padding
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}