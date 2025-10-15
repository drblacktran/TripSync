//
//  CountryPickerViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit

protocol CountryPickerDelegate: AnyObject {
    func countryPicker(_ picker: CountryPickerViewController, didSelectCountry country: Country)
}

struct Country {
    let name: String
    let code: String
    let flag: String
    let currency: String
    let continent: String
    
    static let allCountries: [Country] = [
        // Popular countries first
        Country(name: "Australia", code: "AU", flag: "🇦🇺", currency: "AUD", continent: "Oceania"),
        Country(name: "United States", code: "US", flag: "🇺🇸", currency: "USD", continent: "North America"),
        Country(name: "United Kingdom", code: "GB", flag: "🇬🇧", currency: "GBP", continent: "Europe"),
        Country(name: "Canada", code: "CA", flag: "🇨🇦", currency: "CAD", continent: "North America"),
        Country(name: "Germany", code: "DE", flag: "🇩🇪", currency: "EUR", continent: "Europe"),
        Country(name: "France", code: "FR", flag: "🇫🇷", currency: "EUR", continent: "Europe"),
        Country(name: "Japan", code: "JP", flag: "🇯🇵", currency: "JPY", continent: "Asia"),
        Country(name: "Singapore", code: "SG", flag: "🇸🇬", currency: "SGD", continent: "Asia"),
        Country(name: "New Zealand", code: "NZ", flag: "🇳🇿", currency: "NZD", continent: "Oceania"),
        Country(name: "Switzerland", code: "CH", flag: "🇨🇭", currency: "CHF", continent: "Europe"),
        
        // All countries alphabetically
        Country(name: "Afghanistan", code: "AF", flag: "🇦🇫", currency: "AFN", continent: "Asia"),
        Country(name: "Albania", code: "AL", flag: "🇦🇱", currency: "ALL", continent: "Europe"),
        Country(name: "Algeria", code: "DZ", flag: "🇩🇿", currency: "DZD", continent: "Africa"),
        Country(name: "Argentina", code: "AR", flag: "🇦🇷", currency: "ARS", continent: "South America"),
        Country(name: "Austria", code: "AT", flag: "🇦🇹", currency: "EUR", continent: "Europe"),
        Country(name: "Bangladesh", code: "BD", flag: "🇧🇩", currency: "BDT", continent: "Asia"),
        Country(name: "Belgium", code: "BE", flag: "🇧🇪", currency: "EUR", continent: "Europe"),
        Country(name: "Brazil", code: "BR", flag: "🇧🇷", currency: "BRL", continent: "South America"),
        Country(name: "Bulgaria", code: "BG", flag: "🇧🇬", currency: "BGN", continent: "Europe"),
        Country(name: "Cambodia", code: "KH", flag: "🇰🇭", currency: "KHR", continent: "Asia"),
        Country(name: "Chile", code: "CL", flag: "🇨🇱", currency: "CLP", continent: "South America"),
        Country(name: "China", code: "CN", flag: "🇨🇳", currency: "CNY", continent: "Asia"),
        Country(name: "Colombia", code: "CO", flag: "🇨🇴", currency: "COP", continent: "South America"),
        Country(name: "Croatia", code: "HR", flag: "🇭🇷", currency: "EUR", continent: "Europe"),
        Country(name: "Czech Republic", code: "CZ", flag: "🇨🇿", currency: "CZK", continent: "Europe"),
        Country(name: "Denmark", code: "DK", flag: "🇩🇰", currency: "DKK", continent: "Europe"),
        Country(name: "Egypt", code: "EG", flag: "🇪🇬", currency: "EGP", continent: "Africa"),
        Country(name: "Finland", code: "FI", flag: "🇫🇮", currency: "EUR", continent: "Europe"),
        Country(name: "Greece", code: "GR", flag: "🇬🇷", currency: "EUR", continent: "Europe"),
        Country(name: "Hong Kong", code: "HK", flag: "🇭🇰", currency: "HKD", continent: "Asia"),
        Country(name: "Hungary", code: "HU", flag: "🇭🇺", currency: "HUF", continent: "Europe"),
        Country(name: "Iceland", code: "IS", flag: "🇮🇸", currency: "ISK", continent: "Europe"),
        Country(name: "India", code: "IN", flag: "🇮🇳", currency: "INR", continent: "Asia"),
        Country(name: "Indonesia", code: "ID", flag: "🇮🇩", currency: "IDR", continent: "Asia"),
        Country(name: "Ireland", code: "IE", flag: "🇮🇪", currency: "EUR", continent: "Europe"),
        Country(name: "Israel", code: "IL", flag: "🇮🇱", currency: "ILS", continent: "Asia"),
        Country(name: "Italy", code: "IT", flag: "🇮🇹", currency: "EUR", continent: "Europe"),
        Country(name: "Malaysia", code: "MY", flag: "🇲🇾", currency: "MYR", continent: "Asia"),
        Country(name: "Mexico", code: "MX", flag: "🇲🇽", currency: "MXN", continent: "North America"),
        Country(name: "Netherlands", code: "NL", flag: "🇳🇱", currency: "EUR", continent: "Europe"),
        Country(name: "Norway", code: "NO", flag: "🇳🇴", currency: "NOK", continent: "Europe"),
        Country(name: "Philippines", code: "PH", flag: "🇵🇭", currency: "PHP", continent: "Asia"),
        Country(name: "Poland", code: "PL", flag: "🇵🇱", currency: "PLN", continent: "Europe"),
        Country(name: "Portugal", code: "PT", flag: "🇵🇹", currency: "EUR", continent: "Europe"),
        Country(name: "Russia", code: "RU", flag: "🇷🇺", currency: "RUB", continent: "Europe"),
        Country(name: "South Africa", code: "ZA", flag: "🇿🇦", currency: "ZAR", continent: "Africa"),
        Country(name: "South Korea", code: "KR", flag: "🇰🇷", currency: "KRW", continent: "Asia"),
        Country(name: "Spain", code: "ES", flag: "🇪🇸", currency: "EUR", continent: "Europe"),
        Country(name: "Sweden", code: "SE", flag: "🇸🇪", currency: "SEK", continent: "Europe"),
        Country(name: "Taiwan", code: "TW", flag: "🇹🇼", currency: "TWD", continent: "Asia"),
        Country(name: "Thailand", code: "TH", flag: "🇹🇭", currency: "THB", continent: "Asia"),
        Country(name: "Turkey", code: "TR", flag: "🇹🇷", currency: "TRY", continent: "Asia"),
        Country(name: "Ukraine", code: "UA", flag: "🇺🇦", currency: "UAH", continent: "Europe"),
        Country(name: "United Arab Emirates", code: "AE", flag: "🇦🇪", currency: "AED", continent: "Asia"),
        Country(name: "Vietnam", code: "VN", flag: "🇻🇳", currency: "VND", continent: "Asia")
    ]
}

class CountryPickerViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Properties
    weak var delegate: CountryPickerDelegate?
    private var countries: [Country] = Country.allCountries
    private var filteredCountries: [Country] = []
    private var selectedCountry: Country?
    
    // MARK: - Initialization
    init(selectedCountry: Country? = nil) {
        self.selectedCountry = selectedCountry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchController()
        filteredCountries = countries
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Select Country"
        view.backgroundColor = UIColor.systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.keyboardDismissMode = .onDrag
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search countries..."
        searchController.searchBar.searchBarStyle = .minimal
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func selectCountry(_ country: Country) {
        delegate?.countryPicker(self, didSelectCountry: country)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCountries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath)
        let country = filteredCountries[indexPath.row]
        
        cell.textLabel?.text = "\(country.flag) \(country.name)"
        cell.detailTextLabel?.text = country.currency
        
        // Show checkmark for selected country
        if let selectedCountry = selectedCountry, selectedCountry.code == country.code {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = filteredCountries[indexPath.row]
        selectCountry(country)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && !filteredCountries.isEmpty {
            return "\(filteredCountries.count) countries found"
        } else if !searchController.isActive {
            return "\(countries.count) countries available"
        }
        return nil
    }
}

// MARK: - UISearchResultsUpdating
extension CountryPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        if searchText.isEmpty {
            filteredCountries = countries
        } else {
            filteredCountries = countries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.code.localizedCaseInsensitiveContains(searchText) ||
                country.currency.localizedCaseInsensitiveContains(searchText) ||
                country.continent.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        tableView.reloadData()
    }
}