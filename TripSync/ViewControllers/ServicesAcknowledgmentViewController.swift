//
//  ServicesAcknowledgmentViewController.swift
//  TripSync
//
//  Displays all external APIs, services, and frameworks used in the app
//

import UIKit

class ServicesAcknowledgmentViewController: UIViewController {

    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Data Model
    private var sections: [ServiceSection] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadServiceData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        title = "Services & APIs"
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServiceTableViewCell.self, forCellReuseIdentifier: ServiceTableViewCell.identifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
    }

    // MARK: - Data Loading
    private func loadServiceData() {
        sections = [
            ServiceSection(
                title: "External APIs",
                footer: "Third-party APIs used for location search, weather data, and imagery.",
                services: [
                    ServiceItem(
                        name: "Google Places API",
                        icon: "map.fill",
                        description: "Location search, autocomplete, and place details",
                        purpose: "Used for searching destinations, points of interest, and getting detailed location information",
                        tier: "Free tier: $200/month credit",
                        status: getAPIStatus(key: Constants.googlePlacesAPIKey),
                        website: "https://developers.google.com/maps/documentation/places/web-service",
                        attribution: "Powered by Google Places API"
                    ),
                    ServiceItem(
                        name: "OpenWeatherMap API",
                        icon: "cloud.sun.fill",
                        description: "5-day weather forecasts and conditions",
                        purpose: "Provides real-time weather data and forecasts for trip destinations (up to 5 days ahead)",
                        tier: "Free tier: 1,000 calls/day",
                        status: getAPIStatus(key: Constants.Weather.apiKey),
                        website: "https://openweathermap.org/api",
                        attribution: "Weather data provided by OpenWeatherMap"
                    ),
                    ServiceItem(
                        name: "Unsplash",
                        icon: "photo.fill",
                        description: "High-quality destination images",
                        purpose: "Displays beautiful photos for trip destinations on the trip list",
                        tier: "Free tier: 50 requests/hour",
                        status: .configured,
                        website: "https://unsplash.com",
                        attribution: "Photos from Unsplash"
                    ),
                    ServiceItem(
                        name: "OpenStreetMap Nominatim",
                        icon: "map.circle.fill",
                        description: "Free geocoding and reverse geocoding",
                        purpose: "Converts coordinates to addresses and searches for locations",
                        tier: "Free: 1 request/second",
                        status: .configured,
                        website: "https://nominatim.openstreetmap.org",
                        attribution: "© OpenStreetMap contributors"
                    )
                ]
            ),

            ServiceSection(
                title: "Backend Services",
                footer: "Cloud services used for authentication, data storage, and synchronization.",
                services: [
                    ServiceItem(
                        name: "Firebase Authentication",
                        icon: "lock.shield.fill",
                        description: "User authentication and session management",
                        purpose: "Handles secure user login, registration, password reset, and session management",
                        tier: "Free tier: Unlimited users",
                        status: .configured,
                        website: "https://firebase.google.com/products/auth",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Cloud Firestore",
                        icon: "icloud.fill",
                        description: "Real-time cloud database",
                        purpose: "Stores trip data, user settings, and weather cache with real-time sync across devices",
                        tier: "Free tier: 1 GiB storage, 50K reads/day",
                        status: .configured,
                        website: "https://firebase.google.com/products/firestore",
                        attribution: nil
                    )
                ]
            ),

            ServiceSection(
                title: "Apple Frameworks",
                footer: "Native iOS frameworks integrated into TripSync for enhanced functionality.",
                services: [
                    ServiceItem(
                        name: "MapKit",
                        icon: "map",
                        description: "Apple's mapping and routing framework",
                        purpose: "Displays interactive maps, POI annotations, routes between locations, and day-based trip visualization",
                        tier: "Free (native iOS framework)",
                        status: .configured,
                        website: "https://developer.apple.com/documentation/mapkit",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Core Location",
                        icon: "location.circle.fill",
                        description: "GPS and location services",
                        purpose: "Provides device location for weather forecasts, nearby search, and location-based recommendations",
                        tier: "Free (native iOS framework)",
                        status: .configured,
                        website: "https://developer.apple.com/documentation/corelocation",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Local Authentication",
                        icon: "faceid",
                        description: "Face ID and Touch ID authentication",
                        purpose: "Enables biometric login for secure and convenient app access",
                        tier: "Free (native iOS framework)",
                        status: .configured,
                        website: "https://developer.apple.com/documentation/localauthentication",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Core Data",
                        icon: "internaldrive.fill",
                        description: "Local data persistence framework",
                        purpose: "Stores trip data locally for offline access and faster app performance",
                        tier: "Free (native iOS framework)",
                        status: .configured,
                        website: "https://developer.apple.com/documentation/coredata",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Core Image",
                        icon: "qrcode",
                        description: "Image processing and QR code generation",
                        purpose: "Generates QR codes for trip sharing and processes images",
                        tier: "Free (native iOS framework)",
                        status: .planned,
                        website: "https://developer.apple.com/documentation/coreimage",
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Authentication Services",
                        icon: "key.horizontal.fill",
                        description: "Passkeys support (iOS 16+)",
                        purpose: "Enables passwordless authentication using passkeys for enhanced security",
                        tier: "Free (native iOS framework)",
                        status: .configured,
                        website: "https://developer.apple.com/documentation/authenticationservices",
                        attribution: nil
                    )
                ]
            ),

            ServiceSection(
                title: "Data Privacy & Attribution",
                footer: "TripSync respects your privacy and complies with all service provider attribution requirements.",
                services: [
                    ServiceItem(
                        name: "Privacy Policy",
                        icon: "hand.raised.fill",
                        description: "Your data is stored securely and never shared",
                        purpose: "All personal data is encrypted and stored securely. Location data is only used for trip features and weather forecasts.",
                        tier: nil,
                        status: .configured,
                        website: nil,
                        attribution: nil
                    ),
                    ServiceItem(
                        name: "Open Source Attribution",
                        icon: "doc.text.fill",
                        description: "Acknowledgment of open-source contributions",
                        purpose: "TripSync uses OpenStreetMap data, which is made available under the Open Database License (ODbL).",
                        tier: nil,
                        status: .configured,
                        website: "https://www.openstreetmap.org/copyright",
                        attribution: "© OpenStreetMap contributors"
                    )
                ]
            )
        ]

        tableView.reloadData()
    }

    // MARK: - Helper Methods
    private func getAPIStatus(key: String?) -> ServiceStatus {
        guard let key = key, !key.isEmpty, !key.contains("YOUR_API_KEY") else {
            return .notConfigured
        }
        return .configured
    }
}

