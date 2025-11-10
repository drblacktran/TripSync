//
//  CoordinatePickerTestViewController.swift
//  TripSync
//
//  Created on 7/11/2025.
//  Test view for coordinate picker - REMOVE BEFORE PRODUCTION
//

import UIKit
import CoreLocation

/// Test view controller to demo the coordinate picker
/// Add a button somewhere to present this, or call from app delegate for testing
class CoordinatePickerTestViewController: UIViewController {
    
    private var resultLabel: UILabel!
    private var testButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Coordinate Picker Test"
        view.backgroundColor = .systemBackground
        
        // Result label
        resultLabel = UILabel()
        resultLabel.text = "Tap button to test coordinate picker"
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.font = .systemFont(ofSize: 16)
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)
        
        // Test button
        testButton = UIButton(type: .system)
        testButton.setTitle("Open Coordinate Picker", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        testButton.backgroundColor = .systemBlue
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 12
        testButton.addTarget(self, action: #selector(openPickerTapped), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)
        
        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            testButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 40),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 250),
            testButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openPickerTapped() {
        let picker = CoordinatePickerViewController()
        picker.delegate = self
        
        // Test with Hanoi coordinates
        let hanoiCoordinate = CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
        picker.initialCoordinate = hanoiCoordinate
        
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }
}

extension CoordinatePickerTestViewController: CoordinatePickerDelegate {
    func coordinatePickerDidSelectLocation(
        _ picker: CoordinatePickerViewController,
        coordinate: CLLocationCoordinate2D,
        name: String,
        address: String
    ) {
        resultLabel.text = """
        ✅ Location Selected
        
        Name: \(name)
        
        Address: \(address)
        
        Coordinates:
        Lat: \(String(format: "%.6f", coordinate.latitude))
        Lon: \(String(format: "%.6f", coordinate.longitude))
        """
    }
}
