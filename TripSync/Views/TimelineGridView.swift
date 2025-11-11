//
//  TimelineGridView.swift
//  TripSync
//
//  Timeline grid with hour markers and 15-minute intervals for calendar-style planning
//

import UIKit

class TimelineGridView: UIView {
    
    // MARK: - Properties
    
    private let minutesPerPixel: CGFloat = 4  // 1 pixel = 4 minutes (15px per hour)
    private let gridInterval: TimeInterval = 15 * 60  // 15 minutes
    
    var startHour: Int = 6    // 6 AM default
    var endHour: Int = 23     // 11 PM default
    
    private var hourLabels: [UILabel] = []
    private var gridLines: [CAShapeLayer] = []
    
    // MARK: - Computed Properties
    
    var hourHeight: CGFloat {
        return 60 / minutesPerPixel  // 60 minutes per hour
    }
    
    var totalHours: Int {
        return endHour - startHour + 1
    }
    
    var totalHeight: CGFloat {
        return CGFloat(totalHours) * hourHeight
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGrid()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGrid()
    }
    
    // MARK: - Setup
    
    func setupGrid(startHour: Int = 6, endHour: Int = 23) {
        self.startHour = startHour
        self.endHour = endHour
        
        // Clear existing
        hourLabels.forEach { $0.removeFromSuperview() }
        gridLines.forEach { $0.removeFromSuperlayer() }
        hourLabels.removeAll()
        gridLines.removeAll()
        
        // Set background
        backgroundColor = .systemBackground
        
        // Draw hour labels and grid lines
        for hour in startHour...endHour {
            addHourMarker(hour: hour)
        }
        
        // Draw 15-minute interval lines
        drawGridLines()
    }
    
    private func addHourMarker(hour: Int) {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        
        // Format hour (e.g., "9 AM", "2 PM")
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        if let date = Calendar.current.date(from: dateComponents) {
            label.text = formatter.string(from: date)
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        let yPosition = yPosition(forHour: hour)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            label.widthAnchor.constraint(equalToConstant: 50),
            label.topAnchor.constraint(equalTo: topAnchor, constant: yPosition - 8)  // -8 to center on line
        ])
        
        hourLabels.append(label)
    }
    
    private func drawGridLines() {
        // Draw major lines (every hour) and minor lines (every 15 min)
        let totalMinutes = totalHours * 60
        var currentMinute = 0
        
        while currentMinute <= totalMinutes {
            let isMajorLine = currentMinute % 60 == 0
            let yPos = CGFloat(currentMinute) / minutesPerPixel
            
            let line = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 60, y: yPos))  // Start after hour labels
            path.addLine(to: CGPoint(x: bounds.width, y: yPos))
            
            line.path = path.cgPath
            line.strokeColor = isMajorLine ? UIColor.separator.cgColor : UIColor.separator.withAlphaComponent(0.3).cgColor
            line.lineWidth = isMajorLine ? 1.0 : 0.5
            
            layer.addSublayer(line)
            gridLines.append(line)
            
            currentMinute += Int(gridInterval / 60)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Redraw grid lines when bounds change
        gridLines.forEach { $0.removeFromSuperlayer() }
        gridLines.removeAll()
        drawGridLines()
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert hour to Y position
    func yPosition(forHour hour: Int, minute: Int = 0) -> CGFloat {
        let minutesSinceStart = (hour - startHour) * 60 + minute
        return CGFloat(minutesSinceStart) / minutesPerPixel
    }
    
    /// Convert Date to Y position
    func yPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        return yPosition(forHour: hour, minute: minute)
    }
    
    /// Convert Y position to time (relative to startHour)
    func time(fromYPosition y: CGFloat, on date: Date) -> Date {
        let totalMinutes = Int(y * minutesPerPixel)
        let hour = startHour + totalMinutes / 60
        let minute = totalMinutes % 60
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components) ?? date
    }
    
    /// Convert duration (in seconds) to height
    func height(for duration: TimeInterval) -> CGFloat {
        let minutes = duration / 60
        return CGFloat(minutes) / minutesPerPixel
    }
    
    /// Convert height to duration (in seconds)
    func duration(fromHeight height: CGFloat) -> TimeInterval {
        let minutes = height * minutesPerPixel
        return Double(minutes) * 60
    }
    
    /// Snap Y position to nearest grid interval
    func snapToGrid(_ y: CGFloat) -> CGFloat {
        let minutes = y * minutesPerPixel
        let intervalMinutes = gridInterval / 60
        let snappedMinutes = round(minutes / CGFloat(intervalMinutes)) * CGFloat(intervalMinutes)
        return snappedMinutes / minutesPerPixel
    }
    
    // MARK: - Dynamic Hour Range
    
    /// Adjust grid to show POIs (earliest - 1hr to latest + 1hr)
    func adjustToFit(blocks: [TimelineBlock]) {
        guard !blocks.isEmpty else {
            // Default range
            setupGrid(startHour: 6, endHour: 23)
            return
        }
        
        let calendar = Calendar.current
        
        // Find earliest and latest times
        let earliestBlock = blocks.min(by: { $0.startTime < $1.startTime })
        let latestBlock = blocks.max(by: { $0.endTime < $1.endTime })
        
        guard let earliest = earliestBlock, let latest = latestBlock else {
            setupGrid(startHour: 6, endHour: 23)
            return
        }
        
        let earliestHour = calendar.component(.hour, from: earliest.startTime)
        let latestHour = calendar.component(.hour, from: latest.endTime)
        
        // Add 1-hour buffer, but keep within 0-23 range
        let newStartHour = max(0, earliestHour - 1)
        let newEndHour = min(23, latestHour + 1)
        
        setupGrid(startHour: newStartHour, endHour: newEndHour)
    }
}
