//
//  TripMapViewController.swift
//  TripSync
//
//  Created by Tien Tran on 9/10/2025.
//

import UIKit
import MapKit
import CoreLocation

class TripMapViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Zoom Constants
    private let activityZoomRadiusMeters: Double = 500
    private let routeZoomPaddingMultiplier: Double = 1.3
    
    // MARK: - Layout Constants
    private let minMapHeightForSmallDevices: CGFloat = 250
    private let dayViewMapHeightMultiplier: CGFloat = 0.5
    private let allDaysViewMapHeightMultiplier: CGFloat = 0.95
    
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
    
    // Weather
    private var temperatureUnit: TemperatureUnit = .celsius
    private var currentDayWeather: WeatherForecast?
    private var weatherBadgeView: UIView!
    private var weatherBadgeLabel: UILabel!
    
    // Budget
    private var budgetBadgeView: UIView!
    private var budgetBadgeLabel: UILabel!
    private var currentDayBudget: Double = 0  // In local currency

    // UI Controls
    private var mapControlsContainer: UIView!
    private var layerToggleButton: UIButton!  // POI toggle - bottom left
    private var showCurrentLocationButton: UIButton!  // My Location - bottom right
    private var daySegmentedControl: UISegmentedControl!
    private var dayScrollView: UIScrollView!  // Scrollable container for day buttons
    private var dayButtonsStackView: UIStackView!  // Stack view for day buttons
    private var scrollView: UIScrollView!
    private var detailsTableView: UITableView!  // Day details table
    private var titleLabel: UILabel!  // Title below nav bar
    private var dayButtons: [UIButton] = []  // Store references to day buttons
    
    // Dynamic layout constraints
    private var mapHeightConstraint: NSLayoutConstraint!
    private var mapBottomConstraint: NSLayoutConstraint!
    private var segmentTopConstraint: NSLayoutConstraint!

    // Current state
    private var showPOIs = true
    private var showRoutes = true
    private var selectedDayIndex: Int = 0
    private var tripDays: [String] = []
    private var currentDayActivities: [(name: String, startTime: String, endTime: String)] = []

    // Table view item types
    private enum TableViewItem {
        case weatherHeader(forecast: WeatherForecast?, error: String?)  // Weather at top of day
        case activity(name: String, startTime: String, endTime: String, coordinate: CLLocationCoordinate2D, poi: PointOfInterest?)
        case transport(mode: String, duration: String, fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D)
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
        fetchUserPreferences()
    }

    private func setupTripDays() {
        let calendar = Calendar.current
        
        // Calculate trip duration from actual dates
        let tripDuration = (calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0) + 1

        // Create day labels with dates
        tripDays = (0..<tripDuration).map { dayIndex in
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Day \(dayIndex + 1)\n\(formatter.string(from: dayDate))"
        }

        print("📅 [MAP] Setup \(tripDays.count) days for trip: \(trip.title)")
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

        // Update button selection if buttons are created
        if !dayButtons.isEmpty {
            updateDayButtonSelection(for: selectedDayIndex)
        }
    }
    
    // MARK: - User Preferences
    
    private func fetchUserPreferences() {
        guard let userId = FirebaseManager.shared.getCurrentUser()?.uid else {
            print("⚠️ [WEATHER] No user ID, using default Celsius")
            return
        }
        
        FirebaseManager.shared.fetchUserSettings(userId: userId) { [weak self] settings in
            guard let self = self else { return }
            
            if let unitString = settings?["temperatureUnit"] as? String,
               let unit = TemperatureUnit(rawValue: unitString) {
                self.temperatureUnit = unit
                print("✅ [WEATHER] Temperature unit: \(unit == .celsius ? "Celsius" : "Fahrenheit")")
            } else {
                print("⚠️ [WEATHER] No temperature unit in settings, using Celsius")
                self.temperatureUnit = .celsius
            }
        }
    }
    
    // MARK: - Weather
    
    private func fetchWeatherForDay(dayIndex: Int, completion: @escaping (WeatherForecast?, String?) -> Void) {
        guard dayIndex < tripDays.count else {
            completion(nil, "Invalid day")
            return
        }
        
        // Get the date for this day
        let calendar = Calendar.current
        guard let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: trip.startDate) else {
            completion(nil, "Invalid date")
            return
        }
        
        // Get the region for this day to get coordinates
        guard let dayRegion = getRegionForDay(dayIndex) else {
            print("⚠️ [WEATHER] No region found for day \(dayIndex + 1)")
            completion(nil, "No location data")
            return
        }
        
        // Use region coordinates directly
        guard let coordinates = dayRegion.coordinates else {
            print("⚠️ [WEATHER] No coordinates for region: \(dayRegion.name)")
            completion(nil, "No location data")
            return
        }
        
        let lat = coordinates.latitude
        let lon = coordinates.longitude
        
        print("🌤️ [WEATHER] Fetching weather for Day \(dayIndex + 1) (\(dayRegion.name)) at \(lat), \(lon)")
        
        WeatherService.shared.fetchWeather(latitude: lat, longitude: lon, for: dayDate) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dayWeather):
                    // Get weather at 9 AM (morning forecast)
                    if let morningWeather = WeatherFormatter.weatherAt(hour: 9, in: dayWeather) {
                        completion(morningWeather, nil)
                    } else if let firstForecast = dayWeather.hourlyForecasts.first {
                        completion(firstForecast, nil)
                    } else {
                        completion(nil, "No forecast available")
                    }
                    
                case .failure(let error):
                    print("❌ [WEATHER] Error: \(error.localizedDescription)")
                    if let weatherError = error as? WeatherError,
                       case .dateOutOfRange(let days) = weatherError {
                        completion(nil, "Forecast available \(Constants.Weather.maxForecastDays) days before trip (in \(days) days)")
                    } else {
                        completion(nil, error.localizedDescription)
                    }
                }
            }
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
        guard selectedDayIndex > 0 else { return } // Can't go before Day 1 (selectedDayIndex starts at 0)

        selectedDayIndex -= 1
        updateDayButtonSelection(for: selectedDayIndex)
        dayChanged()
        print("📅 [MAP] Previous day selected")
    }

    @objc private func nextDayTapped() {
        guard selectedDayIndex < tripDays.count - 1 else { return }

        selectedDayIndex += 1
        updateDayButtonSelection(for: selectedDayIndex)
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

        // Calculate initial map height (50% for day view with minimum)
        let initialMapHeight = max(
            view.bounds.height * dayViewMapHeightMultiplier,
            minMapHeightForSmallDevices
        )
        
        mapHeightConstraint = mapView.heightAnchor.constraint(equalToConstant: initialMapHeight)
        mapBottomConstraint = mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        mapBottomConstraint.isActive = false // Will be activated in "All" view
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapHeightConstraint
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

        // Add dayScrollView to container
        dayScrollView.translatesAutoresizingMaskIntoConstraints = false
        mapControlsContainer.addSubview(dayScrollView)
        
        // Weather badge - floating on map (top-right corner)
        setupWeatherBadge()
        
        // Budget badge - floating on map (top-left corner)
        setupBudgetBadge()

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
        
        // Store constraint for dynamic positioning
        segmentTopConstraint = mapControlsContainer.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            // Day segment container - positioned below map (will move to bottom in "All" view)
            segmentTopConstraint,
            mapControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapControlsContainer.heightAnchor.constraint(equalToConstant: 62),  // Increased for two-line buttons

            // DayScrollView inside container
            dayScrollView.topAnchor.constraint(equalTo: mapControlsContainer.topAnchor, constant: 4),
            dayScrollView.leadingAnchor.constraint(equalTo: mapControlsContainer.leadingAnchor),
            dayScrollView.trailingAnchor.constraint(equalTo: mapControlsContainer.trailingAnchor),
            dayScrollView.bottomAnchor.constraint(equalTo: mapControlsContainer.bottomAnchor, constant: -4),

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
    
    private func setupWeatherBadge() {
        // Container view for weather badge
        weatherBadgeView = UIView()
        weatherBadgeView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        weatherBadgeView.layer.cornerRadius = 12
        weatherBadgeView.layer.shadowColor = UIColor.black.cgColor
        weatherBadgeView.layer.shadowOpacity = 0.15
        weatherBadgeView.layer.shadowOffset = CGSize(width: 0, height: 2)
        weatherBadgeView.layer.shadowRadius = 4
        weatherBadgeView.translatesAutoresizingMaskIntoConstraints = false
        weatherBadgeView.isHidden = true  // Hidden until weather loads
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(weatherBadgeTapped))
        weatherBadgeView.addGestureRecognizer(tapGesture)
        
        // Horizontal stack for icon + label
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        weatherBadgeView.addSubview(stackView)
        
        // Weather icon (SF Symbol ImageView)
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        iconImageView.tag = 100  // Tag to find and update later
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(iconImageView)
        
        // Weather label
        weatherBadgeLabel = UILabel()
        weatherBadgeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        weatherBadgeLabel.textColor = .label
        weatherBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(weatherBadgeLabel)
        
        view.addSubview(weatherBadgeView)
        
        NSLayoutConstraint.activate([
            // Position in top-right corner of map
            weatherBadgeView.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            weatherBadgeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            weatherBadgeView.heightAnchor.constraint(equalToConstant: 36),
            
            // Stack view inside badge
            stackView.centerYAnchor.constraint(equalTo: weatherBadgeView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: weatherBadgeView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: weatherBadgeView.trailingAnchor, constant: -10),
            
            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupBudgetBadge() {
        // Container view for budget badge
        budgetBadgeView = UIView()
        budgetBadgeView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        budgetBadgeView.layer.cornerRadius = 12
        budgetBadgeView.layer.shadowColor = UIColor.black.cgColor
        budgetBadgeView.layer.shadowOpacity = 0.15
        budgetBadgeView.layer.shadowOffset = CGSize(width: 0, height: 2)
        budgetBadgeView.layer.shadowRadius = 4
        budgetBadgeView.translatesAutoresizingMaskIntoConstraints = false
        budgetBadgeView.isHidden = true  // Hidden until budget data loads
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(budgetBadgeTapped))
        budgetBadgeView.addGestureRecognizer(tapGesture)
        
        // Horizontal stack for icon + label
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        budgetBadgeView.addSubview(stackView)
        
        // Budget icon (SF Symbol ImageView)
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "dollarsign.circle.fill")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemGreen
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(iconImageView)
        
        // Budget label
        budgetBadgeLabel = UILabel()
        budgetBadgeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        budgetBadgeLabel.textColor = .label
        budgetBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(budgetBadgeLabel)
        
        view.addSubview(budgetBadgeView)
        
        NSLayoutConstraint.activate([
            // Position in top-left corner of map (opposite weather badge)
            budgetBadgeView.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            budgetBadgeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            budgetBadgeView.heightAnchor.constraint(equalToConstant: 36),
            
            // Stack view inside badge
            stackView.centerYAnchor.constraint(equalTo: budgetBadgeView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: budgetBadgeView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: budgetBadgeView.trailingAnchor, constant: -10),
            
            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupDetailsTableView() {
        detailsTableView = UITableView()
        detailsTableView.delegate = self
        detailsTableView.dataSource = self

        // Register all cell types
        detailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "WeatherCell")
        detailsTableView.register(POIDetailCell.self, forCellReuseIdentifier: POIDetailCell.identifier)
        detailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
        detailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TransportCell")

        detailsTableView.backgroundColor = .systemBackground
        detailsTableView.layer.cornerRadius = 12
        detailsTableView.layer.masksToBounds = true
        detailsTableView.isHidden = true  // Hidden by default
        detailsTableView.separatorStyle = .none
        detailsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailsTableView)

        NSLayoutConstraint.activate([
            // Table fills space between segmented control and safe area bottom
            detailsTableView.topAnchor.constraint(equalTo: mapControlsContainer.bottomAnchor, constant: 0),
            detailsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupDaySegmentedControl() {
        let maxDays = tripDays.count
        var dayItems: [String] = ["All"]
        
        // Build date labels for each day
        for index in 0..<maxDays {
            let dayDate = Calendar.current.date(byAdding: .day, value: index, to: trip.startDate) ?? trip.startDate
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            dayItems.append(formatter.string(from: dayDate))
        }

        // Create horizontal scroll view
        dayScrollView = UIScrollView()
        dayScrollView.showsHorizontalScrollIndicator = false
        dayScrollView.showsVerticalScrollIndicator = false
        dayScrollView.translatesAutoresizingMaskIntoConstraints = false
        dayScrollView.backgroundColor = .clear
        dayScrollView.isPagingEnabled = false
        dayScrollView.decelerationRate = .fast  // Snap behavior
        dayScrollView.delegate = self
        
        // Create horizontal stack view for buttons
        dayButtonsStackView = UIStackView()
        dayButtonsStackView.axis = .horizontal
        dayButtonsStackView.spacing = 12
        dayButtonsStackView.distribution = .fill
        dayButtonsStackView.alignment = .center
        dayButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        dayScrollView.addSubview(dayButtonsStackView)
        
        // Create buttons for each day
        dayButtons.removeAll()
        for (index, dayLabel) in dayItems.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(dayLabel, for: .normal)
            button.tag = index - 1  // -1 for "All", 0+ for actual days
            button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
            button.layer.cornerRadius = 10
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Style based on selection
            if index - 1 == selectedDayIndex {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.label, for: .normal)
            }
            
            dayButtonsStackView.addArrangedSubview(button)
            dayButtons.append(button)
            
            // Set fixed width and height for buttons
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
        
        // Layout constraints for stack view inside scroll view
        NSLayoutConstraint.activate([
            dayButtonsStackView.topAnchor.constraint(equalTo: dayScrollView.topAnchor, constant: 4),
            dayButtonsStackView.leadingAnchor.constraint(equalTo: dayScrollView.leadingAnchor, constant: 12),
            dayButtonsStackView.trailingAnchor.constraint(equalTo: dayScrollView.trailingAnchor, constant: -12),
            dayButtonsStackView.bottomAnchor.constraint(equalTo: dayScrollView.bottomAnchor, constant: -4),
            dayButtonsStackView.heightAnchor.constraint(equalTo: dayScrollView.heightAnchor, constant: -8)
        ])

        print("📅 [MAP] Segmented control: \(dayItems.joined(separator: ", "))")
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        let newDayIndex = sender.tag
        
        // Update button styles
        for button in dayButtons {
            if button.tag == newDayIndex {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.label, for: .normal)
            }
        }
        
        // Update selected index and trigger day change
        selectedDayIndex = newDayIndex
        dayChanged()
        
        // Scroll to center the selected button
        if let selectedButton = dayButtons.first(where: { $0.tag == newDayIndex }) {
            let buttonFrame = selectedButton.convert(selectedButton.bounds, to: dayScrollView)
            let scrollViewBounds = dayScrollView.bounds
            let targetX = buttonFrame.midX - scrollViewBounds.width / 2
            let maxX = dayScrollView.contentSize.width - scrollViewBounds.width
            let clampedX = max(0, min(targetX, maxX))
            
            dayScrollView.setContentOffset(CGPoint(x: clampedX, y: 0), animated: true)
        }
    }
    
    private func updateDayButtonSelection(for dayIndex: Int) {
        // Update button styles
        for button in dayButtons {
            if button.tag == dayIndex {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.label, for: .normal)
            }
        }
        
        // Scroll to center the selected button
        if let selectedButton = dayButtons.first(where: { $0.tag == dayIndex }) {
            let buttonFrame = selectedButton.convert(selectedButton.bounds, to: dayScrollView)
            let scrollViewBounds = dayScrollView.bounds
            let targetX = buttonFrame.midX - scrollViewBounds.width / 2
            let maxX = dayScrollView.contentSize.width - scrollViewBounds.width
            let clampedX = max(0, min(targetX, maxX))
            
            dayScrollView.setContentOffset(CGPoint(x: clampedX, y: 0), animated: true)
        }
    }


    // MARK: - Trip Loading
    private func loadTripOnMap() {
        print("🗺️ [MAP] Loading trip on map: \(trip.title)")
        print("📍 [MAP] Trip has \(trip.regions.count) regions")
        print("💰 [BUDGET] Trip base currency: \(trip.baseCurrency)")

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
        let tripDuration = (calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0) + 1

        print("📅 [MAP] Creating annotations for \(tripDuration) days")

        for dayIndex in 0..<tripDuration {
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate

            // Get the region for this day
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

                print("📍 [MAP] Day \(dayIndex + 1): \(region.name) at (\(coordinates.latitude), \(coordinates.longitude))")
            }
        }
    }

    private func getRegionForDay(_ dayIndex: Int) -> TripRegion? {
        // Find any parent region with subregions (e.g., country with cities)
        guard let parentRegion = trip.regions.first(where: { !$0.subRegions.isEmpty }) else {
            // No subregions, return first region
            return trip.regions.first
        }
        
        // Direct index mapping to subregions (cities)
        if dayIndex < parentRegion.subRegions.count {
            let subRegion = parentRegion.subRegions[dayIndex]
            print("🗓️ [MAP] Day \(dayIndex + 1) → \(subRegion.name) (index-based)")
            return subRegion
        }
        
        // Fallback: cyclic mapping for trips longer than cities
        let cyclicIndex = dayIndex % parentRegion.subRegions.count
        let subRegion = parentRegion.subRegions[cyclicIndex]
        print("⚠️ [MAP] Day \(dayIndex + 1) → \(subRegion.name) (cyclic: \(cyclicIndex))")
        return subRegion
    }

    private func createPOIAnnotations() {
        // Get all POIs from all regions and subregions
        let allPOIs = trip.regions.flatMap { region -> [PointOfInterest] in
            var pois = region.pointsOfInterest
            pois.append(contentsOf: region.subRegions.flatMap { $0.pointsOfInterest })
            return pois
        }

        print("📍 [MAP] Creating annotations for \(allPOIs.count) total POIs")

        for poi in allPOIs {
            let poiAnnotation = POIAnnotation(
                poi: poi,
                coordinate: CLLocationCoordinate2D(
                    latitude: poi.coordinates.latitude,
                    longitude: poi.coordinates.longitude
                )
            )

            poiAnnotations.append(poiAnnotation)
            if showPOIs {
                mapView.addAnnotation(poiAnnotation)
            }
        }
        
        print("📍 [MAP] POI annotations created and ready")
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
        // selectedDayIndex is already updated by dayButtonTapped
        if selectedDayIndex == -1 {
            // "All" option selected
            print("📅 [MAP] Day selection changed to: All Days")
            showAllDaysView()
        } else {
            // Specific day selected
            print("📅 [MAP] Day selection changed to: Day \(selectedDayIndex + 1)")
            filterMapContentByDay()
        }
    }

    private func showAllDaysView() {
        // Clear current annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        // Hide weather badge (no weather in "All" view)
        weatherBadgeView.isHidden = true
        
        // Calculate and show total trip budget
        let tripBudget = BudgetCalculationService.calculateTripBudget(for: trip)
        if tripBudget.totalAmount > 0 {
            currentDayBudget = tripBudget.totalAmount
            let formattedBudget = CurrencyFormatter.formatCompact(
                amount: tripBudget.totalAmount,
                currency: tripBudget.currency,
                showSymbol: true
            )
            budgetBadgeLabel.text = formattedBudget
            budgetBadgeView.isHidden = false
            print("💰 [BUDGET] Showing total trip budget: \(formattedBudget)")
        } else {
            budgetBadgeView.isHidden = true
            currentDayBudget = 0
            print("💰 [BUDGET] No trip budget - hiding badge")
        }
        
        // Zoom map to fit trip first
        zoomToTrip()

        // Animate map expansion and table fade-out
        UIView.animate(
            withDuration: 0.5,
            delay: 0.15,  // Slight delay after zoom starts
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut]
        ) {
            // Expand map to nearly full height
            let mapHeight = self.view.bounds.height * self.allDaysViewMapHeightMultiplier
            self.mapHeightConstraint.constant = mapHeight
            
            // Hide table view
            self.detailsTableView.alpha = 0
            
            self.view.layoutIfNeeded()
        } completion: { _ in
            // Fully hide table after animation
            self.detailsTableView.isHidden = true
        }

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

        print("🌍 [MAP] Showing all days view with \(dayAnnotations.count) day annotations and \(poiAnnotations.count) POIs - NO ROUTES")
    }

    private func filterMapContentByDay() {
        // Clear current annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        // Animate map shrink and table fade-in
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseInOut]
        ) {
            // Shrink map to 50% height (with minimum)
            let mapHeight = max(
                self.view.bounds.height * self.dayViewMapHeightMultiplier,
                self.minMapHeightForSmallDevices
            )
            self.mapHeightConstraint.constant = mapHeight
            
            // Show table view
            self.detailsTableView.isHidden = false
            self.detailsTableView.alpha = 1
            
            self.view.layoutIfNeeded()
        }
        
        // Load day activities (this will also show the details table after weather fetch)
        loadDayActivities(for: selectedDayIndex)

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
        
        // Hide table immediately to prevent crashes during async operations
        detailsTableView.isHidden = true

        guard dayIndex < tripDays.count else { return }

        // Get region for this day
        guard let dayRegion = getRegionForDay(dayIndex) else { return }

        // Calculate the date for this day
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: trip.startDate) ?? trip.startDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        print("📅 [MAP] Loading Day \(dayIndex + 1) - \(dateFormatter.string(from: dayDate))")
        print("📍 [MAP] Region: \(dayRegion.name) - \(dayRegion.pointsOfInterest.count) POIs")

        // Get POIs DIRECTLY from the region (no distance filtering!)
        let dayPOIs = dayRegion.pointsOfInterest.map { poi in
            POIAnnotation(
                poi: poi,
                coordinate: CLLocationCoordinate2D(
                    latitude: poi.coordinates.latitude,
                    longitude: poi.coordinates.longitude
                )
            )
        }
        
        // Fetch weather for this day (will update floating badge)
        fetchWeatherForDay(dayIndex: dayIndex) { [weak self] weatherForecast, errorMessage in
            guard let self = self else { return }
            
            // Ensure we're on main thread for UI updates
            DispatchQueue.main.async {
            
            // Update weather badge
            self.currentDayWeather = weatherForecast
            if let weather = weatherForecast {
                let tempString = WeatherFormatter.formattedTemperature(weather.temperature, unit: self.temperatureUnit)
                self.weatherBadgeLabel.text = tempString
                
                // Update icon
                if let iconImageView = self.weatherBadgeView.viewWithTag(100) as? UIImageView {
                    iconImageView.image = UIImage(systemName: WeatherFormatter.sfSymbolName(for: weather))
                }
                
                self.weatherBadgeView.isHidden = false
            } else {
                self.weatherBadgeView.isHidden = true
            }
            
            // Calculate and update budget badge using BudgetCalculationService
            if let dayBudget = BudgetCalculationService.calculateDayBudget(for: dayIndex, in: self.trip) {
                self.currentDayBudget = dayBudget.amount
                let formattedBudget = CurrencyFormatter.formatCompact(
                    amount: dayBudget.amount,
                    currency: dayBudget.currency,
                    showSymbol: true
                )
                print("💰 [BUDGET] Showing badge: \(formattedBudget)")
                self.budgetBadgeLabel.text = formattedBudget
                self.budgetBadgeView.isHidden = false
            } else {
                print("💰 [BUDGET] No budget - hiding badge")
                self.budgetBadgeView.isHidden = true
                self.currentDayBudget = 0
            }
            
            // Clear and rebuild table items (NO weather header)
            self.tableViewItems.removeAll()
            
            // Build table view items with activities and transport between them
            for (index, poiAnnotation) in dayPOIs.enumerated() {
                let startHour = 9 + (index * 2)
                let endHour = startHour + 2

                print("   📍 POI \(index + 1): \(poiAnnotation.poi.name)")
                print("      Coords: \(poiAnnotation.coordinate.latitude), \(poiAnnotation.coordinate.longitude)")
                print("      Time: \(String(format: "%02d:00", startHour)) - \(String(format: "%02d:00", endHour))")

                // Add activity item with POI data
                self.tableViewItems.append(.activity(
                    name: poiAnnotation.poi.name,
                    startTime: String(format: "%02d:00", startHour),
                    endTime: String(format: "%02d:00", endHour),
                    coordinate: poiAnnotation.coordinate,
                    poi: poiAnnotation.poi
                ))

                // Add transport cell between activities (except after the last one)
                if index < dayPOIs.count - 1 {
                    let nextPOI = dayPOIs[index + 1]
                    self.tableViewItems.append(.transport(
                        mode: "🚶‍♂️ Walking",
                        duration: "~10 min",
                        fromCoordinate: poiAnnotation.coordinate,
                        toCoordinate: nextPOI.coordinate
                    ))
                }
            }
            
            // Show and reload table after fetching weather
            self.showDetailsTable()
            }  // End DispatchQueue.main.async
        }
    }

    private func showDetailsTable() {
        // Table now only has activities and transport (no weather header)
        detailsTableView.isHidden = tableViewItems.isEmpty
        detailsTableView.reloadData()
    }

    private enum ZoomLevel {
        case country    // Show entire trip when more than 2 regions
        case cities     // Show main cities when 2 big regions
        case local      // Show local POIs and details
    }

    private func determineZoomLevel() -> ZoomLevel {
        // Always show local level view when a specific day is selected
        // This ensures details table, POI routes, and first POI zoom work correctly
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
        // Use trip's flight data if available, otherwise infer from regions
        if !trip.flights.isEmpty {
            // Use explicit flight data from the trip
            for flight in trip.flights {
                addFlightOverlay(
                    from: flight.departureCoordinate,
                    to: flight.arrivalCoordinate,
                    type: flight.flightType,
                    label: "\(flight.departureLocation) → \(flight.arrivalLocation)"
                )
            }
            print("✈️ [MAP] Added \(trip.flights.count) flight paths from trip data")
        } else {
            // Fallback: Infer flights based on distance between regions
            inferFlightPaths()
        }
    }
    
    private func addFlightOverlay(from: Coordinate, to: Coordinate, type: FlightType, label: String) {
        let flightPath = FlightPathOverlay(
            startCoordinate: CLLocationCoordinate2D(latitude: from.latitude, longitude: from.longitude),
            endCoordinate: CLLocationCoordinate2D(latitude: to.latitude, longitude: to.longitude)
        )
        
        // Color and styling based on flight type
        let strokeColor: UIColor = (type == .international) ? .systemRed : .systemBlue
        let lineWidth: CGFloat = (type == .international) ? 4.0 : 3.0
        
        mapView.addOverlay(flightPath)
        routeOverlays.append(flightPath)
        
        let typeStr = type == .international ? "international" : "domestic"
        print("✈️ [MAP] Added \(typeStr) flight: \(label)")
    }
    
    private func inferFlightPaths() {
        // Automatically infer flight paths based on distance between regions
        // Distance thresholds (in meters):
        // > 1,000 km = International flight (red)
        // 200-1,000 km = Domestic flight (blue)
        // < 200 km = Ground route (handled separately)
        
        var allRegions: [TripRegion] = []
        
        // Collect all regions (both top-level and subregions)
        for region in trip.regions {
            if !region.subRegions.isEmpty {
                allRegions.append(contentsOf: region.subRegions)
            } else {
                allRegions.append(region)
            }
        }
        
        // Sort by arrival date to get chronological order
        allRegions.sort { $0.arrivalDate < $1.arrivalDate }
        
        // Check consecutive regions for flight-worthy distances
        for i in 0..<(allRegions.count - 1) {
            guard let fromCoords = allRegions[i].coordinates,
                  let toCoords = allRegions[i + 1].coordinates else {
                continue
            }
            
            let fromCL = CLLocationCoordinate2D(latitude: fromCoords.latitude, longitude: fromCoords.longitude)
            let toCL = CLLocationCoordinate2D(latitude: toCoords.latitude, longitude: toCoords.longitude)
            
            let distance = calculateDistance(from: fromCL, to: toCL)
            
            // Determine if this should be a flight based on distance
            if distance > 1_000_000 { // > 1,000 km = International
                addFlightOverlay(
                    from: fromCoords,
                    to: toCoords,
                    type: .international,
                    label: "\(allRegions[i].name) → \(allRegions[i + 1].name)"
                )
            } else if distance > 200_000 { // 200-1,000 km = Domestic
                addFlightOverlay(
                    from: fromCoords,
                    to: toCoords,
                    type: .domestic,
                    label: "\(allRegions[i].name) → \(allRegions[i + 1].name)"
                )
            }
            // Distances < 200km are ground routes, not shown as flights
        }
        
        print("✈️ [MAP] Inferred flight paths based on region distances")
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
    
    @objc private func weatherBadgeTapped() {
        guard let weather = currentDayWeather else { return }
        
        // Create overlay background
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.alpha = 0
        overlayView.tag = 999  // Tag to remove later
        
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissWeatherCard))
        overlayView.addGestureRecognizer(tapToDismiss)
        
        // Create weather card
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 12
        cardView.tag = 998  // Tag to remove later
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Card header
        let headerLabel = UILabel()
        headerLabel.text = "Weather Forecast"
        headerLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Grid for weather info (2x2)
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 12
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Row 1: Temperature | Feels Like
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 12
        
        row1.addArrangedSubview(createWeatherInfoView(
            icon: "thermometer",
            title: "Temperature",
            value: WeatherFormatter.formattedTemperature(weather.temperature, unit: temperatureUnit)
        ))
        row1.addArrangedSubview(createWeatherInfoView(
            icon: "thermometer.snowflake",
            title: "Feels Like",
            value: "\(Int(weather.feelsLike))°"
        ))
        
        // Row 2: Humidity | Wind
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 12
        
        row2.addArrangedSubview(createWeatherInfoView(
            icon: "humidity",
            title: "Humidity",
            value: "\(weather.humidity)%"
        ))
        row2.addArrangedSubview(createWeatherInfoView(
            icon: "wind",
            title: "Wind",
            value: "\(String(format: "%.1f", weather.windSpeed)) m/s"
        ))
        
        gridStack.addArrangedSubview(row1)
        gridStack.addArrangedSubview(row2)
        
        // Condition label
        let conditionLabel = UILabel()
        conditionLabel.text = weather.description.capitalized
        conditionLabel.font = .systemFont(ofSize: 15)
        conditionLabel.textColor = .secondaryLabel
        conditionLabel.textAlignment = .center
        conditionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(headerLabel)
        cardView.addSubview(gridStack)
        cardView.addSubview(conditionLabel)
        
        view.addSubview(overlayView)
        view.addSubview(cardView)
        
        // Layout
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320),
            
            headerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            gridStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            gridStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            gridStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            conditionLabel.topAnchor.constraint(equalTo: gridStack.bottomAnchor, constant: 16),
            conditionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            conditionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            conditionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
        
        // Animate in
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        cardView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            overlayView.alpha = 1
            cardView.alpha = 1
            cardView.transform = .identity
        }
    }
    
    private func createWeatherInfoView(icon: String, title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 80),
            
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    @objc private func dismissWeatherCard() {
        guard let overlayView = view.viewWithTag(999),
              let cardView = view.viewWithTag(998) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            overlayView.alpha = 0
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            overlayView.removeFromSuperview()
            cardView.removeFromSuperview()
        }
    }
    
    @objc private func budgetBadgeTapped() {
        guard currentDayBudget > 0 else { return }
        
        if selectedDayIndex == -1 {
            // Show total trip budget breakdown
            showTripBudgetBreakdown()
        } else {
            // Show daily budget breakdown
            showDailyBudgetBreakdown()
        }
    }
    
    private func showTripBudgetBreakdown() {
        let tripBudget = BudgetCalculationService.calculateTripBudget(for: trip)
        
        // Create overlay background
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.alpha = 0
        overlayView.tag = 997
        
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissBudgetCard))
        overlayView.addGestureRecognizer(tapToDismiss)
        
        // Create budget card
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 12
        cardView.tag = 996
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Card header
        let headerLabel = UILabel()
        headerLabel.text = "Trip Budget Breakdown"
        headerLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Total budget view
        let totalContainer = UIView()
        totalContainer.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        totalContainer.layer.cornerRadius = 12
        totalContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let totalLabel = UILabel()
        totalLabel.text = "Total Trip Budget"
        totalLabel.font = .systemFont(ofSize: 14)
        totalLabel.textColor = .secondaryLabel
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let totalAmount = UILabel()
        totalAmount.text = CurrencyFormatter.formatCompact(
            amount: tripBudget.totalAmount,
            currency: tripBudget.currency,
            showSymbol: true
        )
        totalAmount.font = .systemFont(ofSize: 22, weight: .bold)
        totalAmount.textColor = .systemGreen
        totalAmount.translatesAutoresizingMaskIntoConstraints = false
        
        // Average daily
        let avgLabel = UILabel()
        avgLabel.text = "Avg/day: \(CurrencyFormatter.formatCompact(amount: tripBudget.averageDailySpend, currency: tripBudget.currency, showSymbol: true))"
        avgLabel.font = .systemFont(ofSize: 12)
        avgLabel.textColor = .secondaryLabel
        avgLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalContainer.addSubview(totalLabel)
        totalContainer.addSubview(totalAmount)
        totalContainer.addSubview(avgLabel)
        
        // Daily breakdown list
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add each day with budget
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        for dayBudget in tripBudget.dailyBudgets {
            let dayLabel = "Day \(dayBudget.day) - \(dateFormatter.string(from: dayBudget.date))"
            let itemView = createBudgetItemView(
                name: dayLabel,
                amount: dayBudget.amount,
                currency: dayBudget.currency
            )
            stackView.addArrangedSubview(itemView)
        }
        
        // If no daily budgets, show message
        if stackView.arrangedSubviews.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No budget entries for this trip"
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            stackView.addArrangedSubview(emptyLabel)
        }
        
        scrollView.addSubview(stackView)
        
        cardView.addSubview(headerLabel)
        cardView.addSubview(totalContainer)
        cardView.addSubview(scrollView)
        
        view.addSubview(overlayView)
        view.addSubview(cardView)
        
        // Layout
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320),
            cardView.heightAnchor.constraint(lessThanOrEqualToConstant: 450),
            
            headerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            totalContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            totalContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            totalContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            totalContainer.heightAnchor.constraint(equalToConstant: 90),
            
            totalLabel.topAnchor.constraint(equalTo: totalContainer.topAnchor, constant: 12),
            totalLabel.centerXAnchor.constraint(equalTo: totalContainer.centerXAnchor),
            
            totalAmount.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 6),
            totalAmount.centerXAnchor.constraint(equalTo: totalContainer.centerXAnchor),
            
            avgLabel.topAnchor.constraint(equalTo: totalAmount.bottomAnchor, constant: 4),
            avgLabel.centerXAnchor.constraint(equalTo: totalContainer.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: totalContainer.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Animate in
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        cardView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            overlayView.alpha = 1
            cardView.alpha = 1
            cardView.transform = .identity
        }
    }
    
    private func showDailyBudgetBreakdown() {
        // Get current day's POIs and region to determine currency
        let dayPOIs = getPOIsForCurrentDay()
        guard let dayRegion = getRegionForDay(selectedDayIndex) else { return }
        
        // Currency fallback: Region → Trip base currency
        var displayCurrency = dayRegion.localCurrency.isEmpty ? trip.baseCurrency : dayRegion.localCurrency
        
        // If POIs have currency set, use that
        if let firstPOI = dayPOIs.first(where: { $0.estimatedSpending != nil }),
           let estimatedSpending = firstPOI.estimatedSpending,
           !estimatedSpending.currency.isEmpty {
            displayCurrency = estimatedSpending.currency
        }
        
        // Create overlay background
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.alpha = 0
        overlayView.tag = 997  // Tag to remove later
        
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissBudgetCard))
        overlayView.addGestureRecognizer(tapToDismiss)
        
        // Create budget card
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardView.layer.shadowRadius = 12
        cardView.tag = 996  // Tag to remove later
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Card header
        let headerLabel = UILabel()
        headerLabel.text = "Budget Breakdown"
        headerLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Total budget view
        let totalContainer = UIView()
        totalContainer.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        totalContainer.layer.cornerRadius = 12
        totalContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let totalLabel = UILabel()
        totalLabel.text = "Daily Total"
        totalLabel.font = .systemFont(ofSize: 14)
        totalLabel.textColor = .secondaryLabel
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let totalAmount = UILabel()
        totalAmount.text = CurrencyFormatter.formatCompact(amount: currentDayBudget, currency: displayCurrency, showSymbol: true)
        totalAmount.font = .systemFont(ofSize: 20, weight: .bold)
        totalAmount.textColor = .systemGreen
        totalAmount.translatesAutoresizingMaskIntoConstraints = false
        
        totalContainer.addSubview(totalLabel)
        totalContainer.addSubview(totalAmount)
        
        // Activities list
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add each POI with budget
        for poi in dayPOIs {
            guard let estimatedSpending = poi.estimatedSpending,
                  estimatedSpending.amount > 0 else { continue }
            
            // Use POI currency if set, otherwise use display currency
            let itemCurrency = estimatedSpending.currency.isEmpty ? displayCurrency : estimatedSpending.currency
            
            let itemView = createBudgetItemView(
                name: poi.name,
                amount: estimatedSpending.amount,
                currency: itemCurrency
            )
            stackView.addArrangedSubview(itemView)
        }
        
        // If no POIs with budget, show message
        if stackView.arrangedSubviews.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No itemized budget entries"
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            stackView.addArrangedSubview(emptyLabel)
        }
        
        scrollView.addSubview(stackView)
        
        cardView.addSubview(headerLabel)
        cardView.addSubview(totalContainer)
        cardView.addSubview(scrollView)
        
        view.addSubview(overlayView)
        view.addSubview(cardView)
        
        // Layout
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320),
            cardView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            headerLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            
            totalContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            totalContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            totalContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            totalContainer.heightAnchor.constraint(equalToConstant: 70),
            
            totalLabel.topAnchor.constraint(equalTo: totalContainer.topAnchor, constant: 12),
            totalLabel.centerXAnchor.constraint(equalTo: totalContainer.centerXAnchor),
            
            totalAmount.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 4),
            totalAmount.centerXAnchor.constraint(equalTo: totalContainer.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: totalContainer.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Animate in
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        cardView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            overlayView.alpha = 1
            cardView.alpha = 1
            cardView.transform = .identity
        }
    }
    
    private func createBudgetItemView(name: String, amount: Double, currency: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let amountLabel = UILabel()
        amountLabel.text = CurrencyFormatter.formatCompact(amount: amount, currency: currency, showSymbol: true)
        amountLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        amountLabel.textColor = .systemGreen
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(nameLabel)
        container.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            amountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return container
    }
    
    @objc private func dismissBudgetCard() {
        guard let overlayView = view.viewWithTag(997),
              let cardView = view.viewWithTag(996) else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            overlayView.alpha = 0
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            overlayView.removeFromSuperview()
            cardView.removeFromSuperview()
        }
    }
    
    private func getPOIsForCurrentDay() -> [PointOfInterest] {
        guard selectedDayIndex < tripDays.count else { return [] }
        
        // Get region for this day
        guard let dayRegion = getRegionForDay(selectedDayIndex) else { return [] }
        
        return dayRegion.pointsOfInterest
    }
    
    /// Get display currency with fallback chain: POI currency → Region currency → Trip base currency
    private func getDisplayCurrency(for pois: [PointOfInterest], region: TripRegion) -> String {
        // First, try to get currency from POIs
        if let firstPOI = pois.first(where: { $0.estimatedSpending != nil }),
           let estimatedSpending = firstPOI.estimatedSpending,
           !estimatedSpending.currency.isEmpty {
            return estimatedSpending.currency
        }
        
        // Fall back to region currency
        if !region.localCurrency.isEmpty {
            return region.localCurrency
        }
        
        // Finally, fall back to trip base currency
        return trip.baseCurrency
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
        // Thresholds aligned with inferFlightPaths():
        // > 1,000 km = International flight (red)
        // 200-1,000 km = Domestic flight (blue)
        // < 200 km = Ground route (not shown as flight)
        let distance = calculateDistance(from: overlay.startCoordinate, to: overlay.endCoordinate)

        if distance > 1_000_000 { // > 1,000km = International flight
            renderer.strokeColor = UIColor.systemRed
            renderer.lineWidth = 4.0
            renderer.lineDashPattern = [12, 6]
            print("✈️ [MAP] International flight path: \(Int(distance/1000))km - RED")
        } else if distance > 200_000 { // 200-1,000km = Domestic flight
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 3.0
            renderer.lineDashPattern = [8, 4]
            print("✈️ [MAP] Domestic flight path: \(Int(distance/1000))km - BLUE")
        } else { // < 200km = Regional/short flight
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

// MARK: - UIScrollViewDelegate (for day segmented control snap behavior)
extension TripMapViewController {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Only apply to day scroll view
        guard scrollView == dayScrollView else { return }
        
        // Calculate which button to snap to
        let targetX = targetContentOffset.pointee.x
        let buttonWidth: CGFloat = 70 + 12  // button width + spacing
        let index = Int((targetX + scrollView.contentInset.left) / buttonWidth + 0.5)
        let clampedIndex = max(0, min(index, dayButtons.count - 1))
        
        // Snap to button position
        let newTargetX = CGFloat(clampedIndex) * buttonWidth
        targetContentOffset.pointee.x = newTargetX
    }
}

// MARK: - UITableViewDataSource & Delegate (Day Details Table)
extension TripMapViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Guard against out-of-bounds access during async updates
        guard indexPath.row < tableViewItems.count else {
            return tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        }
        
        let item = tableViewItems[indexPath.row]

        switch item {
        case .activity(let name, let startTime, let endTime, _, let poi):
            // Use custom POI cell if we have POI data, otherwise use basic cell
            if let poi = poi {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: POIDetailCell.identifier, for: indexPath) as? POIDetailCell else {
                    return tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
                }
                cell.configure(with: poi, startTime: startTime, endTime: endTime)
                return cell
            } else {
                // Fallback to basic cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)

                cell.contentView.layer.sublayers?.removeAll(where: { $0.name == "transportBorder" })
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
            }

        case .transport(let mode, let duration, _, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransportCell", for: indexPath)

            cell.contentView.layer.sublayers?.removeAll(where: { $0.name == "transportBorder" })
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

            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: 20, y: 0, width: 2, height: 40)
            borderLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            borderLayer.name = "transportBorder"
            cell.contentView.layer.addSublayer(borderLayer)

            return cell
            
        case .weatherHeader:
            // Weather is now shown in floating badge, not in table
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Guard against out-of-bounds access during async updates
        guard indexPath.row < tableViewItems.count else {
            return 70  // Default height
        }
        
        let item = tableViewItems[indexPath.row]

        switch item {
        case .activity(_, _, _, _, let poi):
            // Use taller height for POI cells with extra info
            if let poi = poi, (!poi.tags.isEmpty || poi.rating != nil || poi.userRating != nil) {
                return 110  // Taller for POI details
            }
            return 70  // Standard activity height
        case .transport:
            return 40
        case .weatherHeader:
            return 0  // Hidden (shown in floating badge)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Guard against out-of-bounds access during async updates
        guard indexPath.row < tableViewItems.count else {
            return
        }
        
        let item = tableViewItems[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)

        switch item {
        case .weatherHeader:
            // Weather is shown in floating badge
            break
            
        case .activity(let name, _, _, let coordinate, _):
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: activityZoomRadiusMeters,
                longitudinalMeters: activityZoomRadiusMeters
            )
            mapView.setRegion(region, animated: true)
            print("[MAP] Zoomed to activity: \(name) at (\(coordinate.latitude), \(coordinate.longitude))")
            
        case .transport(_, _, let fromCoordinate, let toCoordinate):
            zoomToRoute(from: fromCoordinate, to: toCoordinate)
        }
    }
    
    private func zoomToRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let cacheKey = "\(from.latitude),\(from.longitude)-\(to.latitude),\(to.longitude)-walking"
        
        if let cachedPolyline = routeCache[cacheKey] {
            var mapRect = cachedPolyline.boundingMapRect
            let screenHeight = view.bounds.height
            let screenWidth = view.bounds.width
            let paddingTop = max(mapRect.size.height * 0.3, screenHeight * 0.15)
            let paddingBottom = max(mapRect.size.height * 0.3, screenHeight * 0.25)
            let paddingSide = max(mapRect.size.width * 0.3, screenWidth * 0.1)
            
            let padding = UIEdgeInsets(
                top: paddingTop,
                left: paddingSide,
                bottom: paddingBottom,
                right: paddingSide
            )
            mapRect = mapView.mapRectThatFits(mapRect, edgePadding: padding)
            mapView.setVisibleMapRect(mapRect, animated: true)
            print("[MAP] Zoomed to cached route using boundingMapRect")
        } else {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let route = response?.routes.first else {
                    let coordinates = [from, to]
                    let region = MKCoordinateRegion.regionThatFits(coordinates: coordinates, paddingMultiplier: self?.routeZoomPaddingMultiplier ?? 1.3)
                    self?.mapView.setRegion(region, animated: true)
                    print("[MAP] Fallback: Zoomed to straight line between points")
                    return
                }
                
                var mapRect = route.polyline.boundingMapRect
                let screenHeight = self.view.bounds.height
                let screenWidth = self.view.bounds.width
                let paddingTop = max(mapRect.size.height * 0.3, screenHeight * 0.15)
                let paddingBottom = max(mapRect.size.height * 0.3, screenHeight * 0.25)
                let paddingSide = max(mapRect.size.width * 0.3, screenWidth * 0.1)
                
                let padding = UIEdgeInsets(
                    top: paddingTop,
                    left: paddingSide,
                    bottom: paddingBottom,
                    right: paddingSide
                )
                mapRect = self.mapView.mapRectThatFits(mapRect, edgePadding: padding)
                self.mapView.setVisibleMapRect(mapRect, animated: true)
                print("[MAP] Zoomed to calculated route using boundingMapRect")
            }
        }
    }
}

// MARK: - Extension for Region Fitting
extension MKCoordinateRegion {
    static func regionThatFits(coordinates: [CLLocationCoordinate2D], paddingMultiplier: Double = 1.3) -> MKCoordinateRegion {
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
            latitudeDelta: (maxLat - minLat) * paddingMultiplier,
            longitudeDelta: (maxLon - minLon) * paddingMultiplier
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
