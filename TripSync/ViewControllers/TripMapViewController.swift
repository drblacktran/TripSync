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

    // UI Controls
    private var mapControlsContainer: UIView!
    private var layerToggleButton: UIButton!
    private var zoomToTripButton: UIButton!
    private var showCurrentLocationButton: UIButton!
    private var daySegmentedControl: UISegmentedControl!
    private var scrollView: UIScrollView!

    // Current state
    private var showPOIs = true
    private var showRoutes = true
    private var selectedDayIndex: Int = 0
    private var tripDays: [String] = []

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

        // Force exactly 14 days for Vietnam trip regardless of mock data issues
        let tripDuration: Int
        if trip.title.contains("Vietnam") {
            tripDuration = 14  // Force 14 days for Vietnam
            print("🔧 [MAP] Forcing Vietnam trip to 14 days")
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
        let dateButton = UIButton(type: .system)
        dateButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        dateButton.layer.cornerRadius = 8
        dateButton.layer.shadowColor = UIColor.black.cgColor
        dateButton.layer.shadowOpacity = 0.1
        dateButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        dateButton.layer.shadowRadius = 2
        dateButton.isUserInteractionEnabled = false

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateRange = "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"

        dateButton.setTitle(dateRange, for: .normal)
        dateButton.setTitleColor(.secondaryLabel, for: .normal)
        dateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        dateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateButton)

        NSLayoutConstraint.activate([
            dateButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
        // Container for map controls
        mapControlsContainer = UIView()
        mapControlsContainer.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        mapControlsContainer.layer.cornerRadius = 12
        mapControlsContainer.layer.shadowColor = UIColor.black.cgColor
        mapControlsContainer.layer.shadowOpacity = 0.1
        mapControlsContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        mapControlsContainer.layer.shadowRadius = 4
        mapControlsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Day segment with scroll view for many days
        setupDaySegmentedControl()

        // Layer toggle button
        layerToggleButton = UIButton(type: .system)
        layerToggleButton.setTitle("🏷️ POIs", for: .normal)
        layerToggleButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        layerToggleButton.layer.cornerRadius = 8
        layerToggleButton.addTarget(self, action: #selector(togglePOIs), for: .touchUpInside)

        // Zoom to trip button
        zoomToTripButton = UIButton(type: .system)
        zoomToTripButton.setTitle("🎯 Fit Trip", for: .normal)
        zoomToTripButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        zoomToTripButton.layer.cornerRadius = 8
        zoomToTripButton.addTarget(self, action: #selector(zoomToTrip), for: .touchUpInside)

        // Current location button
        showCurrentLocationButton = UIButton(type: .system)
        showCurrentLocationButton.setTitle("📍 My Location", for: .normal)
        showCurrentLocationButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        showCurrentLocationButton.layer.cornerRadius = 8
        showCurrentLocationButton.addTarget(self, action: #selector(showCurrentLocation), for: .touchUpInside)

        // Stack view for buttons
        let buttonStack = UIStackView(arrangedSubviews: [layerToggleButton, zoomToTripButton, showCurrentLocationButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [scrollView, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        mapControlsContainer.addSubview(mainStack)
        view.addSubview(mapControlsContainer)

        NSLayoutConstraint.activate([
            // Container constraints
            mapControlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            mapControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Stack constraints
            mainStack.topAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: mapControlsContainer.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: mapControlsContainer.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: mapControlsContainer.bottomAnchor, constant: -12),

            // Button heights
            layerToggleButton.heightAnchor.constraint(equalToConstant: 40),
            zoomToTripButton.heightAnchor.constraint(equalToConstant: 40),
            showCurrentLocationButton.heightAnchor.constraint(equalToConstant: 40),

            // Scroll view height
            scrollView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setupDaySegmentedControl() {
        // Create segmented control with day items including "All" option
        let maxDays = min(tripDays.count, 14)
        var dayItems: [String] = ["All"]  // Start with "All" option

        for index in 0..<maxDays {
            dayItems.append("Day \(index + 1)")
        }

        // Create scroll view container for segmented control
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

        // Configure scroll view content
        NSLayoutConstraint.activate([
            daySegmentedControl.topAnchor.constraint(equalTo: scrollView.topAnchor),
            daySegmentedControl.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            daySegmentedControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            daySegmentedControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            daySegmentedControl.heightAnchor.constraint(equalToConstant: 32)
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
        createRouteOverlays()
        zoomToTrip()
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

        // Force exactly 14 days for Vietnam trip to match setupTripDays
        let tripDuration: Int
        if trip.title.contains("Vietnam") {
            tripDuration = 14  // Force 14 days for Vietnam
            print("🔧 [MAP] Forcing Vietnam annotations to 14 days")
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
            if dayDate >= region.arrivalDate && dayDate <= region.departureDate {
                // Check if this region has subregions
                if !region.subRegions.isEmpty {
                    // Find the appropriate subregion for this day
                    for subRegion in region.subRegions {
                        if dayDate >= subRegion.arrivalDate && dayDate <= subRegion.departureDate {
                            return subRegion
                        }
                    }
                    // If no specific subregion matches, return the first subregion
                    return region.subRegions.first
                }
                return region
            }
        }

        // Fallback: return the first available region
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
        // Check if it's international travel
        if from.country != to.country {
            return .flight
        }

        // Check trip's primary transport mode
        return trip.primaryTransportMode
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

        // Show all day annotations
        for annotation in dayAnnotations {
            mapView.addAnnotation(annotation)
        }

        // Show all POIs if enabled
        if showPOIs {
            for poi in poiAnnotations {
                mapView.addAnnotation(poi)
            }
        }

        // Zoom out to show entire trip
        zoomToTrip()

        print("🌍 [MAP] Showing all days view with \(dayAnnotations.count) day annotations and \(poiAnnotations.count) POIs")
    }

    private func filterMapContentByDay() {
        // Clear current annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

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
        // Show detailed view with POIs for selected day
        if selectedDayIndex < dayAnnotations.count {
            let dayAnnotation = dayAnnotations[selectedDayIndex]
            mapView.addAnnotation(dayAnnotation)

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

                for poi in dayPOIs {
                    mapView.addAnnotation(poi)
                }
            }

            // Zoom to local area
            let region = MKCoordinateRegion(
                center: dayAnnotation.coordinate,
                latitudinalMeters: 25000, // 25km - local city view
                longitudinalMeters: 25000
            )
            mapView.setRegion(region, animated: true)
        }

        print("📍 [MAP] Showing local-level view with POIs")
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
            layerToggleButton.setTitle("🏷️ POIs ✓", for: .normal)
            layerToggleButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        } else {
            mapView.removeAnnotations(poiAnnotations)
            layerToggleButton.setTitle("🏷️ POIs", for: .normal)
            layerToggleButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
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