//
//  MapAnnotations.swift
//  TripSync
//
//  Created by Tien Tran on 9/10/2025.
//

import Foundation
import MapKit

// MARK: - Day Annotation
class DayAnnotation: NSObject, MKAnnotation {
    let dayNumber: Int
    let date: Date
    let region: TripRegion
    let coordinate: CLLocationCoordinate2D

    var title: String? {
        return "Day \(dayNumber)"
    }

    var subtitle: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: date)) • \(region.name)"
    }

    init(dayNumber: Int, date: Date, region: TripRegion, coordinate: CLLocationCoordinate2D) {
        self.dayNumber = dayNumber
        self.date = date
        self.region = region
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - POI Annotation
class POIAnnotation: NSObject, MKAnnotation {
    let poi: PointOfInterest
    let coordinate: CLLocationCoordinate2D

    var title: String? {
        return poi.name
    }

    var subtitle: String? {
        let duration = poi.estimatedDuration
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m • \(poi.category.rawValue.capitalized)"
        } else {
            return "\(minutes)min • \(poi.category.rawValue.capitalized)"
        }
    }

    init(poi: PointOfInterest, coordinate: CLLocationCoordinate2D) {
        self.poi = poi
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Route Overlay
class RouteOverlay: NSObject, MKOverlay {
    let polyline: MKPolyline
    let transportMode: TransportMode

    var coordinate: CLLocationCoordinate2D {
        return polyline.coordinate
    }

    var boundingMapRect: MKMapRect {
        return polyline.boundingMapRect
    }

    init(polyline: MKPolyline, transportMode: TransportMode) {
        self.polyline = polyline
        self.transportMode = transportMode
        super.init()
    }
}

// MARK: - Flight Path Overlay
class FlightPathOverlay: NSObject, MKOverlay {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: (startCoordinate.latitude + endCoordinate.latitude) / 2,
            longitude: (startCoordinate.longitude + endCoordinate.longitude) / 2
        )
    }

    var boundingMapRect: MKMapRect {
        let startPoint = MKMapPoint(startCoordinate)
        let endPoint = MKMapPoint(endCoordinate)

        let minX = min(startPoint.x, endPoint.x)
        let maxX = max(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxY = max(startPoint.y, endPoint.y)

        return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // Computed property for the curved flight path
    var flightPath: MKPolyline {
        return createCurvedFlightPath()
    }

    init(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        super.init()
    }

    private func createCurvedFlightPath() -> MKPolyline {
        let startLat = startCoordinate.latitude
        let startLon = startCoordinate.longitude
        let endLat = endCoordinate.latitude
        let endLon = endCoordinate.longitude

        // Calculate the great circle path with curvature
        var coordinates: [CLLocationCoordinate2D] = []

        let steps = 50 // Number of points to create smooth curve
        for i in 0...steps {
            let fraction = Double(i) / Double(steps)

            // Simple linear interpolation for now (can be enhanced with proper great circle calculation)
            let lat = startLat + (endLat - startLat) * fraction
            let lon = startLon + (endLon - startLon) * fraction

            // Add altitude curve effect by offsetting latitude slightly
            let distanceKm = calculateDistance(start: startCoordinate, end: endCoordinate)
            let maxAltitudeOffset = min(distanceKm / 1000.0, 5.0) // Max 5 degrees offset for long flights

            // Create parabolic curve (highest in the middle)
            let altitudeFactor = 4 * fraction * (1 - fraction) // Parabola: peaks at 0.5
            let altitudeOffset = altitudeFactor * maxAltitudeOffset

            let adjustedLat = lat + altitudeOffset
            coordinates.append(CLLocationCoordinate2D(latitude: adjustedLat, longitude: lon))
        }

        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    private func calculateDistance(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) // in meters
    }
}

// MARK: - Flight Path Renderer
class FlightPathRenderer: MKOverlayRenderer {
    let flightOverlay: FlightPathOverlay

    // Renderer properties
    var strokeColor: UIColor = .systemBlue
    var lineWidth: CGFloat = 3.0
    var lineDashPattern: [NSNumber]?

    init(overlay: FlightPathOverlay) {
        self.flightOverlay = overlay
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let path = createPath(for: flightOverlay.flightPath, in: mapRect) else { return }

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(lineWidth / zoomScale)

        // Set dash pattern if specified
        if let dashPattern = lineDashPattern {
            let dashLengths = dashPattern.map { CGFloat($0.floatValue) / zoomScale }
            context.setLineDash(phase: 0, lengths: dashLengths)
        }

        context.addPath(path)
        context.strokePath()

        // Draw airplane icons along the path
        drawAirplaneIcons(context: context, path: path, zoomScale: zoomScale)
    }

    private func createPath(for polyline: MKPolyline, in mapRect: MKMapRect) -> CGPath? {
        let path = CGMutablePath()
        let points = polyline.points()
        let pointCount = polyline.pointCount

        if pointCount > 0 {
            let firstPoint = point(for: points[0])
            path.move(to: firstPoint)

            for i in 1..<pointCount {
                let point = self.point(for: points[i])
                path.addLine(to: point)
            }
        }

        return path
    }

    private func drawAirplaneIcons(context: CGContext, path: CGPath, zoomScale: MKZoomScale) {
        // Draw airplane icons at regular intervals along the flight path
        let numberOfAirplanes = 3 // Fixed number to avoid complex path calculations

        for i in 0..<numberOfAirplanes {
            let position = CGFloat(i) / CGFloat(numberOfAirplanes - 1)
            if let point = getPointOnPath(path, at: position) {
                drawAirplane(at: point, context: context, zoomScale: zoomScale)
            }
        }
    }

    private func getPointOnPath(_ path: CGPath, at position: CGFloat) -> CGPoint? {
        // Simplified: return interpolated point along the path
        // In a real implementation, you'd calculate the exact position along the curved path
        let startPoint = flightOverlay.startCoordinate
        let endPoint = flightOverlay.endCoordinate

        let lat = startPoint.latitude + (endPoint.latitude - startPoint.latitude) * Double(position)
        let lon = startPoint.longitude + (endPoint.longitude - startPoint.longitude) * Double(position)

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return point(for: MKMapPoint(coordinate))
    }

    private func drawAirplane(at point: CGPoint, context: CGContext, zoomScale: MKZoomScale) {
        let airplaneSize: CGFloat = 12.0 / zoomScale

        context.saveGState()

        // Move to airplane position
        context.translateBy(x: point.x, y: point.y)

        // Draw simple airplane shape
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(1.0 / zoomScale)

        // Airplane body (simple triangle)
        let airplanePath = CGMutablePath()
        airplanePath.move(to: CGPoint(x: 0, y: -airplaneSize/2))
        airplanePath.addLine(to: CGPoint(x: airplaneSize/3, y: airplaneSize/2))
        airplanePath.addLine(to: CGPoint(x: -airplaneSize/3, y: airplaneSize/2))
        airplanePath.closeSubpath()

        context.addPath(airplanePath)
        context.fillPath()
        context.addPath(airplanePath)
        context.strokePath()

        context.restoreGState()
    }
}

// MARK: - Removed problematic CGPath extension to avoid unsafe bit casting issues
