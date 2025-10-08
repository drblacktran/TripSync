//
//  TripDetailLayoutMockups.swift
//  TripSync - Visual Layout Mockups
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit

// MARK: - Option 1: UITableView with Custom Sections (Recommended for Timeline)
class TripDetailTableMockup: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let trip: Trip
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableMockup()
    }
    
    private func setupUI() {
        title = trip.title
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Only add close button if presented modally, otherwise use default back button
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func setupTableMockup() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Map Section (Reserved)
        let mapPlaceholder = createMapPlaceholder()
        contentView.addSubview(mapPlaceholder)
        
        // Add map constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            mapPlaceholder.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mapPlaceholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapPlaceholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapPlaceholder.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Create sections for each region/day from the trip
        let primaryRegion = trip.regions.first
        let regionName = primaryRegion?.name ?? "Unknown Region"
        let regionCountry = primaryRegion?.country ?? trip.targetCountries.first ?? "Unknown"
        
        // Day 1 Section
        let day1Section = createDaySection(title: "Day 1 - \(regionName)", region: regionName)
        contentView.addSubview(day1Section)
        
        // Day 2 Section  
        let day2Section = createDaySection(title: "Day 2 - \(regionCountry)", region: regionCountry)
        contentView.addSubview(day2Section)
        
        // Add day section constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            day1Section.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200),
            day1Section.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            day1Section.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            day1Section.heightAnchor.constraint(equalToConstant: 280),
            
            day2Section.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 500),
            day2Section.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            day2Section.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            day2Section.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // Set content height
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 800)
        ])
    }
    
    private func createMapPlaceholder() -> UIView {
        let mapView = UIView()
        mapView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        mapView.layer.cornerRadius = 12
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        let mapLabel = UILabel()
        mapLabel.text = "🗺️ \(trip.title.uppercased()) MAP\n(MapKit Integration)\n\(trip.regions.count) regions to show"
        mapLabel.textAlignment = .center
        mapLabel.numberOfLines = 0
        mapLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mapLabel.textColor = UIColor.systemBlue
        mapView.addSubview(mapLabel)
        mapLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            mapLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
        ])
        
        return mapView
    }
    
    private func createDaySection(title: String, region: String) -> UIView {
        let dayContainer = UIView()
        dayContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Day Header
        let dayHeader = createDayHeader(title: title)
        dayContainer.addSubview(dayHeader)
        
        // Timeline Container with actual trip data
        let timelineContainer = createTimelineContainer(for: region)
        dayContainer.addSubview(timelineContainer)
        
        NSLayoutConstraint.activate([
            dayHeader.topAnchor.constraint(equalTo: dayContainer.topAnchor),
            dayHeader.leadingAnchor.constraint(equalTo: dayContainer.leadingAnchor, constant: 16),
            dayHeader.trailingAnchor.constraint(equalTo: dayContainer.trailingAnchor, constant: -16),
            dayHeader.heightAnchor.constraint(equalToConstant: 40),
            
            timelineContainer.topAnchor.constraint(equalTo: dayHeader.bottomAnchor, constant: 8),
            timelineContainer.leadingAnchor.constraint(equalTo: dayContainer.leadingAnchor, constant: 16),
            timelineContainer.trailingAnchor.constraint(equalTo: dayContainer.trailingAnchor, constant: -16),
            timelineContainer.bottomAnchor.constraint(equalTo: dayContainer.bottomAnchor)
        ])
        
        return dayContainer
    }
    
    private func createDayHeader(title: String) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 8
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor.systemBlue
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16)
        ])
        
        return headerView
    }
    
    private func createTimelineContainer(for region: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Find POIs from the trip data for this region
        let regionData = trip.regions.first { $0.name.contains(region) || $0.country.contains(region) }
        let pois = regionData?.pointsOfInterest ?? []
        
        // Create POI cells from actual data or use defaults
        let poi1 = createPOICell(
            title: pois.first?.name ?? "Ben Thanh Market",
            time: "09:00",
            category: getCategoryEmoji(pois.first?.category ?? .market)
        )
        
        let transport1 = createTransportCell(mode: "🚶‍♂️ Walk", duration: "15 min")
        
        let poi2 = createPOICell(
            title: pois.count > 1 ? pois[1].name : "War Remnants Museum",
            time: "11:30",
            category: getCategoryEmoji(pois.count > 1 ? pois[1].category : .museum)
        )
        
        container.addSubview(poi1)
        container.addSubview(transport1)
        container.addSubview(poi2)
        
        NSLayoutConstraint.activate([
            poi1.topAnchor.constraint(equalTo: container.topAnchor),
            poi1.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            poi1.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            poi1.heightAnchor.constraint(equalToConstant: 70),
            
            transport1.topAnchor.constraint(equalTo: poi1.bottomAnchor, constant: 8),
            transport1.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            transport1.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            transport1.heightAnchor.constraint(equalToConstant: 40),
            
            poi2.topAnchor.constraint(equalTo: transport1.bottomAnchor, constant: 8),
            poi2.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            poi2.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            poi2.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        return container
    }
    
    private func getCategoryEmoji(_ category: POICategory) -> String {
        switch category {
        case .restaurant: return "🍽️"
        case .market: return "🏪"
        case .museum: return "🏛️"
        case .attraction: return "🎯"
        case .park: return "🌳"
        case .shopping: return "🛍️"
        case .cafe: return "☕"
        case .viewpoint: return "📸"
        case .beach: return "🏖️"
        case .cultural: return "🎭"
        case .religious: return "⛩️"
        default: return "📍"
        }
    }
    
    private func createPOICell(title: String, time: String, category: String) -> UIView {
        let cell = UIView()
        cell.backgroundColor = UIColor.secondarySystemGroupedBackground
        cell.layer.cornerRadius = 8
        cell.translatesAutoresizingMaskIntoConstraints = false
        
        let categoryLabel = UILabel()
        categoryLabel.text = category
        categoryLabel.font = UIFont.systemFont(ofSize: 24)
        cell.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = UIColor.secondaryLabel
        cell.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 16),
            
            titleLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: categoryLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return cell
    }
    
    private func createTransportCell(mode: String, duration: String) -> UIView {
        let cell = UIView()
        cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        cell.layer.cornerRadius = 6
        cell.translatesAutoresizingMaskIntoConstraints = false
        
        let modeLabel = UILabel()
        modeLabel.text = mode
        modeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        modeLabel.textColor = UIColor.systemBlue
        cell.addSubview(modeLabel)
        modeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let durationLabel = UILabel()
        durationLabel.text = duration
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = UIColor.systemBlue
        cell.addSubview(durationLabel)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            modeLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            modeLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            
            durationLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12)
        ])
        
        return cell
    }
}

