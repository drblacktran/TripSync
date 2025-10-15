//
//  TripDetailCells.swift
//  TripSync
//
//  Created by Tien Tran on 9/10/2025.
//

import UIKit

// MARK: - Protocols for Cell Delegates
protocol TripOverviewCellDelegate: AnyObject {
    func didUpdateTripTitle(_ title: String)
    func didUpdateTripDates(startDate: Date, endDate: Date)
    func didUpdateTripBudget(_ budget: Double?)
}

protocol POIActivityCellDelegate: AnyObject {
    func didUpdatePOITime(_ poi: PointOfInterest, newTime: String)
    func didTogglePOICompleted(_ poi: PointOfInterest, completed: Bool)
    func didRequestPOIEdit(_ poi: PointOfInterest)
}

protocol BudgetCellDelegate: AnyObject {
    func didUpdateBudgetAmount(_ amount: Double, forRow row: Int)
    func didRequestAddExpense()
}

protocol DocumentCellDelegate: AnyObject {
    func didRequestDocumentView(_ document: TripDocument)
    func didRequestDocumentDelete(_ document: TripDocument)
    func didRequestAddDocument()
}

// MARK: - Trip Map Cell
class TripMapTableViewCell: UITableViewCell {
    static let identifier = "TripMapTableViewCell"

    private let mapPlaceholderView = UIView()
    private let mapLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        mapPlaceholderView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        mapPlaceholderView.layer.cornerRadius = 12
        mapPlaceholderView.translatesAutoresizingMaskIntoConstraints = false

