//
//  DraggablePOIBlock.swift
//  TripSync
//
//  Draggable and resizable POI block for timeline view
//

import UIKit

protocol DraggablePOIBlockDelegate: AnyObject {
    func poiBlockDidStartDragging(_ block: DraggablePOIBlock)
    func poiBlockDidMove(_ block: DraggablePOIBlock, to newStartTime: Date)
    func poiBlockDidEndDragging(_ block: DraggablePOIBlock)
    func poiBlockDidResize(_ block: DraggablePOIBlock, to newDuration: TimeInterval)
    func poiBlockWasTapped(_ block: DraggablePOIBlock)
}

class DraggablePOIBlock: UIView {
    
    // MARK: - Properties
    
    var block: TimelineBlock {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: DraggablePOIBlockDelegate?
    weak var gridView: TimelineGridView?
    
    var hasOverlap: Bool = false {
        didSet {
            updateOverlapIndicator()
        }
    }
    
    // UI Components
    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let durationLabel = UILabel()
    private let overlapBadge = UIView()
    private let resizeHandle = UIView()
    
    // Gesture Recognizers
    private var panGesture: UIPanGestureRecognizer!
    private var resizePanGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    // Drag state
    private var originalFrame: CGRect = .zero
    private var originalDuration: TimeInterval = 0
    
    // MARK: - Init
    
    init(block: TimelineBlock, gridView: TimelineGridView) {
        self.block = block
        self.gridView = gridView
        super.init(frame: .zero)
        setupUI()
        setupGestures()
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Ensure translatesAutoresizingMaskIntoConstraints is set to true to avoid conflicts
        // This view's frame will be set directly by TimelineGridView
        translatesAutoresizingMaskIntoConstraints = true
        
        // Container with rounded corners and shadow
        containerView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1.5
        containerView.layer.borderColor = UIColor.systemBlue.cgColor
        containerView.clipsToBounds = false
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        
        // Name label
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 2
        
        // Time label
        timeLabel.font = .systemFont(ofSize: 11, weight: .medium)
        timeLabel.textColor = .secondaryLabel
        
        // Duration label
        durationLabel.font = .systemFont(ofSize: 10)
        durationLabel.textColor = .tertiaryLabel
        
        // Overlap warning badge
        overlapBadge.backgroundColor = .systemYellow
        overlapBadge.layer.cornerRadius = 8
        overlapBadge.isHidden = true
        let warningLabel = UILabel()
        warningLabel.text = "⚠️"
        warningLabel.font = .systemFont(ofSize: 12)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        overlapBadge.addSubview(warningLabel)
        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: overlapBadge.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: overlapBadge.centerYAnchor)
        ])
        
        // Resize handle (bottom edge)
        resizeHandle.backgroundColor = .systemBlue.withAlphaComponent(0.5)
        resizeHandle.layer.cornerRadius = 2
        
        // Add to hierarchy
        addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(durationLabel)
        containerView.addSubview(overlapBadge)
        containerView.addSubview(resizeHandle)
        
        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        overlapBadge.translatesAutoresizingMaskIntoConstraints = false
        resizeHandle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: overlapBadge.leadingAnchor, constant: -4),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            durationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            durationLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            durationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            overlapBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            overlapBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            overlapBadge.widthAnchor.constraint(equalToConstant: 24),
            overlapBadge.heightAnchor.constraint(equalToConstant: 24),
            
            resizeHandle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            resizeHandle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            resizeHandle.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -2),
            resizeHandle.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    private func setupGestures() {
        // Pan gesture for dragging
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        // Pan gesture for resizing (on handle only)
        resizePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:)))
        resizeHandle.addGestureRecognizer(resizePanGesture)
        resizeHandle.isUserInteractionEnabled = true
        
        // Tap gesture for selection
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Content Update
    
    private func updateContent() {
        nameLabel.text = block.poi.name
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTimeStr = formatter.string(from: block.startTime)
        let endTimeStr = formatter.string(from: block.endTime)
        timeLabel.text = "\(startTimeStr) - \(endTimeStr)"
        
        let minutes = Int(block.duration / 60)
        durationLabel.text = "\(minutes) min"
    }
    
    private func updateOverlapIndicator() {
        overlapBadge.isHidden = !hasOverlap
        
        if hasOverlap {
            containerView.layer.borderColor = UIColor.systemYellow.cgColor
            containerView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
        } else {
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let gridView = gridView else { return }
        
        switch gesture.state {
        case .began:
            originalFrame = frame
            delegate?.poiBlockDidStartDragging(self)
            
            // Visual feedback
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.alpha = 0.9
            }
            
        case .changed:
            let translation = gesture.translation(in: superview)
            var newY = originalFrame.origin.y + translation.y
            
            // Snap to grid
            newY = gridView.snapToGrid(newY)
            
            // Update frame
            frame.origin.y = newY
            
            // Calculate new time
            let newTime = gridView.time(fromYPosition: newY, on: block.startTime)
            
            // Update labels
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let endTime = newTime.addingTimeInterval(block.duration)
            timeLabel.text = "\(formatter.string(from: newTime)) - \(formatter.string(from: endTime))"
            
            // Notify delegate
            delegate?.poiBlockDidMove(self, to: newTime)
            
        case .ended, .cancelled:
            // Final snap
            let snappedY = gridView.snapToGrid(frame.origin.y)
            let finalTime = gridView.time(fromYPosition: snappedY, on: block.startTime)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.frame.origin.y = snappedY
                self.transform = .identity
                self.alpha = 1.0
            }
            
            // Update block
            block.startTime = finalTime
            updateContent()
            
            delegate?.poiBlockDidEndDragging(self)
            
        default:
            break
        }
    }
    
    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        guard let gridView = gridView else { return }
        
        switch gesture.state {
        case .began:
            originalFrame = frame
            originalDuration = block.duration
            
            // Visual feedback on handle
            UIView.animate(withDuration: 0.2) {
                self.resizeHandle.backgroundColor = .systemBlue.withAlphaComponent(0.8)
                self.resizeHandle.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
            }
            
        case .changed:
            let translation = gesture.translation(in: superview)
            var newHeight = originalFrame.height + translation.y
            
            // Convert to duration
            var newDuration = gridView.duration(fromHeight: newHeight)
            
            // Snap to 15-min intervals, min 15 min
            newDuration = TimelineBlock.snapDuration(newDuration, interval: 15 * 60, minimum: 15 * 60)
            
            // Update height
            let snappedHeight = gridView.height(for: newDuration)
            frame.size.height = snappedHeight
            
            // Update labels
            let minutes = Int(newDuration / 60)
            durationLabel.text = "\(minutes) min"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let endTime = block.startTime.addingTimeInterval(newDuration)
            timeLabel.text = "\(formatter.string(from: block.startTime)) - \(formatter.string(from: endTime))"
            
        case .ended, .cancelled:
            // Final duration
            let finalDuration = gridView.duration(fromHeight: frame.height)
            let snappedDuration = TimelineBlock.snapDuration(finalDuration, interval: 15 * 60, minimum: 15 * 60)
            
            UIView.animate(withDuration: 0.3) {
                self.resizeHandle.backgroundColor = .systemBlue.withAlphaComponent(0.5)
                self.resizeHandle.transform = .identity
            }
            
            // Update block
            block.duration = snappedDuration
            updateContent()
            
            // Resize frame to final size
            frame.size.height = gridView.height(for: snappedDuration)
            
            delegate?.poiBlockDidResize(self, to: snappedDuration)
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.poiBlockWasTapped(self)
        
        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension DraggablePOIBlock: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan and tap to coexist
        return false
    }
}