// MARK: - Option 2: UICollectionView Compositional Layout (Grid-based)
class TripDetailCollectionMockup: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let trip: Trip
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionMockup()
    }
    
    private func setupUI() {
        title = "\(trip.title) - Collection Layout"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func setupCollectionMockup() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Map Section
        let mapView = createMapSection()
        contentView.addSubview(mapView)
        
        // Add map constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Collection Grid Section
        let gridSection = createGridSection()
        contentView.addSubview(gridSection)
        
        // Add grid constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            gridSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200),
            gridSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gridSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 900)
        ])
    }
    
    private func createMapSection() -> UIView {
        let mapView = UIView()
        mapView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        mapView.layer.cornerRadius = 12
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        let mapLabel = UILabel()
        mapLabel.text = "🗺️ \(trip.title.uppercased()) - GRID LAYOUT\n(Collection View with 2-column grid)\n\(trip.regions.count) regions"
        mapLabel.textAlignment = .center
        mapLabel.numberOfLines = 0
        mapLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mapLabel.textColor = UIColor.systemBlue
        mapView.addSubview(mapLabel)
        mapLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            mapLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
        ])
        
        return mapView
    }
    
    private func createGridSection() -> UIView {
        let gridContainer = UIView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Get POIs from trip data
        let allPOIs = trip.regions.flatMap { $0.pointsOfInterest }
        let samplePOIs = Array(allPOIs.prefix(6))  // Take first 6 POIs
        
        // Day Header
        let dayHeader = UIView()
        dayHeader.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        dayHeader.layer.cornerRadius = 8
        dayHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let dayLabel = UILabel()
        dayLabel.text = "Day 1 - \(trip.regions.first?.name ?? "Exploration")"
        dayLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        dayLabel.textColor = UIColor.systemBlue
        dayHeader.addSubview(dayLabel)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        gridContainer.addSubview(dayHeader)
        
        // Create 2x3 grid of POI cards
        let cardWidth = (UIScreen.main.bounds.width - 48) / 2  // 16 margin + 16 spacing + 16 margin
        var yOffset: CGFloat = 60  // After day header
        
        for row in 0..<3 {
            for col in 0..<2 {
                let index = row * 2 + col
                if index < samplePOIs.count {
                    let poi = samplePOIs[index]
                    let card = createPOICard(poi: poi, width: cardWidth)
                    gridContainer.addSubview(card)
                    
                    NSLayoutConstraint.activate([
                        card.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: yOffset),
                        card.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: 16 + CGFloat(col) * (cardWidth + 16)),
                        card.widthAnchor.constraint(equalToConstant: cardWidth),
                        card.heightAnchor.constraint(equalToConstant: 120)
                    ])
                }
            }
            yOffset += 136  // Card height + spacing
        }
        
        NSLayoutConstraint.activate([
            gridContainer.heightAnchor.constraint(equalToConstant: yOffset),
            
            dayHeader.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            dayHeader.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: 16),
            dayHeader.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor, constant: -16),
            dayHeader.heightAnchor.constraint(equalToConstant: 40),
            
            dayLabel.centerYAnchor.constraint(equalTo: dayHeader.centerYAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: dayHeader.leadingAnchor, constant: 16)
        ])
        
        return gridContainer
    }
    
    private func createPOICard(poi: PointOfInterest, width: CGFloat) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.1
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let categoryLabel = UILabel()
        categoryLabel.text = getCategoryEmoji(poi.category)
        categoryLabel.font = UIFont.systemFont(ofSize: 32)
        card.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = poi.name
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.numberOfLines = 2
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = "09:00 - 11:00"
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = UIColor.secondaryLabel
        card.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            categoryLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            
            timeLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            timeLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])
        
        return card
    }
    
    private func getCategoryEmoji(_ category: POICategory) -> String {
        switch category {
        case .restaurant: return "🍽️"
        case .market: return "🏪"
        case .museum: return "🏛️"
        case .attraction: return "🎯"
        case .park: return "🌳"
        case .shopping: return "🛍️"
        case .cafe: return "☕"
        case .viewpoint: return "📸"
        case .beach: return "🏖️"
        case .cultural: return "🎭"
        case .religious: return "⛩️"
        default: return "📍"
        }
    }
}

