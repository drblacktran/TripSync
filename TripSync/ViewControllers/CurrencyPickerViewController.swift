//
//  CurrencyPickerViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit

protocol CurrencyPickerDelegate: AnyObject {
    func currencyPicker(_ picker: CurrencyPickerViewController, didSelectCurrency currency: Currency)
}

struct Currency {
    let code: String
    let name: String
    let symbol: String
    let country: String
    
    static let allCurrencies: [Currency] = [
        // Major currencies first
        Currency(code: "USD", name: "US Dollar", symbol: "$", country: "United States"),
        Currency(code: "EUR", name: "Euro", symbol: "€", country: "European Union"),
        Currency(code: "GBP", name: "British Pound", symbol: "£", country: "United Kingdom"),
        Currency(code: "JPY", name: "Japanese Yen", symbol: "¥", country: "Japan"),
        Currency(code: "AUD", name: "Australian Dollar", symbol: "A$", country: "Australia"),
        Currency(code: "CAD", name: "Canadian Dollar", symbol: "C$", country: "Canada"),
        Currency(code: "CHF", name: "Swiss Franc", symbol: "CHF", country: "Switzerland"),
        Currency(code: "CNY", name: "Chinese Yuan", symbol: "¥", country: "China"),
        Currency(code: "SEK", name: "Swedish Krona", symbol: "kr", country: "Sweden"),
        Currency(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$", country: "New Zealand"),
        
        // All currencies alphabetically
        Currency(code: "AED", name: "UAE Dirham", symbol: "د.إ", country: "United Arab Emirates"),
        Currency(code: "AFN", name: "Afghan Afghani", symbol: "؋", country: "Afghanistan"),
        Currency(code: "ALL", name: "Albanian Lek", symbol: "L", country: "Albania"),
        Currency(code: "ARS", name: "Argentine Peso", symbol: "$", country: "Argentina"),
        Currency(code: "BDT", name: "Bangladeshi Taka", symbol: "৳", country: "Bangladesh"),
        Currency(code: "BGN", name: "Bulgarian Lev", symbol: "лв", country: "Bulgaria"),
        Currency(code: "BRL", name: "Brazilian Real", symbol: "R$", country: "Brazil"),
        Currency(code: "CLP", name: "Chilean Peso", symbol: "$", country: "Chile"),
        Currency(code: "COP", name: "Colombian Peso", symbol: "$", country: "Colombia"),
        Currency(code: "CZK", name: "Czech Koruna", symbol: "Kč", country: "Czech Republic"),
        Currency(code: "DKK", name: "Danish Krone", symbol: "kr", country: "Denmark"),
        Currency(code: "DZD", name: "Algerian Dinar", symbol: "د.ج", country: "Algeria"),
        Currency(code: "EGP", name: "Egyptian Pound", symbol: "£", country: "Egypt"),
        Currency(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$", country: "Hong Kong"),
        Currency(code: "HUF", name: "Hungarian Forint", symbol: "Ft", country: "Hungary"),
        Currency(code: "IDR", name: "Indonesian Rupiah", symbol: "Rp", country: "Indonesia"),
        Currency(code: "ILS", name: "Israeli Shekel", symbol: "₪", country: "Israel"),
        Currency(code: "INR", name: "Indian Rupee", symbol: "₹", country: "India"),
        Currency(code: "ISK", name: "Icelandic Króna", symbol: "kr", country: "Iceland"),
        Currency(code: "KHR", name: "Cambodian Riel", symbol: "៛", country: "Cambodia"),
        Currency(code: "KRW", name: "South Korean Won", symbol: "₩", country: "South Korea"),
        Currency(code: "MXN", name: "Mexican Peso", symbol: "$", country: "Mexico"),
        Currency(code: "MYR", name: "Malaysian Ringgit", symbol: "RM", country: "Malaysia"),
        Currency(code: "NOK", name: "Norwegian Krone", symbol: "kr", country: "Norway"),
        Currency(code: "PHP", name: "Philippine Peso", symbol: "₱", country: "Philippines"),
        Currency(code: "PLN", name: "Polish Złoty", symbol: "zł", country: "Poland"),
        Currency(code: "RUB", name: "Russian Ruble", symbol: "₽", country: "Russia"),
        Currency(code: "SGD", name: "Singapore Dollar", symbol: "S$", country: "Singapore"),
        Currency(code: "THB", name: "Thai Baht", symbol: "฿", country: "Thailand"),
        Currency(code: "TRY", name: "Turkish Lira", symbol: "₺", country: "Turkey"),
        Currency(code: "TWD", name: "Taiwan Dollar", symbol: "NT$", country: "Taiwan"),
        Currency(code: "UAH", name: "Ukrainian Hryvnia", symbol: "₴", country: "Ukraine"),
        Currency(code: "VND", name: "Vietnamese Dong", symbol: "₫", country: "Vietnam"),
        Currency(code: "ZAR", name: "South African Rand", symbol: "R", country: "South Africa")
    ]
}

class CurrencyPickerViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Properties
    weak var delegate: CurrencyPickerDelegate?
    private var currencies: [Currency] = Currency.allCurrencies
    private var filteredCurrencies: [Currency] = []
    private var selectedCurrency: Currency?
    private var groupedCurrencies: [String: [Currency]] = [:]
    private var sectionTitles: [String] = []
    
    // MARK: - Initialization
    init(selectedCurrency: Currency? = nil) {
        self.selectedCurrency = selectedCurrency
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
        organizeData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Select Currency"
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CurrencyCell")
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionIndexMinimumDisplayRowCount = 10
        
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
        searchController.searchBar.placeholder = "Search currencies..."
        searchController.searchBar.searchBarStyle = .minimal
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func organizeData() {
        if searchController.isActive && !searchController.searchBar.text!.isEmpty {
            // Show filtered results without grouping
            sectionTitles = ["Search Results"]
            groupedCurrencies = ["Search Results": filteredCurrencies]
        } else {
            // Group currencies: Major currencies first, then alphabetical
            let majorCurrencies = Array(currencies.prefix(10)) // First 10 are major
            let otherCurrencies = Array(currencies.dropFirst(10))
            
            groupedCurrencies = [
                "Major Currencies": majorCurrencies,
                "All Currencies": otherCurrencies
            ]
            sectionTitles = ["Major Currencies", "All Currencies"]
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func selectCurrency(_ currency: Currency) {
        delegate?.currencyPicker(self, didSelectCurrency: currency)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CurrencyPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sectionTitles[section]
        return groupedCurrencies[sectionTitle]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitle = sectionTitles[section]
        let count = groupedCurrencies[sectionTitle]?.count ?? 0
        
        if sectionTitle == "Search Results" {
            return "\(count) currencies found"
        }
        return sectionTitle
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath)
        
        let sectionTitle = sectionTitles[indexPath.section]
        guard let sectionCurrencies = groupedCurrencies[sectionTitle] else { return cell }
        
        let currency = sectionCurrencies[indexPath.row]
        
        cell.textLabel?.text = "\(currency.symbol) \(currency.code)"
        cell.detailTextLabel?.text = "\(currency.name) • \(currency.country)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        
        // Show checkmark for selected currency
        if let selectedCurrency = selectedCurrency, selectedCurrency.code == currency.code {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = sectionTitles[indexPath.section]
        guard let sectionCurrencies = groupedCurrencies[sectionTitle] else { return }
        
        let currency = sectionCurrencies[indexPath.row]
        selectCurrency(currency)
    }
    
    // Section index for quick navigation
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive { return nil }
        return ["$", "A-Z"] // Major currencies ($) and All currencies (A-Z)
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
}

// MARK: - UISearchResultsUpdating
extension CurrencyPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        if searchText.isEmpty {
            filteredCurrencies = currencies
        } else {
            filteredCurrencies = currencies.filter { currency in
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.country.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        organizeData()
    }
}