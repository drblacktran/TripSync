//
//  AppIconGenerator.swift
//  TripSync
//
//  Generates app icon programmatically using the airplane.circle design
//

import UIKit

class AppIconGenerator {

    /// Generate TripSync app icon (airplane in circle)
    /// - Parameters:
    ///   - size: Icon size (default 1024 for App Store)
    ///   - backgroundColor: Background color (default systemBlue)
    ///   - iconColor: Icon color (default white)
    /// - Returns: Generated icon image
    static func generateTripSyncIcon(
        size: CGFloat = 1024,
        backgroundColor: UIColor = .systemBlue,
        iconColor: UIColor = .white
    ) -> UIImage? {

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // Fill background with solid color
            backgroundColor.setFill()
            context.fill(rect)

            // Calculate icon size (70% of total size for proper padding)
            let iconSize = size * 0.7
            let iconRect = CGRect(
                x: (size - iconSize) / 2,
                y: (size - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            // Draw airplane symbol
            if let airplaneSymbol = UIImage(systemName: "airplane.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: iconSize))
                .withTintColor(iconColor, renderingMode: .alwaysOriginal) {

                airplaneSymbol.draw(in: iconRect)
            }
        }

        return image
    }

    /// Generate custom TripSync icon with gradient background
    /// - Parameters:
    ///   - size: Icon size
    ///   - gradientColors: Array of gradient colors
    ///   - iconColor: Icon color
    /// - Returns: Generated icon with gradient
    static func generateTripSyncIconWithGradient(
        size: CGFloat = 1024,
        gradientColors: [UIColor] = [UIColor.systemBlue, UIColor.systemTeal],
        iconColor: UIColor = .white
    ) -> UIImage? {

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // Create gradient background
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors.map { $0.cgColor } as CFArray,
                locations: nil
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size, y: size),
                options: []
            )

            // Calculate icon size
            let iconSize = size * 0.7
            let iconRect = CGRect(
                x: (size - iconSize) / 2,
                y: (size - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            // Draw airplane symbol
            if let airplaneSymbol = UIImage(systemName: "airplane.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: iconSize))
                .withTintColor(iconColor, renderingMode: .alwaysOriginal) {

                airplaneSymbol.draw(in: iconRect)
            }
        }

        return image
    }

    /// Generate custom icon with manual airplane drawing (for more control)
    /// - Parameters:
    ///   - size: Icon size
    ///   - backgroundColor: Background color
    ///   - circleColor: Circle color
    ///   - airplaneColor: Airplane color
    /// - Returns: Custom drawn icon
    static func generateCustomTripSyncIcon(
        size: CGFloat = 1024,
        backgroundColor: UIColor = .systemBlue,
        circleColor: UIColor = .white,
        airplaneColor: UIColor = .systemBlue
    ) -> UIImage? {

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let ctx = context.cgContext

            // Fill background
            backgroundColor.setFill()
            ctx.fill(rect)

            // Draw outer circle (80% of size)
            let circleSize = size * 0.8
            let circleRect = CGRect(
                x: (size - circleSize) / 2,
                y: (size - circleSize) / 2,
                width: circleSize,
                height: circleSize
            )

            circleColor.setFill()
            ctx.fillEllipse(in: circleRect)

            // Draw airplane shape in the center
            drawAirplane(in: ctx, rect: circleRect, color: airplaneColor)
        }

        return image
    }

    /// Draw a simple airplane shape
    private static func drawAirplane(in context: CGContext, rect: CGRect, color: UIColor) {
        let centerX = rect.midX
        let centerY = rect.midY
        let scale = rect.width * 0.25 // Airplane size

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)

        // Rotate airplane to point right-upward (45 degrees)
        context.rotate(by: -CGFloat.pi / 4)

        let path = UIBezierPath()

        // Airplane body (fuselage)
        path.move(to: CGPoint(x: 0, y: -scale * 0.6))
        path.addLine(to: CGPoint(x: 0, y: scale * 0.4))

        // Wings
        path.move(to: CGPoint(x: -scale * 0.5, y: 0))
        path.addLine(to: CGPoint(x: scale * 0.5, y: 0))

        // Tail wings
        path.move(to: CGPoint(x: -scale * 0.3, y: scale * 0.3))
        path.addLine(to: CGPoint(x: scale * 0.3, y: scale * 0.3))

        // Set stroke properties
        color.setStroke()
        path.lineWidth = scale * 0.15
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        context.restoreGState()
    }