        mapLabel.textAlignment = .center
        mapLabel.numberOfLines = 0
        mapLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mapLabel.textColor = UIColor.systemBlue
        mapLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mapPlaceholderView)
        mapPlaceholderView.addSubview(mapLabel)

        NSLayoutConstraint.activate([
            mapPlaceholderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mapPlaceholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapPlaceholderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapPlaceholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            mapLabel.centerXAnchor.constraint(equalTo: mapPlaceholderView.centerXAnchor),
            mapLabel.centerYAnchor.constraint(equalTo: mapPlaceholderView.centerYAnchor),
            mapLabel.leadingAnchor.constraint(greaterThanOrEqualTo: mapPlaceholderView.leadingAnchor, constant: 16),
            mapLabel.trailingAnchor.constraint(lessThanOrEqualTo: mapPlaceholderView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with trip: Trip) {
        let regionCount = trip.regions.count
        let poiCount = trip.regions.flatMap { $0.pointsOfInterest }.count

        mapLabel.text = "🗺️ \(trip.title.uppercased())\n\(regionCount) regions • \(poiCount) places\n(MapKit Integration - TODO)"
    }
}

// MARK: - Trip Overview Cell
class TripOverviewTableViewCell: UITableViewCell {
    static let identifier = "TripOverviewTableViewCell"

    weak var delegate: TripOverviewCellDelegate?

    private let titleTextField = UITextField()
    private let datesLabel = UILabel()
    private let budgetTextField = UITextField()
    private let durationLabel = UILabel()
    private let destinationLabel = UILabel()

    private var trip: Trip?
    private var isEditMode = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        // Title field
        titleTextField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleTextField.borderStyle = .none
        titleTextField.isEnabled = false
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        // Dates label
        datesLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        datesLabel.textColor = .systemBlue

        // Budget field
        budgetTextField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        budgetTextField.borderStyle = .none
        budgetTextField.isEnabled = false
        budgetTextField.placeholder = "Set budget..."
        budgetTextField.keyboardType = .decimalPad
        budgetTextField.addTarget(self, action: #selector(budgetChanged), for: .editingChanged)

        // Duration label
        durationLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        durationLabel.textColor = .secondaryLabel

        // Destination label
        destinationLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        destinationLabel.textColor = .secondaryLabel
        destinationLabel.numberOfLines = 2

        let stackView = UIStackView(arrangedSubviews: [
            titleTextField,
            datesLabel,
            createHorizontalStack(left: destinationLabel, right: durationLabel),
            budgetTextField
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    private func createHorizontalStack(left: UIView, right: UIView) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [left, right])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }

    func configure(with trip: Trip, isEditMode: Bool) {
        self.trip = trip
        self.isEditMode = isEditMode

        titleTextField.text = trip.title
        titleTextField.isEnabled = isEditMode
        titleTextField.backgroundColor = isEditMode ? .systemGray6 : .clear

        budgetTextField.text = trip.totalBudget != nil ? String(format: "%.0f %@", trip.totalBudget!, trip.baseCurrency) : ""
        budgetTextField.isEnabled = isEditMode
        budgetTextField.backgroundColor = isEditMode ? .systemGray6 : .clear

        // Format dates
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        datesLabel.text = "\(formatter.string(from: trip.startDate)) → \(formatter.string(from: trip.endDate))"

        // Calculate duration
        let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        durationLabel.text = "\(days) days"

        // Destination
        destinationLabel.text = trip.targetCountries.joined(separator: ", ")
    }

    @objc private func titleChanged() {
        guard let title = titleTextField.text, !title.isEmpty else { return }
        delegate?.didUpdateTripTitle(title)
    }

    @objc private func budgetChanged() {
        guard let text = budgetTextField.text, !text.isEmpty else {
            delegate?.didUpdateTripBudget(nil)
            return
        }

        if let budget = Double(text) {
            delegate?.didUpdateTripBudget(budget)
        }
    }
}

// MARK: - Daily Schedule Header Cell
class DailyScheduleTableViewCell: UITableViewCell {
    static let identifier = "DailyScheduleTableViewCell"

    private let dayLabel = UILabel()
    private let dateLabel = UILabel()
    private let summaryLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)

        dayLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        dayLabel.textColor = .systemBlue

        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = .systemBlue

        summaryLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        summaryLabel.textColor = .systemBlue

        let stackView = UIStackView(arrangedSubviews: [dayLabel, dateLabel, summaryLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(withDay day: Int, date: Date, trip: Trip) {
        dayLabel.text = "Day \(day)"

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        dateLabel.text = formatter.string(from: date)

        // Get region for this day (simplified)
        let regionName = trip.regions.first?.subRegions.first?.name ?? trip.regions.first?.name ?? "Exploring"
        summaryLabel.text = regionName
    }
}

// MARK: - POI Activity Cell
class POIActivityTableViewCell: UITableViewCell {
    static let identifier = "POIActivityTableViewCell"

    weak var delegate: POIActivityCellDelegate?

    private let categoryLabel = UILabel()
    private let nameLabel = UILabel()
    private let timeTextField = UITextField()
    private let durationLabel = UILabel()
    private let completedButton = UIButton()

    private var poi: PointOfInterest?
    private var isEditMode = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .gray

        categoryLabel.font = UIFont.systemFont(ofSize: 24)

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.numberOfLines = 2

        timeTextField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeTextField.textColor = .systemBlue
        timeTextField.borderStyle = .none
        timeTextField.textAlignment = .center
        timeTextField.addTarget(self, action: #selector(timeChanged), for: .editingChanged)

        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = .secondaryLabel

        completedButton.setTitle("", for: .normal)
        completedButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        completedButton.addTarget(self, action: #selector(completedTapped), for: .touchUpInside)

        // Layout
        let leftStack = UIStackView(arrangedSubviews: [categoryLabel])
        leftStack.axis = .vertical
        leftStack.alignment = .center

        let centerStack = UIStackView(arrangedSubviews: [nameLabel, durationLabel])
        centerStack.axis = .vertical
        centerStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [timeTextField, completedButton])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [leftStack, centerStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            leftStack.widthAnchor.constraint(equalToConstant: 40),
            rightStack.widthAnchor.constraint(equalToConstant: 80),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with poi: PointOfInterest, timeSlot: String, isEditMode: Bool) {
        self.poi = poi
        self.isEditMode = isEditMode

        categoryLabel.text = getCategoryEmoji(poi.category)
        nameLabel.text = poi.name

        let hours = Int(poi.estimatedDuration / 3600)
        let minutes = Int((poi.estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            durationLabel.text = "\(hours)h \(minutes)m"
        } else {
            durationLabel.text = "\(minutes) min"
        }

        timeTextField.text = timeSlot
        timeTextField.isEnabled = isEditMode
        timeTextField.backgroundColor = isEditMode ? .systemGray6 : .clear

        // Completed status (simplified - using visitedDate as indicator)
        let isCompleted = poi.visitedDate != nil
        completedButton.setTitle(isCompleted ? "✅" : "⭕", for: .normal)
        completedButton.isEnabled = true // Always allow toggling completion
    }

    private func getCategoryEmoji(_ category: POICategory) -> String {
        switch category {
        case .restaurant: return "🍽️"
        case .market: return "🏪"
        case .museum: return "🏛️"
        case .attraction: return "🎯"
        case .park: return "🌳"
        case .shopping: return "🛍️"
        case .cafe: return "☕"
        case .viewpoint: return "📸"
        case .beach: return "🏖️"
        case .cultural: return "🎭"
        case .religious: return "⛩️"
        default: return "📍"
        }
    }

    @objc private func timeChanged() {
        guard let poi = poi, let time = timeTextField.text else { return }
        delegate?.didUpdatePOITime(poi, newTime: time)
    }

    @objc private func completedTapped() {
        guard let poi = poi else { return }
        let isCurrentlyCompleted = poi.visitedDate != nil
        delegate?.didTogglePOICompleted(poi, completed: !isCurrentlyCompleted)

        // Update UI immediately
        completedButton.setTitle(!isCurrentlyCompleted ? "✅" : "⭕", for: .normal)
    }
}

// MARK: - Budget Cell
class BudgetTableViewCell: UITableViewCell {
    static let identifier = "BudgetTableViewCell"

    weak var delegate: BudgetCellDelegate?

    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let amountTextField = UITextField()

    private var rowType: Int = 0
    private var isEditMode = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        amountLabel.textAlignment = .right

        amountTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        amountTextField.textAlignment = .right
        amountTextField.borderStyle = .none
        amountTextField.keyboardType = .decimalPad
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, amountLabel, amountTextField])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with trip: Trip, rowType: Int, isEditMode: Bool) {
        self.rowType = rowType
        self.isEditMode = isEditMode

        switch rowType {
        case 0: // Total Budget
            titleLabel.text = "Total Budget"
            let budgetText = trip.totalBudget != nil ? String(format: "%.0f %@", trip.totalBudget!, trip.baseCurrency) : "Not set"
            amountLabel.text = budgetText
            amountTextField.text = trip.totalBudget != nil ? String(format: "%.0f", trip.totalBudget!) : ""
            amountTextField.placeholder = "Enter budget..."

        case 1: // Actual Spent
            titleLabel.text = "Actual Spent"
            amountLabel.text = String(format: "%.2f %@", trip.actualSpent, trip.baseCurrency)
            amountTextField.text = String(format: "%.2f", trip.actualSpent)
            amountTextField.placeholder = "Enter amount..."

        case 2: // Remaining
            titleLabel.text = "Remaining"
            let remaining = (trip.totalBudget ?? 0) - trip.actualSpent
            let remainingText = String(format: "%.2f %@", remaining, trip.baseCurrency)
            amountLabel.text = remaining >= 0 ? remainingText : remainingText
            amountLabel.textColor = remaining >= 0 ? .systemGreen : .systemRed
            amountTextField.isHidden = true // Can't edit calculated field

        default:
            break
        }

        amountLabel.isHidden = isEditMode && rowType != 2
        amountTextField.isHidden = !isEditMode || rowType == 2
        amountTextField.backgroundColor = isEditMode ? .systemGray6 : .clear
    }

    @objc private func amountChanged() {
        guard let text = amountTextField.text, let amount = Double(text) else { return }
        delegate?.didUpdateBudgetAmount(amount, forRow: rowType)
    }
}

// MARK: - Document Cell
class DocumentTableViewCell: UITableViewCell {
    static let identifier = "DocumentTableViewCell"

    weak var delegate: DocumentCellDelegate?

    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton()

    private var document: TripDocument?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .gray

        iconLabel.font = UIFont.systemFont(ofSize: 24)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let mainStack = UIStackView(arrangedSubviews: [iconLabel, textStack, actionButton])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            iconLabel.widthAnchor.constraint(equalToConstant: 40),
            actionButton.widthAnchor.constraint(equalToConstant: 60),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with document: TripDocument, isEditMode: Bool) {
        self.document = document

        iconLabel.text = getDocumentIcon(document.type)
        titleLabel.text = document.title

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        subtitleLabel.text = formatter.string(from: document.uploadDate)

        actionButton.setTitle(isEditMode ? "Delete" : "View", for: .normal)
        actionButton.setTitleColor(isEditMode ? .systemRed : .systemBlue, for: .normal)
    }

    func configureAsAddButton() {
        self.document = nil

        iconLabel.text = "➕"
        titleLabel.text = "Add Document"
        subtitleLabel.text = "Tap to add photo or file"

        actionButton.setTitle("Add", for: .normal)
        actionButton.setTitleColor(.systemBlue, for: .normal)
    }

    private func getDocumentIcon(_ type: DocumentType) -> String {
        switch type {
        case .flight: return "✈️"
        case .accommodation: return "🏨"
        case .ticket: return "🎫"
        case .receipt: return "🧾"
        case .map: return "🗺️"
        case .photo: return "📷"
        case .itinerary: return "📋"
        case .passport: return "📘"
        case .visa: return "📄"
        case .insurance: return "🛡️"
        case .other: return "📎"
        }
    }

    @objc private func actionTapped() {
        if let document = document {
            delegate?.didRequestDocumentView(document)
        } else {
            delegate?.didRequestAddDocument()
        }
    }
}