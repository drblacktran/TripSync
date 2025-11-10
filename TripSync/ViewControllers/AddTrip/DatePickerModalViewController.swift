//
//  DatePickerModalViewController.swift
//  TripSync
//
//  Modal for selecting visit date and time for a POI
//

import UIKit

protocol DatePickerModalDelegate: AnyObject {
    func datePickerDidConfirm(_ controller: DatePickerModalViewController, date: Date, time: Date)
    func datePickerDidSkip(_ controller: DatePickerModalViewController) // Add without scheduling
    func datePickerDidCancel(_ controller: DatePickerModalViewController)
}

class DatePickerModalViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: DatePickerModalDelegate?
    
    private let poiName: String
    private let poiAddress: String
    private let tripStartDate: Date
    private let tripEndDate: Date
    
    private var selectedDate: Date
    private var selectedTime: Date
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "When will you visit?"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let poiNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let poiAddressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Trip", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Without Schedule", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemOrange, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    init(poiName: String, poiAddress: String, tripStartDate: Date, tripEndDate: Date) {
        self.poiName = poiName
        self.poiAddress = poiAddress
        self.tripStartDate = tripStartDate
        self.tripEndDate = tripEndDate
        self.selectedDate = tripStartDate
        self.selectedTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupActions()
        configurePickerLimits()
        updateLabels()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(containerView)
        
        [titleLabel, poiNameLabel, poiAddressLabel, datePicker, timePicker, confirmButton, skipButton, cancelButton].forEach {
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            poiNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            poiNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            poiNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            poiAddressLabel.topAnchor.constraint(equalTo: poiNameLabel.bottomAnchor, constant: 4),
            poiAddressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            poiAddressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            datePicker.topAnchor.constraint(equalTo: poiAddressLabel.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            timePicker.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 16),
            timePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            timePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timePicker.heightAnchor.constraint(equalToConstant: 120),
            
            confirmButton.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            
            skipButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 12),
            skipButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            skipButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        timePicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
    }
    
    private func configurePickerLimits() {
        // Set date range to trip dates
        datePicker.minimumDate = tripStartDate
        datePicker.maximumDate = tripEndDate
        datePicker.date = tripStartDate
        
        // Set default time to 9:00 AM
        if let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) {
            timePicker.date = defaultTime
        }
    }
    
    private func updateLabels() {
        poiNameLabel.text = poiName
        poiAddressLabel.text = poiAddress
    }
    
    // MARK: - Actions
    
    @objc private func confirmTapped() {
        selectedDate = datePicker.date
        selectedTime = timePicker.date
        
        delegate?.datePickerDidConfirm(self, date: selectedDate, time: selectedTime)
        dismiss(animated: true)
    }
    
    @objc private func skipTapped() {
        delegate?.datePickerDidSkip(self)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        delegate?.datePickerDidCancel(self)
        dismiss(animated: true)
    }
    
    @objc private func dateChanged() {
        selectedDate = datePicker.date
    }
    
    @objc private func timeChanged() {
        selectedTime = timePicker.date
    }
}
