//
//  TimelineDayView.swift
//  TripSync
//
//  Container view combining grid, POI blocks, and travel connectors
//

import UIKit

protocol TimelineDayViewDelegate: AnyObject {
    func timelineDayView(_ view: TimelineDayView, didUpdateBlock block: TimelineBlock)
    func timelineDayView(_ view: TimelineDayView, didTapBlock block: TimelineBlock)
    func timelineDayViewDidRequestAddPOI(_ view: TimelineDayView)
}

class TimelineDayView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: TimelineDayViewDelegate?
    
    private(set) var timeline: DailyTimeline {
        didSet {
            refreshTimeline()
        }
    }
    
    private let gridView = TimelineGridView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let addPlaceButton = UIButton(type: .system)
    
    private var poiBlockViews: [DraggablePOIBlock] = []
    private var connectorViews: [TravelConnectorView] = []
    
    // MARK: - Init
    
    init(timeline: DailyTimeline) {
        self.timeline = timeline
        super.init(frame: .zero)
        setupUI()
        refreshTimeline()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Scroll view setup
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        // Content view holds grid and POI blocks
        contentView.backgroundColor = .clear
        
        // Empty state
        emptyStateView.backgroundColor = .secondarySystemBackground
        emptyStateView.layer.cornerRadius = 12
        emptyStateLabel.text = "No places added yet\nTap + to add your first place"
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 15)
        emptyStateLabel.textColor = .secondaryLabel
        
        addPlaceButton.setTitle("+ Add Place", for: .normal)
        addPlaceButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addPlaceButton.addTarget(self, action: #selector(addPlaceTapped), for: .touchUpInside)
        
        // Hierarchy
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(gridView)
        
        addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(addPlaceButton)
        
        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        gridView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        addPlaceButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            gridView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -20),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20),
            
            addPlaceButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 16),
            addPlaceButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor)
        ])
    }
    
    // MARK: - Timeline Management
    
    func updateTimeline(_ timeline: DailyTimeline) {
        self.timeline = timeline
    }
    
    private func refreshTimeline() {
        // Clear existing views
        poiBlockViews.forEach { $0.removeFromSuperview() }
        connectorViews.forEach { $0.removeFromSuperview() }
        poiBlockViews.removeAll()
        connectorViews.removeAll()
        
        // Show/hide empty state
        let isEmpty = timeline.blocks.isEmpty
        emptyStateView.isHidden = !isEmpty
        scrollView.isHidden = isEmpty
        
        guard !isEmpty else { return }
        
        // Adjust grid to fit POIs
        gridView.adjustToFit(blocks: timeline.blocks)
        
        // Update content size
        let gridHeight = gridView.totalHeight
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: gridHeight)
        gridView.frame = contentView.bounds
        scrollView.contentSize = CGSize(width: bounds.width, height: gridHeight)
        
        // Sort blocks by start time
        let sortedBlocks = timeline.blocks.sorted { $0.startTime < $1.startTime }
        
        // Create POI blocks and connectors
        for (index, block) in sortedBlocks.enumerated() {
            // Create POI block
            let blockView = createPOIBlockView(for: block)
            contentView.addSubview(blockView)
            poiBlockViews.append(blockView)
            
            // Create connector to next block (if exists)
            if index < sortedBlocks.count - 1, let travelSegment = block.travelToNext {
                let connector = createConnectorView(
                    segment: travelSegment,
                    from: block,
                    to: sortedBlocks[index + 1]
                )
                contentView.addSubview(connector)
                connectorViews.append(connector)
            }
        }
        
        // Detect and mark overlaps
        updateOverlapIndicators()
    }
    
    private func createPOIBlockView(for block: TimelineBlock) -> DraggablePOIBlock {
        let blockView = DraggablePOIBlock(block: block, gridView: gridView)
        blockView.delegate = self
        
        // Calculate frame
        let y = gridView.yPosition(for: block.startTime)
        let height = gridView.height(for: block.duration)
        let x: CGFloat = 70  // Offset for hour labels
        let width = bounds.width - 90
        
        blockView.frame = CGRect(x: x, y: y, width: width, height: height)
        
        return blockView
    }
    
    private func createConnectorView(segment: TravelSegment, from: TimelineBlock, to: TimelineBlock) -> TravelConnectorView {
        let connector = TravelConnectorView(travelSegment: segment)
        
        // Calculate frame between blocks
        let startY = gridView.yPosition(for: from.endTime)
        let endY = gridView.yPosition(for: to.startTime)
        let x: CGFloat = 70
        let width: CGFloat = 80
        let height = endY - startY
        
        connector.frame = CGRect(x: x, y: startY, width: width, height: height)
        
        return connector
    }
    
    // MARK: - Overlap Detection
    
    private func updateOverlapIndicators() {
        // Check each block for overlaps
        for blockView in poiBlockViews {
            let overlappingBlocks = timeline.overlappingBlocks(with: blockView.block)
            blockView.hasOverlap = !overlappingBlocks.isEmpty
        }
    }
    
    // MARK: - Actions
    
    @objc private func addPlaceTapped() {
        delegate?.timelineDayViewDidRequestAddPOI(self)
    }
    
    // MARK: - Public Methods
    
    func addBlock(_ block: TimelineBlock) {
        var updatedTimeline = timeline
        updatedTimeline.blocks.append(block)
        updateTimeline(updatedTimeline)
    }
    
    func removeBlock(_ blockId: String) {
        var updatedTimeline = timeline
        updatedTimeline.blocks.removeAll { $0.id == blockId }
        updateTimeline(updatedTimeline)
    }
    
    func updateBlock(_ block: TimelineBlock) {
        var updatedTimeline = timeline
        if let index = updatedTimeline.blocks.firstIndex(where: { $0.id == block.id }) {
            updatedTimeline.blocks[index] = block
            updateTimeline(updatedTimeline)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update frames when bounds change
        if !timeline.blocks.isEmpty {
            refreshTimeline()
        }
    }
}