// MARK: - TableView DataSource & Delegate
extension ServicesAcknowledgmentViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].services.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServiceTableViewCell.identifier, for: indexPath) as! ServiceTableViewCell
        let service = sections[indexPath.section].services[indexPath.row]
        cell.configure(with: service)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let service = sections[indexPath.section].services[indexPath.row]
        showServiceDetails(service)
    }

    private func showServiceDetails(_ service: ServiceItem) {
        let alert = UIAlertController(
            title: service.name,
            message: """
            \(service.description)

            Purpose:
            \(service.purpose)

            \(service.tier != nil ? "Tier: \(service.tier!)\n" : "")
            Status: \(service.status.displayText)
            \(service.attribution != nil ? "\n\(service.attribution!)" : "")
            """,
            preferredStyle: .alert
        )

        if let websiteURL = service.website {
            alert.addAction(UIAlertAction(title: "Learn More", style: .default) { _ in
                if let url = URL(string: websiteURL) {
                    UIApplication.shared.open(url)
                }
            })
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
}

// MARK: - Custom Cell
class ServiceTableViewCell: UITableViewCell {
    static let identifier = "ServiceTableViewCell"

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Icon
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Description
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        contentView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status badge
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(equalToConstant: 60),
            statusLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with service: ServiceItem) {
        iconImageView.image = UIImage(systemName: service.icon)
        titleLabel.text = service.name
        descriptionLabel.text = service.description

        statusLabel.text = service.status.displayText
        statusLabel.backgroundColor = service.status.backgroundColor
        statusLabel.textColor = service.status.textColor
    }
}

// MARK: - Data Models
struct ServiceSection {
    let title: String
    let footer: String?
    let services: [ServiceItem]
}

struct ServiceItem {
    let name: String
    let icon: String
    let description: String
    let purpose: String
    let tier: String?
    let status: ServiceStatus
    let website: String?
    let attribution: String?
}

enum ServiceStatus {
    case configured
    case notConfigured
    case planned

    var displayText: String {
        switch self {
        case .configured: return "Active"
        case .notConfigured: return "Not Set"
        case .planned: return "Planned"
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .configured: return .systemGreen.withAlphaComponent(0.2)
        case .notConfigured: return .systemOrange.withAlphaComponent(0.2)
        case .planned: return .systemGray.withAlphaComponent(0.2)
        }
    }

    var textColor: UIColor {
        switch self {
        case .configured: return .systemGreen
        case .notConfigured: return .systemOrange
        case .planned: return .systemGray
        }
    }
}