    /// Save generated icon to Documents directory for preview
    /// - Parameter image: Icon image to save
    /// - Returns: File URL if successful
    @discardableResult
    static func saveIconToDocuments(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("TripSyncIcon.png")

        do {
            try data.write(to: fileURL)
            print("✅ Icon saved to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Failed to save icon: \(error)")
            return nil
        }
    }

    /// Generate all variants (light, dark, tinted) and save to Documents
    static func generateAllVariants() -> [String: UIImage] {
        var variants: [String: UIImage] = [:]

        // Light mode (default)
        if let lightIcon = generateTripSyncIcon(
            size: 1024,
            backgroundColor: .systemBlue,
            iconColor: .white
        ) {
            variants["light"] = lightIcon
            saveIconToDocuments(lightIcon)
        }

        // Dark mode variant
        if let darkIcon = generateTripSyncIcon(
            size: 1024,
            backgroundColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0), // Brighter blue for dark mode
            iconColor: .white
        ) {
            variants["dark"] = darkIcon
        }

        // Tinted variant (monochrome for iOS 18+)
        if let tintedIcon = generateTripSyncIcon(
            size: 1024,
            backgroundColor: .white,
            iconColor: .systemBlue
        ) {
            variants["tinted"] = tintedIcon
        }

        // Gradient variant (optional)
        if let gradientIcon = generateTripSyncIconWithGradient(
            size: 1024,
            gradientColors: [
                UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),  // Blue
                UIColor(red: 0.0, green: 0.78, blue: 0.75, alpha: 1.0)  // Teal
            ],
            iconColor: .white
        ) {
            variants["gradient"] = gradientIcon
        }

        print("✅ Generated \(variants.count) icon variants")
        return variants
    }
}

// MARK: - Preview Helper
extension AppIconGenerator {

    /// Create a preview view controller to visualize generated icons
    static func createPreviewViewController() -> UIViewController {
        let vc = IconPreviewViewController()
        return vc
    }
}

// MARK: - Preview View Controller
class IconPreviewViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TripSync Icon Preview"
        view.backgroundColor = .systemBackground

        setupUI()
        generateAndDisplayIcons()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func generateAndDisplayIcons() {
        let variants = AppIconGenerator.generateAllVariants()

        for (name, icon) in variants {
            let iconView = createIconPreview(icon: icon, name: name)
            stackView.addArrangedSubview(iconView)
        }

        // Add save instructions
        let instructionsLabel = UILabel()
        instructionsLabel.text = "Icons saved to Documents folder.\nTap 'Export' to share or use in Xcode."
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.font = .systemFont(ofSize: 14)
        instructionsLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(instructionsLabel)

        // Add export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export All Icons", for: .normal)
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 8
        exportButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        exportButton.addTarget(self, action: #selector(exportIcons), for: .touchUpInside)
        stackView.addArrangedSubview(exportButton)
    }

    private func createIconPreview(icon: UIImage, name: String) -> UIView {
        let container = UIView()

        let imageView = UIImageView(image: icon)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 22.37 // iOS icon corner radius (22.37% of size)
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.systemGray4.cgColor

        let label = UILabel()
        label.text = name.capitalized
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center

        container.addSubview(imageView)
        container.addSubview(label)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    @objc private func exportIcons() {
        let alert = UIAlertController(
            title: "Export Icons",
            message: "Icons have been saved to Documents folder. You can access them via Files app or export to your Mac.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
