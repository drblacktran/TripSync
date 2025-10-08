//
//  TripTableViewCell.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit

class TripTableViewCell: UITableViewCell {
    static let identifier = "TripTableViewCell"
    
    // MARK: - UI Elements
    private let backgroundImageView = UIImageView()
    private let overlayView = UIView()
    private let titleLabel = UILabel()
    private let destinationLabel = UILabel()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    
    // MARK: - Properties
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.image = nil
        titleLabel.text = nil
        destinationLabel.text = nil
        dateLabel.text = nil
        durationLabel.text = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        selectionStyle = .none
        
        // Background image view
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        contentView.addSubview(backgroundImageView)
        
        // Overlay for better text readability
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        contentView.addSubview(overlayView)
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        
        // Destination label
        destinationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        destinationLabel.textColor = .white
        destinationLabel.alpha = 0.9
        contentView.addSubview(destinationLabel)
        
        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .white
        dateLabel.alpha = 0.8
        contentView.addSubview(dateLabel)
        
        // Duration label
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = .white
        durationLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        durationLabel.layer.cornerRadius = 8
        durationLabel.layer.masksToBounds = true
        durationLabel.textAlignment = .center
        contentView.addSubview(durationLabel)
        
        // Disable auto-resizing masks
        [backgroundImageView, overlayView, titleLabel, destinationLabel, dateLabel, durationLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background image view
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Overlay view
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -12),
            
            // Destination label
            destinationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            destinationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            destinationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Date label
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Duration label
            durationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationLabel.widthAnchor.constraint(equalToConstant: 60),
            durationLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    func configure(with trip: Trip) {
        titleLabel.text = trip.title
        
        // Get primary destination from regions
        let primaryDestination = trip.regions.first?.name ?? trip.targetCountries.first ?? "Unknown"
        destinationLabel.text = primaryDestination
        
        // Format date range
        let startDate = dateFormatter.string(from: trip.startDate)
        let endDate = dateFormatter.string(from: trip.endDate)
        dateLabel.text = "\(startDate) - \(endDate)"
        
        // Calculate duration
        let duration = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        durationLabel.text = "\(duration + 1)d"
        
        // Load image based on destination
        loadDestinationImage(for: primaryDestination)
    }
    
    private func loadDestinationImage(for destination: String) {
        // Set a default gradient background while loading
        setGradientBackground(for: destination)
        
        // Load image from internet based on destination
        let imageURL = getImageURL(for: destination)
        loadImageFromURL(imageURL)
    }
    
    private func setGradientBackground(for destination: String) {
        // Create a gradient based on destination
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        
        // Different gradients for different destinations
        if destination.contains("Tokyo") || destination.contains("Japan") {
            gradientLayer.colors = [UIColor.systemPink.cgColor, UIColor.systemPurple.cgColor]
        } else if destination.contains("Paris") || destination.contains("France") {
            gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemIndigo.cgColor]
        } else if destination.contains("Bali") || destination.contains("Indonesia") {
            gradientLayer.colors = [UIColor.systemOrange.cgColor, UIColor.systemRed.cgColor]
        } else if destination.contains("New York") || destination.contains("USA") {
            gradientLayer.colors = [UIColor.systemGray.cgColor, UIColor.systemGray2.cgColor]
        } else if destination.contains("Melbourne") || destination.contains("Australia") {
            gradientLayer.colors = [UIColor.systemGreen.cgColor, UIColor.systemTeal.cgColor]
        } else {
            gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        }
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        backgroundImageView.layer.sublayers?.removeAll()
        backgroundImageView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func getImageURL(for destination: String) -> String {
        // Use Unsplash for high-quality destination images
        let searchQuery = destination.components(separatedBy: ",").first?.replacingOccurrences(of: " ", with: "%20") ?? "travel"
        return "https://source.unsplash.com/800x400/?\(searchQuery),landscape"
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                UIView.transition(with: self?.backgroundImageView ?? UIView(),
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    self?.backgroundImageView.image = image
                    self?.backgroundImageView.layer.sublayers?.removeAll()
                }, completion: nil)
            }
        }.resume()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame if needed
        if let gradientLayer = backgroundImageView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundImageView.bounds
        }
        
        // Add some margin around the cell
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        contentView.layer.cornerRadius = 12
    }
}