//
//  DestinationSearchViewController.swift
//  TripSync
//
//  Search and add destinations using Google Places autocomplete + Vietnam provinces
//

import UIKit

class DestinationSearchViewController: UIViewController {
    
    private let tripBuilder: TripBuilder
    
    // MARK: - UI Components
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search destinations (e.g., Da Nang, Hanoi)"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(DestinationResultCell.self, forCellReuseIdentifier: "ResultCell")
        table.register(DestinationCell.self, forCellReuseIdentifier: "DestinationCell")
        table.keyboardDismissMode = .onDrag
        return table
    }()
    
    private let manualEntryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Manual Entry (from 34 provinces)", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        return button
    }()
    
    // MARK: - Data
    
    private var searchResults: [GooglePlaceResult] = []
    private var selectedDestinations: [TripRegion] = []
    private var isSearching = false
    
    // MARK: - Initialization
    
    init(tripBuilder: TripBuilder) {
        self.tripBuilder = tripBuilder
        self.selectedDestinations = tripBuilder.getDestinations()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Destinations"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupActions()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        [searchBar, tableView, manualEntryButton, nextButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            manualEntryButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            manualEntryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: manualEntryButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -12),
            
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        updateNextButton()
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        manualEntryButton.addTarget(self, action: #selector(showManualEntry), for: .touchUpInside)
    }
    
    @objc private func nextButtonTapped() {
        guard !selectedDestinations.isEmpty else {
            showAlert(title: "No Destinations", message: "Please add at least one destination")
            return
        }
        
        // Save destinations to builder
        selectedDestinations.forEach { tripBuilder.addDestination($0) }
        
        // TODO: Navigate to POI selection for first destination
        // Need to create POISearchViewController first
        /*
        if let firstDestination = selectedDestinations.first {
            let poiVC = POISearchViewController(tripBuilder: tripBuilder, region: firstDestination)
            navigationController?.pushViewController(poiVC, animated: true)
        }
        */
        
        // Temporary: Just dismiss for now
        let alert = UIAlertController(
            title: "Destinations Added",
            message: "Added \(selectedDestinations.count) destination(s). POI selection coming next!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func showManualEntry() {
        let picker = ManualProvincePickerViewController()
        picker.delegate = self
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }
    
    private func searchDestinations(query: String) {
        isSearching = true
        
        GooglePlacesService.shared.autocomplete(
            query: query,
            types: ["(cities)", "(regions)"],
            country: "vn"
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isSearching = false
                
                switch result {
                case .success(let places):
                    self.searchResults = places
                    print("✅ Found \(places.count) destinations")
                case .failure(let error):
                    print("❌ Search error: \(error)")
                    self.showAlert(title: "Search Error", message: error.localizedDescription)
                    self.searchResults = []
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    private func selectDestination(_ place: GooglePlaceResult) {
        // Get full details first
        GooglePlacesService.shared.placeDetails(placeId: place.placeId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let detailedPlace):
                    self.createRegionFromPlace(detailedPlace)
                case .failure(let error):
                    print("❌ Details error: \(error)")
                    // Fallback: use basic info
                    self.createRegionFromPlace(place)
                }
            }
        }
    }
    
    private func createRegionFromPlace(_ place: GooglePlaceResult) {
        // Match to Vietnam province
        let matchedProvince = Vietnam2025.matchToProvince(googlePlace: place)
        
        // Show date picker for this destination
        showDatePicker(for: place, province: matchedProvince)
    }
    
    private func showDatePicker(for place: GooglePlaceResult, province: ProvinceInfo?) {
        let alert = UIAlertController(
            title: "Stay Dates for \(place.name)",
            message: "When will you visit this destination?",
            preferredStyle: .alert
        )
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 200))
        datePicker.frame = container.bounds
        container.addSubview(datePicker)
        alert.view.addSubview(container)
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Create region
            var region = TripRegion(
                name: place.name,
                country: place.country ?? "Vietnam",
                arrivalDate: datePicker.date,
                departureDate: Calendar.current.date(byAdding: .day, value: 1, to: datePicker.date) ?? datePicker.date
            )
            
            region.coordinates = place.coordinates
            region.placeID = place.placeId
            region.formattedAddress = place.formattedAddress
            region.cityName = place.locality
            region.administrativeArea = place.administrativeArea
            region.countryCode = place.countryCode
            region.regionType = .city
            
            // Use province data if matched
            if let province = province {
                region.localCurrency = province.localCurrency
                region.timezone = province.timezone
                region.administrativeArea = province.name
            } else {
                region.localCurrency = "VND"
                region.timezone = "Asia/Ho_Chi_Minh"
            }
            
            self.selectedDestinations.append(region)
            self.updateNextButton()
            self.searchBar.text = ""
            self.searchResults = []
            self.tableView.reloadData()
            
            print("✅ Added destination: \(region.name)")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 350)
        alert.view.addConstraint(height)
        
        present(alert, animated: true)
    }
    
    private func updateNextButton() {
        nextButton.isEnabled = !selectedDestinations.isEmpty
        nextButton.alpha = selectedDestinations.isEmpty ? 0.5 : 1.0
        nextButton.setTitle("Continue (\(selectedDestinations.count) destinations)", for: .normal)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension DestinationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty, searchText.count >= 2 else {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        // Debounce search
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: searchBar)
        perform(#selector(performSearch), with: searchBar, afterDelay: 0.5)
    }
    
    @objc private func performSearch(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchDestinations(query: query)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension DestinationSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return selectedDestinations.count
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !selectedDestinations.isEmpty {
            return "Selected Destinations"
        } else if section == 1 && !searchResults.isEmpty {
            return "Search Results"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath) as! DestinationCell
            cell.configure(with: selectedDestinations[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! DestinationResultCell
            let place = searchResults[indexPath.row]
            let province = Vietnam2025.matchToProvince(googlePlace: place)
            cell.configure(with: place, province: province)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let place = searchResults[indexPath.row]
            selectDestination(place)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && editingStyle == .delete {
            selectedDestinations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateNextButton()
        }
    }
}

// MARK: - Manual Province Picker Delegate

extension DestinationSearchViewController: ManualProvincePickerDelegate {
    func didSelectProvince(_ province: ProvinceInfo) {
        // Create region from province
        var region = TripRegion(
            name: province.capital ?? province.name,
            country: "Vietnam",
            arrivalDate: Date(),
            departureDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        
        region.coordinates = province.coordinates
        region.localCurrency = province.localCurrency
        region.timezone = province.timezone
        region.administrativeArea = province.name
        region.countryCode = Vietnam2025.countryCode
        region.regionType = province.regionType
        
        selectedDestinations.append(region)
        updateNextButton()
        tableView.reloadData()
        
        print("✅ Added manual destination: \(region.name)")
    }
}

// MARK: - Custom Cells

class DestinationResultCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let provinceBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [titleLabel, subtitleLabel, provinceBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            provinceBadge.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            provinceBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            provinceBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            provinceBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with place: GooglePlaceResult, province: ProvinceInfo?) {
        titleLabel.text = place.name
        subtitleLabel.text = place.formattedAddress
        
        if let province = province {
            provinceBadge.text = " Province: \(province.name) "
            provinceBadge.isHidden = false
        } else {
            provinceBadge.isHidden = true
        }
    }
}

class DestinationCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [titleLabel, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with region: TripRegion) {
        titleLabel.text = "📍 \(region.name)"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = formatter.string(from: region.arrivalDate)
    }
}

// MARK: - Manual Province Picker

protocol ManualProvincePickerDelegate: AnyObject {
    func didSelectProvince(_ province: ProvinceInfo)
}

class ManualProvincePickerViewController: UIViewController {
    
    weak var delegate: ManualProvincePickerDelegate?
    
    private let tableView = UITableView()
    private let provinces = Vietnam2025.provinces.sorted { $0.name < $1.name }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select Province"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
}

extension ManualProvincePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return provinces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let province = provinces[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = province.name
        config.secondaryText = province.capital
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let province = provinces[indexPath.row]
        delegate?.didSelectProvince(province)
        dismiss(animated: true)
    }
}