// MARK: - DraggablePOIBlockDelegate

extension TimelineDayView: DraggablePOIBlockDelegate {
    func poiBlockDidStartDragging(_ block: DraggablePOIBlock) {
        // Bring to front
        contentView.bringSubviewToFront(block)
    }
    
    func poiBlockDidMove(_ block: DraggablePOIBlock, to newStartTime: Date) {
        // Real-time overlap detection
        var tempBlock = block.block
        tempBlock.startTime = newStartTime
        
        let overlaps = timeline.overlappingBlocks(with: tempBlock)
        block.hasOverlap = !overlaps.isEmpty
        
        // Visual feedback for other affected blocks
        for otherBlockView in poiBlockViews where otherBlockView != block {
            if overlaps.contains(where: { $0.id == otherBlockView.block.id }) {
                otherBlockView.hasOverlap = true
            } else {
                // Reset if no longer overlapping
                let actualOverlaps = timeline.overlappingBlocks(with: otherBlockView.block)
                otherBlockView.hasOverlap = !actualOverlaps.isEmpty
            }
        }
    }
    
    func poiBlockDidEndDragging(_ block: DraggablePOIBlock) {
        // Update timeline with new position
        updateBlock(block.block)
        delegate?.timelineDayView(self, didUpdateBlock: block.block)
        
        // Refresh connectors
        refreshTimeline()
    }
    
    func poiBlockDidResize(_ block: DraggablePOIBlock, to newDuration: TimeInterval) {
        // Update timeline with new duration
        updateBlock(block.block)
        delegate?.timelineDayView(self, didUpdateBlock: block.block)
        
        // Refresh connectors
        refreshTimeline()
    }
    
    func poiBlockWasTapped(_ block: DraggablePOIBlock) {
        delegate?.timelineDayView(self, didTapBlock: block.block)
    }
}
