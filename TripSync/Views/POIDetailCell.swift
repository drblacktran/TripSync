//
//  POIDetailCell.swift
//  TripSync
//
//  Enhanced cell for displaying POI details with ratings, tags, and notes
//

import UIKit

class POIDetailCell: UITableViewCell {
    static let identifier = "POIDetailCell"
    
    // MARK: - UI Elements
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userRatingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let favoriteIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let notesIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "note.text")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .default
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(ratingStackView)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(favoriteIcon)
        contentView.addSubview(notesIcon)
        
        // Setup rating stack
        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(userRatingLabel)
        
        NSLayoutConstraint.activate([
            // Name label - top left
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: favoriteIcon.leadingAnchor, constant: -8),
            
            // Favorite icon - top right
            favoriteIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            favoriteIcon.trailingAnchor.constraint(lessThanOrEqualTo: notesIcon.leadingAnchor, constant: -8),
            favoriteIcon.widthAnchor.constraint(equalToConstant: 16),
            favoriteIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Notes icon - top right
            notesIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            notesIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            notesIcon.widthAnchor.constraint(equalToConstant: 16),
            notesIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Time label - second row
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Rating stack - third row
            ratingStackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            ratingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Tags label - fourth row
            tagsLabel.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 4),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with poi: PointOfInterest, startTime: String, endTime: String) {
        nameLabel.text = poi.name
        timeLabel.text = "\(startTime) - \(endTime)"
        
        // Configure ratings
        ratingLabel.isHidden = poi.rating == nil
        userRatingLabel.isHidden = poi.userRating == nil
        
        if let rating = poi.rating {
            ratingLabel.text = "⭐️ \(String(format: "%.1f", rating))"
        }
        
        if let userRating = poi.userRating {
            userRatingLabel.text = "👤 \(String(format: "%.1f", userRating))"
        }
        
        // Show/hide favorite icon
        favoriteIcon.isHidden = !poi.isFavorite
        
        // Show/hide notes icon
        notesIcon.isHidden = poi.notes.isEmpty
        
        // Configure tags
        if !poi.tags.isEmpty {
            let tagString = poi.tags.prefix(3).map { "#\($0)" }.joined(separator: " ")
            tagsLabel.text = tagString
            tagsLabel.isHidden = false
        } else {
            tagsLabel.isHidden = true
        }
        
        // Adjust layout if no tags
        if poi.tags.isEmpty {
            // No tags, so rating is last element
            ratingStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        timeLabel.text = nil
        ratingLabel.text = nil
        userRatingLabel.text = nil
        tagsLabel.text = nil
        favoriteIcon.isHidden = true
        notesIcon.isHidden = true
        tagsLabel.isHidden = false
    }
}