// MARK: - Option 3: Custom Timeline with Connecting Lines
class TripDetailTimelineMockup: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let trip: Trip
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimelineMockup()
    }
    
    private func setupUI() {
        title = "\(trip.title) - Timeline Layout"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func setupTimelineMockup() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Map Section
        let mapView = createTimelineMapSection()
        contentView.addSubview(mapView)
        
        // Add map constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // Custom Timeline
        let timeline = createCustomTimeline()
        contentView.addSubview(timeline)
        
        // Add timeline constraints after adding to hierarchy
        NSLayoutConstraint.activate([
            timeline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 200),
            timeline.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timeline.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 800)
        ])
    }
    
    private func createTimelineMapSection() -> UIView {
        let mapView = UIView()
        mapView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        mapView.layer.cornerRadius = 12
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        let mapLabel = UILabel()
        mapLabel.text = "🗺️ \(trip.title.uppercased()) - TIMELINE LAYOUT\n(Custom vertical timeline with dots)\nTotal POIs: \(trip.regions.flatMap { $0.pointsOfInterest }.count)"
        mapLabel.textAlignment = .center
        mapLabel.numberOfLines = 0
        mapLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mapLabel.textColor = UIColor.systemBlue
        mapView.addSubview(mapLabel)
        mapLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            mapLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
        ])
        
        return mapView
    }
    
    private func createCustomTimeline() -> UIView {
        let timeline = UIView()
        timeline.translatesAutoresizingMaskIntoConstraints = false
        
        // Get actual POI data from trip
        let pois = trip.regions.first?.pointsOfInterest ?? []
        let samplePOIs = Array(pois.prefix(4))  // Show first 4 POIs
        
        // Vertical timeline line
        let timelineLine = UIView()
        timelineLine.backgroundColor = UIColor.systemBlue
        timelineLine.translatesAutoresizingMaskIntoConstraints = false
        timeline.addSubview(timelineLine)
        
        var yOffset: CGFloat = 0
        
        for (index, poi) in samplePOIs.enumerated() {
            // Timeline dot
            let dot = createTimelineDot(isStart: index == 0)
            timeline.addSubview(dot)
            
            // POI content card
            let poiCard = createTimelinePOICard(poi: poi, time: "0\(9 + index * 2):00")
            timeline.addSubview(poiCard)
            
            NSLayoutConstraint.activate([
                dot.topAnchor.constraint(equalTo: timeline.topAnchor, constant: yOffset + 20),
                dot.leadingAnchor.constraint(equalTo: timeline.leadingAnchor, constant: 40),
                dot.widthAnchor.constraint(equalToConstant: 16),
                dot.heightAnchor.constraint(equalToConstant: 16),
                
                poiCard.topAnchor.constraint(equalTo: timeline.topAnchor, constant: yOffset),
                poiCard.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 16),
                poiCard.trailingAnchor.constraint(equalTo: timeline.trailingAnchor, constant: -16),
                poiCard.heightAnchor.constraint(equalToConstant: 80)
            ])
            
            yOffset += 100
            
            // Add transport connector (except for last item)
            if index < samplePOIs.count - 1 {
                let transport = createTransportConnector(mode: "🚶‍♂️", duration: "15 min")
                timeline.addSubview(transport)
                
                NSLayoutConstraint.activate([
                    transport.topAnchor.constraint(equalTo: timeline.topAnchor, constant: yOffset - 20),
                    transport.leadingAnchor.constraint(equalTo: timeline.leadingAnchor, constant: 72),
                    transport.trailingAnchor.constraint(equalTo: timeline.trailingAnchor, constant: -16),
                    transport.heightAnchor.constraint(equalToConstant: 30)
                ])
                
                yOffset += 20
            }
        }
        
        NSLayoutConstraint.activate([
            timeline.heightAnchor.constraint(equalToConstant: yOffset + 40),
            
            timelineLine.topAnchor.constraint(equalTo: timeline.topAnchor, constant: 20),
            timelineLine.bottomAnchor.constraint(equalTo: timeline.bottomAnchor, constant: -20),
            timelineLine.leadingAnchor.constraint(equalTo: timeline.leadingAnchor, constant: 47),
            timelineLine.widthAnchor.constraint(equalToConstant: 2)
        ])
        
        return timeline
    }
    
    private func createTimelineDot(isStart: Bool = false) -> UIView {
        let dot = UIView()
        dot.backgroundColor = isStart ? UIColor.systemGreen : UIColor.systemBlue
        dot.layer.cornerRadius = 8
        dot.layer.borderWidth = 3
        dot.layer.borderColor = UIColor.systemBackground.cgColor
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }
    
    private func createTimelinePOICard(poi: PointOfInterest, time: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let categoryLabel = UILabel()
        categoryLabel.text = getCategoryEmoji(poi.category)
        categoryLabel.font = UIFont.systemFont(ofSize: 24)
        card.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = poi.name
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = UIColor.secondaryLabel
        card.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: categoryLabel.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            timeLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        return card
    }
    
    private func createTransportConnector(mode: String, duration: String) -> UIView {
        let connector = UIView()
        connector.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        connector.layer.cornerRadius = 15
        connector.translatesAutoresizingMaskIntoConstraints = false
        
        let transportLabel = UILabel()
        transportLabel.text = "\(mode) \(duration)"
        transportLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        transportLabel.textColor = UIColor.systemBlue
        transportLabel.textAlignment = .center
        connector.addSubview(transportLabel)
        transportLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            transportLabel.centerYAnchor.constraint(equalTo: connector.centerYAnchor),
            transportLabel.leadingAnchor.constraint(equalTo: connector.leadingAnchor, constant: 8),
            transportLabel.trailingAnchor.constraint(equalTo: connector.trailingAnchor, constant: -8)
        ])
        
        return connector
    }
    
    private func getCategoryEmoji(_ category: POICategory) -> String {
        switch category {
        case .restaurant: return "🍽️"
        case .market: return "🏪"
        case .museum: return "🏛️"
        case .attraction: return "🎯"
        case .park: return "🌳"
        case .shopping: return "🛍️"
        case .cafe: return "☕"
        case .viewpoint: return "📸"
        case .beach: return "🏖️"
        case .cultural: return "🎭"
        case .religious: return "⛩️"
        default: return "📍"
        }
    }
}