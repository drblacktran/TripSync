//
//  AddTripViewController.swift
//  TripSync
//
//  Main entry point for creating a new trip
//

import UIKit

protocol AddTripDelegate: AnyObject {
    func didAddTrip(_ trip: Trip)
}

class AddTripViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: AddTripDelegate?
    private var selectedCountry: Country?
    
    // MARK: - Trip Builder
    
    private var tripBuilder: TripBuilder!
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Create New Trip"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let tripNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Trip Name (e.g., Vietnam Adventure)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.autocapitalizationType = .words
        return textField
    }()
    
    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date()
        return picker
    }()
    
    private let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date()
        return picker
    }()
    
    private let homeCountryTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Tap to select home country"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.text = "🇦🇺 Australia"
        textField.isUserInteractionEnabled = true
        return textField
    }()
    
    private let baseCurrencyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Currency (auto-filled)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.text = "AUD"
        textField.isEnabled = false // Read-only, auto-filled from country
        textField.textColor = .secondaryLabel
        return textField
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next: Add Destinations", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tripBuilder = TripBuilder()
        
        // Set default country (Australia)
        selectedCountry = Country.allCountries.first { $0.code == "AU" }
        
        setupUI()
        setupActions()
        setupKeyboardDismiss()
        
        // Auto-set end date to 7 days after start date
        endDatePicker.date = Calendar.current.date(byAdding: .day, value: 7, to: startDatePicker.date) ?? Date()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create labels once
        let startDateLabel = createLabel("Start Date:")
        let endDateLabel = createLabel("End Date:")
        let homeCountryLabel = createLabel("Home Country:")
        let baseCurrencyLabel = createLabel("Base Currency:")
        
        [headerLabel, tripNameTextField, startDateLabel, startDatePicker,
         endDateLabel, endDatePicker, homeCountryLabel,
         homeCountryTextField, baseCurrencyLabel, baseCurrencyTextField,
         nextButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        // Layout form fields
        var lastView: UIView = headerLabel
        let spacing: CGFloat = 12
        
        for subview in [tripNameTextField, startDateLabel, startDatePicker,
                        endDateLabel, endDatePicker, homeCountryLabel,
                        homeCountryTextField, baseCurrencyLabel, baseCurrencyTextField] {
            NSLayoutConstraint.activate([
                subview.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: spacing),
                subview.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                subview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])
            
            if let textField = subview as? UITextField {
                textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }
            
            lastView = subview
        }
        
        NSLayoutConstraint.activate([
            nextButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 32),
            nextButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        // Add tap gesture to country field
        let countryTapGesture = UITapGestureRecognizer(target: self, action: #selector(countryFieldTapped))
        homeCountryTextField.addGestureRecognizer(countryTapGesture)
    }
    
    @objc private func countryFieldTapped() {
        let countryPicker = CountryPickerViewController()
        countryPicker.delegate = self
        let nav = UINavigationController(rootViewController: countryPicker)
        present(nav, animated: true)
    }
    
    @objc private func startDateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date < startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
        endDatePicker.minimumDate = startDatePicker.date
    }
    
    @objc private func nextButtonTapped() {
        // Validate input
        guard let tripName = tripNameTextField.text, !tripName.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a trip name")
            return
        }
        
        guard let country = selectedCountry else {
            showAlert(title: "Missing Information", message: "Please select a home country")
            return
        }
        
        guard startDatePicker.date < endDatePicker.date else {
            showAlert(title: "Invalid Dates", message: "End date must be after start date")
            return
        }
        
        // Build basic trip info
        tripBuilder.setBasicInfo(
            title: tripName,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            homeCountry: country.name,
            baseCurrency: country.currency
        )
        
        // Navigate to unified search (cities and POIs together)
        let searchVC = UnifiedSearchViewController(tripBuilder: tripBuilder)
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CountryPickerDelegate

extension AddTripViewController: CountryPickerDelegate {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountry country: Country) {
        selectedCountry = country
        
        // Update UI
        homeCountryTextField.text = "\(country.flag) \(country.name)"
        baseCurrencyTextField.text = country.currency
    }
}

// MARK: - Trip Builder

class TripBuilder {
    private var title: String = ""
    var startDate: Date = Date() // Public for DatePickerModal
    var endDate: Date = Date()   // Public for DatePickerModal
    private var homeCountry: String = "Australia"
    private var baseCurrency: String = "AUD"
    private var destinations: [TripRegion] = []
    
    func setBasicInfo(title: String, startDate: Date, endDate: Date, homeCountry: String, baseCurrency: String) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.homeCountry = homeCountry
        self.baseCurrency = baseCurrency
    }
    
    func addDestination(_ region: TripRegion) {
        destinations.append(region)
    }
    
    func removeDestination(at index: Int) {
        guard index < destinations.count else { return }
        destinations.remove(at: index)
    }
    
    func getDestinations() -> [TripRegion] {
        return destinations
    }
    
    func build() -> Trip {
        var trip = Trip(
            title: title,
            startDate: startDate,
            endDate: endDate,
            homeCountry: homeCountry
        )
        
        trip.baseCurrency = baseCurrency
        trip.regions = destinations
        trip.isInternational = destinations.contains { $0.country != homeCountry }
        trip.targetCountries = Array(Set(destinations.map { $0.country }))
        
        return trip
    }
}
