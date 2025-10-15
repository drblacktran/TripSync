//
//  AddTripViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit
import MapKit

protocol AddTripDelegate: AnyObject {
    func didAddTrip(_ trip: Trip)
}

class AddTripViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleTextField = UITextField()
    private let destinationTextField = UITextField()
    private let searchResultsTableView = UITableView()
    private let searchResultsContainer = UIView()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    weak var delegate: AddTripDelegate?
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var selectedLocation: CLLocationCoordinate2D?
    private var selectedLocationName: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "Add New Trip"
        
        // Add scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews
        [titleTextField, destinationTextField, searchResultsContainer, startDatePicker, endDatePicker, saveButton, cancelButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Configure text fields
        setupTextField(titleTextField, placeholder: "Trip Title", icon: "airplane")
        setupTextField(destinationTextField, placeholder: "Search destination (city, country)", icon: "location")
        destinationTextField.addTarget(self, action: #selector(destinationTextChanged), for: .editingChanged)
        
        // Setup search results
        setupSearchResults()
        
        // Configure date pickers
        startDatePicker.datePickerMode = .date
        startDatePicker.preferredDatePickerStyle = .wheels
        startDatePicker.minimumDate = Date()
        
        endDatePicker.datePickerMode = .date
        endDatePicker.preferredDatePickerStyle = .wheels
        endDatePicker.minimumDate = Date()
        
        // Configure buttons
        setupPrimaryButton(saveButton, title: "Save Trip")
        setupSecondaryButton(cancelButton, title: "Cancel")
        
        // Set default dates
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let weekLater = Calendar.current.date(byAdding: .day, value: 7, to: tomorrow) ?? Date()
        startDatePicker.date = tomorrow
        endDatePicker.date = weekLater
        
        // Add date picker labels
        addDateLabels()
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String, icon: String) {
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = UIColor.systemBackground
        
        // Add icon and padding
        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = UIColor.systemGray
        iconImageView.contentMode = .scaleAspectFit
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
        iconImageView.frame = CGRect(x: 12, y: 5, width: 20, height: 20)
        leftView.addSubview(iconImageView)
        
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 30))
        textField.rightViewMode = .always
    }
    
    private func setupPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
    }
    
    private func setupSecondaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.systemGray, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    private func addDateLabels() {
        let startDateLabel = UILabel()
        startDateLabel.text = "Start Date"
        startDateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        startDateLabel.textColor = UIColor.label
        contentView.addSubview(startDateLabel)
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let endDateLabel = UILabel()
        endDateLabel.text = "End Date"
        endDateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        endDateLabel.textColor = UIColor.label
        contentView.addSubview(endDateLabel)
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add constraints for labels
        NSLayoutConstraint.activate([
            startDateLabel.bottomAnchor.constraint(equalTo: startDatePicker.topAnchor, constant: -8),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            endDateLabel.bottomAnchor.constraint(equalTo: endDatePicker.topAnchor, constant: -8),
            endDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title text field
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Destination text field
            destinationTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            destinationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            destinationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            destinationTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Search results container
            searchResultsContainer.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 4),
            searchResultsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            searchResultsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            searchResultsContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // Start date picker
            startDatePicker.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 60),
            startDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            startDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // End date picker
            endDatePicker.topAnchor.constraint(equalTo: startDatePicker.bottomAnchor, constant: 40),
            endDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            endDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Save button
            saveButton.topAnchor.constraint(equalTo: endDatePicker.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
    }
    
    private func setupSearchResults() {
        // Configure search completer
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -25.2744, longitude: 133.7751), // Australia center
            latitudinalMeters: 10000000,
            longitudinalMeters: 10000000
        )
        
        // Configure search results container
        searchResultsContainer.backgroundColor = UIColor.systemBackground
        searchResultsContainer.layer.cornerRadius = 8
        searchResultsContainer.layer.borderWidth = 1
        searchResultsContainer.layer.borderColor = UIColor.systemGray4.cgColor
        searchResultsContainer.isHidden = true
        
        // Configure search results table view
        searchResultsContainer.addSubview(searchResultsTableView)
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.register(LocationSearchCell.self, forCellReuseIdentifier: "LocationCell")
        searchResultsTableView.backgroundColor = UIColor.clear
        searchResultsTableView.separatorStyle = .none
        
        NSLayoutConstraint.activate([
            searchResultsTableView.topAnchor.constraint(equalTo: searchResultsContainer.topAnchor),
            searchResultsTableView.leadingAnchor.constraint(equalTo: searchResultsContainer.leadingAnchor),
            searchResultsTableView.trailingAnchor.constraint(equalTo: searchResultsContainer.trailingAnchor),
            searchResultsTableView.bottomAnchor.constraint(equalTo: searchResultsContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let destination = destinationTextField.text, !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill in both title and destination.")
            return
        }
        
        // Validate dates
        if endDatePicker.date <= startDatePicker.date {
            showAlert(title: "Invalid Dates", message: "End date must be after start date.")
            return
        }
        
        // Create new trip
        var newTrip = Trip(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            homeCountry: "Australia"
        )
        
        // Determine if international and set transport mode
        let destinationCountry = extractCountryFromDestination(destination.trimmingCharacters(in: .whitespacesAndNewlines))
        newTrip.targetCountries = [destinationCountry]
        newTrip.isInternational = (destinationCountry != newTrip.homeCountry)
        newTrip.primaryTransportMode = newTrip.isInternational ? .flight : .car
        
        // Create primary region
        let primaryRegion = TripRegion(
            id: UUID().uuidString,
            name: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            country: destinationCountry,
            arrivalDate: startDatePicker.date,
            departureDate: endDatePicker.date
        )
        
        newTrip.regions = [primaryRegion]
        
        // Notify delegate
        delegate?.didAddTrip(newTrip)
        
        // Dismiss
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func startDateChanged() {
        // Update minimum end date to be after start date
        endDatePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date)
        
        // If end date is now before start date, update it
        if endDatePicker.date <= startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
    }
    
    @objc private func destinationTextChanged() {
        guard let query = destinationTextField.text, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            hideSearchResults()
            return
        }
        
        searchCompleter.queryFragment = query
    }
    
    private func showSearchResults() {
        searchResultsContainer.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideSearchResults() {
        searchResultsContainer.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Helper Methods
    private func extractCountryFromDestination(_ destination: String) -> String {
        // Simple logic to extract country from destination string
        // In a real app, this would use geocoding APIs
        let countryMappings = [
            "tokyo": "Japan",
            "japan": "Japan",
            "kyoto": "Japan",
            "osaka": "Japan",
            "paris": "France",
            "france": "France",
            "london": "United Kingdom",
            "uk": "United Kingdom",
            "england": "United Kingdom",
            "new york": "United States",
            "usa": "United States",
            "america": "United States",
            "vietnam": "Vietnam",
            "ho chi minh": "Vietnam",
            "hanoi": "Vietnam",
            "saigon": "Vietnam",
            "bali": "Indonesia",
            "indonesia": "Indonesia",
            "jakarta": "Indonesia",
            "singapore": "Singapore",
            "melbourne": "Australia",
            "sydney": "Australia",
            "brisbane": "Australia",
            "perth": "Australia",
            "adelaide": "Australia",
            "australia": "Australia"
        ]
        
        let lowercased = destination.lowercased()
        for (key, country) in countryMappings {
            if lowercased.contains(key) {
                return country
            }
        }
        
        // Default to the destination as country if not found
        return destination
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddTripViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
        
        if !searchResults.isEmpty {
            showSearchResults()
        } else {
            hideSearchResults()
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed with error: \(error.localizedDescription)")
        hideSearchResults()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension AddTripViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationSearchCell
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedResult = searchResults[indexPath.row]
        destinationTextField.text = selectedResult.title
        selectedLocationName = selectedResult.title
        
        // Perform search to get coordinates
        let searchRequest = MKLocalSearch.Request(completion: selectedResult)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            if let response = response, let mapItem = response.mapItems.first {
                self?.selectedLocation = mapItem.placemark.coordinate
                print("Selected location: \(selectedResult.title) at \(mapItem.placemark.coordinate)")
            }
        }
        
        hideSearchResults()
        destinationTextField.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - LocationSearchCell
class LocationSearchCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        
        iconImageView.image = UIImage(systemName: "location.fill")
        iconImageView.tintColor = UIColor.systemBlue
        iconImageView.contentMode = .scaleAspectFit
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.label
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        
        [iconImageView, titleLabel, subtitleLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with completion: MKLocalSearchCompletion) {
        titleLabel.text = completion.title
        subtitleLabel.text = completion.subtitle
    }
}