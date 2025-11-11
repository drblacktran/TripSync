//
//  POIConfirmationModalViewController.swift
//  TripSync
//
//  Modal showing POI details with time slot and duration confirmation
//

import UIKit

protocol POIConfirmationModalDelegate: AnyObject {
    func poiConfirmationDidConfirm(_ controller: POIConfirmationModalViewController, poi: PointOfInterest, startTime: Date, duration: TimeInterval, estimatedBudget: Double)
    func poiConfirmationDidCancel(_ controller: POIConfirmationModalViewController)
}

class POIConfirmationModalViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: POIConfirmationModalDelegate?
    
    private let poi: PointOfInterest
    private var startTime: Date
    private var duration: TimeInterval
    private var estimatedBudget: Double = 0.0
    private let previousPOI: TimelineBlock?
    private let travelSegment: TravelSegment?
    
    // UI Components
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    private let poiImageView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let categoryBadge = UILabel()
    
    private let timeCard = UIView()
    private let timeIconLabel = UILabel()
    private let timeLabel = UILabel()
    private let timeSubLabel = UILabel()
    
    private let durationCard = UIView()
    private let durationIconLabel = UILabel()
    private let durationLabel = UILabel()
    private let changeDurationButton = UIButton(type: .system)
    
    private let budgetCard = UIView()
    private let budgetIconLabel = UILabel()
    private let budgetTextField = UITextField()
    private let budgetCurrencyLabel = UILabel()
    
    private let travelCard = UIView()
    private let travelIconLabel = UILabel()
    private let travelLabel = UILabel()
    
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Init
    
    init(poi: PointOfInterest, suggestedStartTime: Date, suggestedDuration: TimeInterval, previousPOI: TimelineBlock? = nil, travelSegment: TravelSegment? = nil) {
        self.poi = poi
        self.startTime = suggestedStartTime
        self.duration = suggestedDuration
        self.previousPOI = previousPOI
        self.travelSegment = travelSegment
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContent()
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        
        // POI Image (placeholder)
        poiImageView.contentMode = .scaleAspectFill
        poiImageView.clipsToBounds = true
        poiImageView.backgroundColor = .systemGray5
        poiImageView.layer.cornerRadius = 12
        poiImageView.image = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        poiImageView.contentMode = .center
        
        // Name
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.numberOfLines = 2
        
        // Address
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 2
        
        // Category badge
        categoryBadge.font = .systemFont(ofSize: 12, weight: .medium)
        categoryBadge.textColor = .white
        categoryBadge.backgroundColor = .systemBlue
        categoryBadge.textAlignment = .center
        categoryBadge.layer.cornerRadius = 4
        categoryBadge.clipsToBounds = true
        
        // Time card
        setupInfoCard(timeCard, icon: timeIconLabel, title: timeLabel, subtitle: timeSubLabel)
        
        // Duration card
        setupInfoCard(durationCard, icon: durationIconLabel, title: durationLabel, subtitle: nil)
        changeDurationButton.setTitle("Change", for: .normal)
        changeDurationButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        changeDurationButton.addTarget(self, action: #selector(changeDurationTapped), for: .touchUpInside)
        durationCard.addSubview(changeDurationButton)
        
        // Budget card
        budgetCard.backgroundColor = .secondarySystemBackground
        budgetCard.layer.cornerRadius = 12
        
        budgetIconLabel.text = "💰"
        budgetIconLabel.font = .systemFont(ofSize: 24)
        budgetIconLabel.textAlignment = .center
        
        budgetTextField.placeholder = "0.00"
        budgetTextField.font = .systemFont(ofSize: 16, weight: .medium)
        budgetTextField.keyboardType = .decimalPad
        budgetTextField.textAlignment = .left
        budgetTextField.addTarget(self, action: #selector(budgetTextChanged), for: .editingChanged)
        
        // Add toolbar with done button to budget text field
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        budgetTextField.inputAccessoryView = toolbar
        
        budgetCurrencyLabel.text = "VND"
        budgetCurrencyLabel.font = .systemFont(ofSize: 16)
        budgetCurrencyLabel.textColor = .secondaryLabel
        
        budgetCard.addSubview(budgetIconLabel)
        budgetCard.addSubview(budgetTextField)
        budgetCard.addSubview(budgetCurrencyLabel)
        
        // Travel card
        setupInfoCard(travelCard, icon: travelIconLabel, title: travelLabel, subtitle: nil)
        
        // Buttons
        confirmButton.setTitle("Add to Timeline", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(poiImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(addressLabel)
        containerView.addSubview(categoryBadge)
        containerView.addSubview(timeCard)
        containerView.addSubview(durationCard)
        containerView.addSubview(budgetCard)
        containerView.addSubview(travelCard)
        containerView.addSubview(confirmButton)
        containerView.addSubview(cancelButton)
        
        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        poiImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        timeCard.translatesAutoresizingMaskIntoConstraints = false
        durationCard.translatesAutoresizingMaskIntoConstraints = false
        budgetCard.translatesAutoresizingMaskIntoConstraints = false
        budgetIconLabel.translatesAutoresizingMaskIntoConstraints = false
        budgetTextField.translatesAutoresizingMaskIntoConstraints = false
        budgetCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        travelCard.translatesAutoresizingMaskIntoConstraints = false
        changeDurationButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            poiImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            poiImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            poiImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            poiImageView.heightAnchor.constraint(equalToConstant: 200),
            
            nameLabel.topAnchor.constraint(equalTo: poiImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            categoryBadge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            categoryBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            categoryBadge.heightAnchor.constraint(equalToConstant: 24),
            categoryBadge.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            addressLabel.topAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            timeCard.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 20),
            timeCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            timeCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            timeCard.heightAnchor.constraint(equalToConstant: 70),
            
            durationCard.topAnchor.constraint(equalTo: timeCard.bottomAnchor, constant: 12),
            durationCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            durationCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            durationCard.heightAnchor.constraint(equalToConstant: 70),
            
            changeDurationButton.centerYAnchor.constraint(equalTo: durationCard.centerYAnchor),
            changeDurationButton.trailingAnchor.constraint(equalTo: durationCard.trailingAnchor, constant: -16),
            
            budgetCard.topAnchor.constraint(equalTo: durationCard.bottomAnchor, constant: 12),
            budgetCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            budgetCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            budgetCard.heightAnchor.constraint(equalToConstant: 70),
            
            budgetIconLabel.leadingAnchor.constraint(equalTo: budgetCard.leadingAnchor, constant: 16),
            budgetIconLabel.centerYAnchor.constraint(equalTo: budgetCard.centerYAnchor),
            budgetIconLabel.widthAnchor.constraint(equalToConstant: 40),
            
            budgetTextField.leadingAnchor.constraint(equalTo: budgetIconLabel.trailingAnchor, constant: 12),
            budgetTextField.centerYAnchor.constraint(equalTo: budgetCard.centerYAnchor),
            budgetTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            budgetCurrencyLabel.leadingAnchor.constraint(equalTo: budgetTextField.trailingAnchor, constant: 8),
            budgetCurrencyLabel.trailingAnchor.constraint(lessThanOrEqualTo: budgetCard.trailingAnchor, constant: -16),
            budgetCurrencyLabel.centerYAnchor.constraint(equalTo: budgetCard.centerYAnchor),
            
            travelCard.topAnchor.constraint(equalTo: budgetCard.bottomAnchor, constant: 12),
            travelCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            travelCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            travelCard.heightAnchor.constraint(equalToConstant: 70),
            
            confirmButton.topAnchor.constraint(equalTo: travelCard.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupInfoCard(_ card: UIView, icon: UILabel, title: UILabel, subtitle: UILabel?) {
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        
        icon.font = .systemFont(ofSize: 24)
        icon.textAlignment = .center
        
        title.font = .systemFont(ofSize: 16, weight: .medium)
        
        if let subtitle = subtitle {
            subtitle.font = .systemFont(ofSize: 13)
            subtitle.textColor = .secondaryLabel
        }
        
        card.addSubview(icon)
        card.addSubview(title)
        if let subtitle = subtitle {
            card.addSubview(subtitle)
        }
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        subtitle?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 40),
            
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: subtitle != nil ? 14 : 24)
        ])
        
        if let subtitle = subtitle {
            NSLayoutConstraint.activate([
                subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
                subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
                subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor)
            ])
        }
    }
    
    // MARK: - Content Update
    
    private func updateContent() {
        nameLabel.text = poi.name
        addressLabel.text = poi.address
        categoryBadge.text = " \(poi.category.rawValue.capitalized) "
        
        // Time
        timeIconLabel.text = "⏰"
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let endTime = startTime.addingTimeInterval(duration)
        timeLabel.text = "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMM d"
        timeSubLabel.text = dayFormatter.string(from: startTime)
        
        // Duration
        durationIconLabel.text = "⏱️"
        let minutes = Int(duration / 60)
        if minutes < 60 {
            durationLabel.text = "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMin = minutes % 60
            if remainingMin > 0 {
                durationLabel.text = "\(hours)h \(remainingMin)m"
            } else {
                durationLabel.text = "\(hours) hour\(hours == 1 ? "" : "s")"
            }
        }
        
        // Travel
        if let travel = travelSegment, let previous = previousPOI {
            travelCard.isHidden = false
            travelIconLabel.text = travel.mode.icon
            
            let travelMinutes = Int(travel.duration / 60)
            var travelTimeStr = "\(travelMinutes) min"
            if travelMinutes >= 60 {
                let hours = travelMinutes / 60
                let mins = travelMinutes % 60
                travelTimeStr = mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
            }
            
            travelLabel.text = "\(travelTimeStr) \(travel.mode.displayName.lowercased()) from \(previous.poi.name)"
        } else {
            travelCard.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func budgetTextChanged() {
        if let text = budgetTextField.text, let value = Double(text) {
            estimatedBudget = value
        } else {
            estimatedBudget = 0.0
        }
    }
    
    @objc private func changeDurationTapped() {
        let durationPicker = DurationPickerModalViewController(poiName: poi.name, suggestedDuration: duration)
        durationPicker.delegate = self
        present(durationPicker, animated: true)
    }
    
    @objc private func confirmTapped() {
        print("✅ [POI CONFIRMATION] User confirmed POI '\(poi.name)'")
        print("   Start Time: \(startTime)")
        print("   Duration: \(duration) seconds (\(Int(duration / 60)) minutes)")
        print("   End Time: \(startTime.addingTimeInterval(duration))")
        print("   Estimated Budget: \(estimatedBudget) VND")
        delegate?.poiConfirmationDidConfirm(self, poi: poi, startTime: startTime, duration: duration, estimatedBudget: estimatedBudget)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        delegate?.poiConfirmationDidCancel(self)
        dismiss(animated: true)
    }
}

// MARK: - DurationPickerModalDelegate

extension POIConfirmationModalViewController: DurationPickerModalDelegate {
    func durationPickerDidSelect(_ controller: DurationPickerModalViewController, duration: TimeInterval) {
        print("📥 [POI CONFIRMATION] Received duration from picker: \(duration) seconds (\(Int(duration / 60)) minutes)")
        self.duration = duration
        updateContent()
    }
    
    func durationPickerDidCancel(_ controller: DurationPickerModalViewController) {
        // Do nothing
    }
}
