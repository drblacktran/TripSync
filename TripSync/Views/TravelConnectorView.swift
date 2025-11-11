//
//  TravelConnectorView.swift
//  TripSync
//
//  Visual connector showing travel mode and duration between POIs
//

import UIKit

class TravelConnectorView: UIView {
    
    // MARK: - Properties
    
    var travelSegment: TravelSegment {
        didSet {
            updateContent()
        }
    }
    
    private let iconLabel = UILabel()
    private let durationLabel = UILabel()
    private let arrowLayer = CAShapeLayer()
    
    // MARK: - Init
    
    init(travelSegment: TravelSegment) {
        self.travelSegment = travelSegment
        super.init(frame: .zero)
        setupUI()
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Icon (transport mode emoji)
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.textAlignment = .center
        
        // Duration label
        durationLabel.font = .systemFont(ofSize: 11, weight: .medium)
        durationLabel.textColor = .secondaryLabel
        durationLabel.textAlignment = .center
        
        // Add to hierarchy
        addSubview(iconLabel)
        addSubview(durationLabel)
        
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            
            durationLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            durationLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 2)
        ])
        
        // Draw arrow
        layer.addSublayer(arrowLayer)
    }
    
    private func updateContent() {
        // Set icon based on transport mode
        iconLabel.text = travelSegment.mode.icon
        
        // Format duration
        let minutes = Int(travelSegment.duration / 60)
        if minutes < 60 {
            durationLabel.text = "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMin = minutes % 60
            if remainingMin > 0 {
                durationLabel.text = "\(hours)h \(remainingMin)m"
            } else {
                durationLabel.text = "\(hours)h"
            }
        }
        
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawArrow()
    }
    
    private func drawArrow() {
        let path = UIBezierPath()
        
        // Start point (top center)
        let startX = bounds.midX
        let startY: CGFloat = 0
        
        // End point (bottom center)
        let endX = bounds.midX
        let endY = bounds.height
        
        // Control point for curve (offset to left)
        let controlX = startX - 15
        let controlY = bounds.midY
        
        // Draw curved line
        path.move(to: CGPoint(x: startX, y: startY))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: endY - 6),  // -6 to leave room for arrow head
            controlPoint: CGPoint(x: controlX, y: controlY)
        )
        
        // Draw arrow head
        let arrowSize: CGFloat = 6
        path.move(to: CGPoint(x: endX, y: endY))
        path.addLine(to: CGPoint(x: endX - arrowSize/2, y: endY - arrowSize))
        path.move(to: CGPoint(x: endX, y: endY))
        path.addLine(to: CGPoint(x: endX + arrowSize/2, y: endY - arrowSize))
        
        arrowLayer.path = path.cgPath
        arrowLayer.strokeColor = UIColor.systemGray.cgColor
        arrowLayer.lineWidth = 1.5
        arrowLayer.lineCap = .round
        arrowLayer.fillColor = UIColor.clear.cgColor
    }
}
