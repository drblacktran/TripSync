//
//  TripListViewController.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import UIKit
// import CoreData // Temporarily disabled

class TripListViewController: UIViewController {
    
    private let tableView = UITableView()
    var trips: [TripModel] = []
    
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
        // Load dummy data for now (will be replaced with Firebase)
        trips = TripModel.createDummyTrips()
        print("Loaded \(trips.count) dummy trips")
        tableView.reloadData()
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
        trips.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        // Show empty state if no trips left
        if trips.isEmpty {
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDelegate
extension TripListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        // TODO: Navigate to trip detail view
    }
}

// MARK: - AddTripDelegate
extension TripListViewController: AddTripDelegate {
    func didAddTrip(_ trip: TripModel) {
        trips.insert(trip, at: 0) // Add to the beginning
        
        // Animate the insertion
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()
        
        // Remove empty state if it was showing
        if trips.count == 1 {
            tableView.reloadData()
        }
        
        print("Added new trip: \(trip.title)")
    }
}