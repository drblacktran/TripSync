//
//  TripListViewController.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import UIKit

class TripListViewController: UIViewController {
    
    private let tableView = UITableView()
    var trips: [Trip] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadTrips()
    }
    
    private func setupUI() {
        title = "My Trips"
        view.backgroundColor = UIColor.systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTripTapped))
        
        // Add table view to the view hierarchy
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        // Register custom cell
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
    
    @objc private func addTripTapped() {
        let addTripVC = AddTripViewController()
        addTripVC.delegate = self
        let navController = UINavigationController(rootViewController: addTripVC)
        present(navController, animated: true)
    }
    
    private func loadTrips() {
        // Show loading state
        showLoadingState()
        
        FirebaseManager.shared.fetchTrips { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoadingState()
                
                switch result {
                case .success(let fetchedTrips):
                    self?.trips = fetchedTrips
                    print("Loaded \(fetchedTrips.count) trips from Firebase")
                    self?.tableView.reloadData()
                    
                    // If no trips found, initialize with sample data for new users
                    if fetchedTrips.isEmpty {
                        self?.initializeSampleTripsForNewUser()
                    }
                    
                case .failure(let error):
                    print("Failed to load trips: \(error.localizedDescription)")
                    self?.showErrorAlert(message: "Failed to load trips: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func initializeSampleTripsForNewUser() {
        FirebaseManager.shared.initializeUserWithSampleTrips { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("Sample trips initialized for new user")
                    // Reload trips after initialization
                    self?.loadTrips()
                case .failure(let error):
                    print("Failed to initialize sample trips: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showLoadingState() {
        // You can add a loading indicator here if desired
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func hideLoadingState() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TripListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if trips.isEmpty {
            // Show empty state
            let emptyLabel = UILabel()
            emptyLabel.text = "No trips yet\nTap + to create your first trip"
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.textColor = UIColor.secondaryLabel
            emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        return trips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TripTableViewCell.identifier, for: indexPath) as? TripTableViewCell else {
            return UITableViewCell()
        }
        
        let trip = trips[indexPath.row]
        cell.configure(with: trip)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trip = trips[indexPath.row]
            
            let alert = UIAlertController(
                title: "Delete Trip",
                message: "Are you sure you want to delete '\(trip.title)'? This action cannot be undone.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteTrip(at: indexPath)
            })
            
            present(alert, animated: true)
        }
    }
    
    private func deleteTrip(at indexPath: IndexPath) {
        let trip = trips[indexPath.row]
        
        FirebaseManager.shared.deleteTrip(tripId: trip.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.trips.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    // Show empty state if no trips left
                    if self?.trips.isEmpty == true {
                        self?.tableView.reloadData()
                    }
                    
                    print("Trip deleted successfully")
                    
                case .failure(let error):
                    print("Failed to delete trip: \(error.localizedDescription)")
                    self?.showErrorAlert(message: "Failed to delete trip: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension TripListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        
        let tripDetailVC = TripDetailTableMockup(trip: trip)
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}

// MARK: - AddTripDelegate
extension TripListViewController: AddTripDelegate {
    func didAddTrip(_ trip: Trip) {
        // Save to Firebase first
        FirebaseManager.shared.saveTrip(trip) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.trips.insert(trip, at: 0) // Add to the beginning
                    
                    // Animate the insertion
                    self?.tableView.beginUpdates()
                    self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self?.tableView.endUpdates()
                    
                    // Remove empty state if it was showing
                    if self?.trips.count == 1 {
                        self?.tableView.reloadData()
                    }
                    
                    print("Added new trip: \(trip.title)")
                    
                case .failure(let error):
                    print("Failed to save trip: \(error.localizedDescription)")
                    self?.showErrorAlert(message: "Failed to save trip: \(error.localizedDescription)")
                }
            }
        }
    }
}