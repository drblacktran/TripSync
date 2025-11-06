//
//  DiscoverViewController.swift
//  TripSync
//
//  Created by AI Assistant on 6/11/2025.
//

import UIKit

class DiscoverViewController: UIViewController {
    
    private let tableView = UITableView()
    private var sampleTrips: [Trip] = []
    private var loadingAlert: UIAlertController?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadSampleTrips()
    }
    
    private func setupUI() {
        title = "Discover"
        view.backgroundColor = UIColor.systemBackground
        
        // Add table view to the view hierarchy
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TripTableViewCell.self, forCellReuseIdentifier: TripTableViewCell.identifier)
        tableView.rowHeight = 150
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.systemGroupedBackground
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadSampleTrips() {
        // Load sample trips for discovery
        sampleTrips = Trip.createMockTrips()
        tableView.reloadData()
    }
    
    private func switchToTripsTab(trip: Trip) {
        // Switch to the Trips tab (index 0)
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = 0
            
            // Navigate to the trip detail
            if let navController = tabBarController.viewControllers?[0] as? UINavigationController,
               let tripsVC = navController.viewControllers.first as? TripListViewController {
                // Reload trips to show the new one
                tripsVC.loadTrips()
            }
        }
    }
    
    // MARK: - Loading Indicator
    private func showLoadingAlert() {
        loadingAlert = UIAlertController(title: nil, message: "Creating trip...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        if let alert = loadingAlert {
            alert.view.addSubview(loadingIndicator)
            NSLayoutConstraint.activate([
                loadingIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
                loadingIndicator.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
            ])
            present(alert, animated: true)
        }
    }
    
    private func hideLoadingAlert() {
        loadingAlert?.dismiss(animated: true)
        loadingAlert = nil
    }
    
    private func previewTrip(_ trip: Trip) {
        // Show the trip in map view (read-only preview)
        let mapVC = TripMapViewController(trip: trip)
        navigationController?.pushViewController(mapVC, animated: true)
    }
    
    private func useAsTemplate(_ trip: Trip) {
        // Create a new trip based on the template
        let daysFromNow = 3
        let duration = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 5
        let newStartDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        let newEndDate = Calendar.current.date(byAdding: .day, value: duration, to: newStartDate) ?? Date()
        
        // Create new trip with new ID
        let newTrip = Trip(
            id: UUID().uuidString,
            title: "\(trip.title) (Copy)",
            startDate: newStartDate,
            endDate: newEndDate,
            homeCountry: trip.homeCountry
        )
        
        // Copy over the trip properties manually
        var copiedTrip = newTrip
        copiedTrip.targetCountries = trip.targetCountries
        copiedTrip.isInternational = trip.isInternational
        copiedTrip.baseCurrency = trip.baseCurrency
        copiedTrip.totalBudget = trip.totalBudget
        copiedTrip.primaryTransportMode = trip.primaryTransportMode
        copiedTrip.regions = trip.regions
        copiedTrip.tags = trip.tags
        
        // Save to Firebase
        showLoadingAlert()
        
        FirebaseManager.shared.saveTrip(copiedTrip) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoadingAlert()
                
                switch result {
                case .success():
                    let successAlert = UIAlertController(
                        title: "Success!",
                        message: "'\(copiedTrip.title)' has been added to your trips!",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "View Trip", style: .default) { [weak self] _ in
                        // Switch to Trips tab and show the new trip
                        self?.switchToTripsTab(trip: copiedTrip)
                    })
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self?.present(successAlert, animated: true)
                    
                case .failure(let error):
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to save trip: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errorAlert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension DiscoverViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleTrips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TripTableViewCell.identifier, for: indexPath) as? TripTableViewCell else {
            return UITableViewCell()
        }
        
        let trip = sampleTrips[indexPath.row]
        cell.configure(with: trip)
        
        // Add "Sample" badge
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DiscoverViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let trip = sampleTrips[indexPath.row]
        
        // Show action sheet: Preview or Use as Template
        let alert = UIAlertController(
            title: trip.title,
            message: "What would you like to do with this sample trip?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Preview Trip", style: .default) { [weak self] _ in
            self?.previewTrip(trip)
        })
        
        alert.addAction(UIAlertAction(title: "Use as Template", style: .default) { [weak self] _ in
            self?.useAsTemplate(trip)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = tableView
            popoverController.sourceRect = tableView.rectForRow(at: indexPath)
        }
        
        present(alert, animated: true)
    }
}
