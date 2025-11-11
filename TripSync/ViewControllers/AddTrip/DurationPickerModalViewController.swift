//
//  DurationPickerModalViewController.swift
//  TripSync
//
//  Modal for selecting POI duration with preset options
//

import UIKit

protocol DurationPickerModalDelegate: AnyObject {
    func durationPickerDidSelect(_ controller: DurationPickerModalViewController, duration: TimeInterval)
    func durationPickerDidCancel(_ controller: DurationPickerModalViewController)
}

class DurationPickerModalViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: DurationPickerModalDelegate?
    
    private let poiName: String
    private var selectedDuration: TimeInterval
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let poiLabel = UILabel()
    private let presetsStackView = UIStackView()
    private let customPickerView = UIView()
    private let hourPicker = UIPickerView()
    private let minutePicker = UIPickerView()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private var isShowingCustomPicker = false
    private var selectedHours = 1
    private var selectedMinutes = 0
    
    // MARK: - Init
    
    init(poiName: String, suggestedDuration: TimeInterval) {
        self.poiName = poiName
        self.selectedDuration = suggestedDuration
        
        // Convert duration to hours/minutes
        let totalMinutes = Int(suggestedDuration / 60)
        self.selectedHours = totalMinutes / 60
        self.selectedMinutes = totalMinutes % 60
        
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
        setupUI()
        selectInitialDuration()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Container
        containerView.backgroundColor = .clear
        
        // Title
        titleLabel.text = "How long will you spend here?"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        
        // POI name
        poiLabel.text = poiName
        poiLabel.font = .systemFont(ofSize: 16)
        poiLabel.textColor = .secondaryLabel
        poiLabel.textAlignment = .center
        poiLabel.numberOfLines = 2
        
        // Presets stack
        presetsStackView.axis = .vertical
        presetsStackView.spacing = 12
        presetsStackView.distribution = .fillEqually
        
        // Add preset buttons
        for (label, seconds) in POIDurationHelper.presetDurations {
            let button = createPresetButton(label: label, duration: seconds)
            presetsStackView.addArrangedSubview(button)
        }
        
        // Custom button
        let customButton = createPresetButton(label: "Custom", duration: 0)
        customButton.tag = -1  // Special tag for custom
        presetsStackView.addArrangedSubview(customButton)
        
        // Custom picker view (initially hidden)
        customPickerView.backgroundColor = .secondarySystemBackground
        customPickerView.layer.cornerRadius = 12
        customPickerView.isHidden = true
        
        hourPicker.delegate = self
        hourPicker.dataSource = self
        hourPicker.tag = 0
        
        minutePicker.delegate = self
        minutePicker.dataSource = self
        minutePicker.tag = 1
        
        let pickerLabel = UILabel()
        pickerLabel.text = "hours           minutes"
        pickerLabel.font = .systemFont(ofSize: 14)
        pickerLabel.textColor = .secondaryLabel
        pickerLabel.textAlignment = .center
        
        customPickerView.addSubview(hourPicker)
        customPickerView.addSubview(minutePicker)
        customPickerView.addSubview(pickerLabel)
        
        // Buttons
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Add to hierarchy
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(poiLabel)
        containerView.addSubview(presetsStackView)
        containerView.addSubview(customPickerView)
        containerView.addSubview(confirmButton)
        containerView.addSubview(cancelButton)
        
        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        poiLabel.translatesAutoresizingMaskIntoConstraints = false
        presetsStackView.translatesAutoresizingMaskIntoConstraints = false
        customPickerView.translatesAutoresizingMaskIntoConstraints = false
        hourPicker.translatesAutoresizingMaskIntoConstraints = false
        minutePicker.translatesAutoresizingMaskIntoConstraints = false
        pickerLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            poiLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            poiLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            poiLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            presetsStackView.topAnchor.constraint(equalTo: poiLabel.bottomAnchor, constant: 24),
            presetsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            presetsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            presetsStackView.heightAnchor.constraint(equalToConstant: 350), // Increased from 280
            
            customPickerView.topAnchor.constraint(equalTo: presetsStackView.bottomAnchor, constant: 20),
            customPickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            customPickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            customPickerView.heightAnchor.constraint(equalToConstant: 200), // Increased from 180
            
            hourPicker.leadingAnchor.constraint(equalTo: customPickerView.leadingAnchor, constant: 40),
            hourPicker.centerYAnchor.constraint(equalTo: customPickerView.centerYAnchor),
            hourPicker.widthAnchor.constraint(equalToConstant: 80),
            
            minutePicker.trailingAnchor.constraint(equalTo: customPickerView.trailingAnchor, constant: -40),
            minutePicker.centerYAnchor.constraint(equalTo: customPickerView.centerYAnchor),
            minutePicker.widthAnchor.constraint(equalToConstant: 80),
            
            pickerLabel.centerXAnchor.constraint(equalTo: customPickerView.centerXAnchor),
            pickerLabel.bottomAnchor.constraint(equalTo: customPickerView.bottomAnchor, constant: -12),
            
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createPresetButton(label: String, duration: TimeInterval) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = Int(duration)
        button.addTarget(self, action: #selector(presetButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func selectInitialDuration() {
        // Highlight matching preset or show custom picker
        var matchedPreset = false
        
        for case let button as UIButton in presetsStackView.arrangedSubviews {
            if button.tag > 0 && TimeInterval(button.tag) == selectedDuration {
                highlightButton(button)
                matchedPreset = true
                break
            }
        }
        
        if !matchedPreset {
            // Select custom and show picker
            if let customButton = presetsStackView.arrangedSubviews.last as? UIButton {
                highlightButton(customButton)
                showCustomPicker()
            }
        }
        
        // Set picker values
        hourPicker.selectRow(selectedHours, inComponent: 0, animated: false)
        minutePicker.selectRow(selectedMinutes / 15, inComponent: 0, animated: false)
    }
    
    private func highlightButton(_ button: UIButton) {
        // Reset all buttons
        for case let btn as UIButton in presetsStackView.arrangedSubviews {
            btn.layer.borderColor = UIColor.clear.cgColor
            btn.backgroundColor = .secondarySystemBackground
        }
        
        // Highlight selected
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
    }
    
    private func showCustomPicker() {
        isShowingCustomPicker = true
        
        // Set default to 1 hour if currently 0 to prevent 0 duration
        if selectedHours == 0 && selectedMinutes == 0 {
            selectedHours = 1
            selectedMinutes = 0
            hourPicker.selectRow(1, inComponent: 0, animated: false)
            minutePicker.selectRow(0, inComponent: 0, animated: false)
            updateDurationFromPicker()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.customPickerView.isHidden = false
        }
    }
    
    private func hideCustomPicker() {
        isShowingCustomPicker = false
        
        UIView.animate(withDuration: 0.3) {
            self.customPickerView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func presetButtonTapped(_ sender: UIButton) {
        highlightButton(sender)
        
        if sender.tag == -1 {
            // Custom button
            showCustomPicker()
            updateDurationFromPicker()
        } else {
            // Preset button
            hideCustomPicker()
            selectedDuration = TimeInterval(sender.tag)
        }
    }
    
    @objc private func confirmTapped() {
        print("✅ [DURATION PICKER] Confirmed duration: \(selectedDuration) seconds (\(Int(selectedDuration / 60)) minutes)")
        delegate?.durationPickerDidSelect(self, duration: selectedDuration)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        delegate?.durationPickerDidCancel(self)
        dismiss(animated: true)
    }
    
    private func updateDurationFromPicker() {
        let hours = hourPicker.selectedRow(inComponent: 0)
        let minuteIndex = minutePicker.selectedRow(inComponent: 0)
        let minutes = minuteIndex * 15  // 0, 15, 30, 45
        
        selectedHours = hours
        selectedMinutes = minutes
        
        // Calculate duration with minimum 15 minutes validation
        let totalMinutes = hours * 60 + minutes
        let validatedMinutes = max(totalMinutes, 15)  // Minimum 15 minutes
        selectedDuration = TimeInterval(validatedMinutes * 60)
        
        print("⏱️ [DURATION PICKER] Selected: \(hours)h \(minutes)m → Total: \(totalMinutes) min → Validated: \(validatedMinutes) min (\(selectedDuration) seconds)")
    }
}

// MARK: - UIPickerViewDelegate & DataSource

extension DurationPickerModalViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            // Hours: 0-12
            return 13
        } else {
            // Minutes: 0, 15, 30, 45
            return 4
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return "\(row)"
        } else {
            return "\(row * 15)"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateDurationFromPicker()
    }
}
