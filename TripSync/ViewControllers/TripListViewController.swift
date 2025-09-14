//
//  TripListViewController.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import UIKit
import CoreData

class TripListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var trips: [Trip] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTrips()
    }
    
    private func setupUI() {
        title = "My Trips"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTripTapped))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripCell")
    }
    
    @objc private func addTripTapped() {
        // TODO: Present add trip view controller
    }
    
    private func loadTrips() {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        
        do {
            trips = try CoreDataManager.shared.context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Error loading trips: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource
extension TripListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath)
        let trip = trips[indexPath.row]
        
        cell.textLabel?.text = trip.title
        cell.detailTextLabel?.text = trip.destination
        
        return cell
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