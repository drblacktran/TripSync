//
//  TripModel.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import Foundation

struct TripModel: Codable, Identifiable {
    let id: String
    let title: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let createdDate: Date
    let isShared: Bool
    
    init(id: String = UUID().uuidString, title: String, destination: String, startDate: Date, endDate: Date, createdDate: Date = Date(), isShared: Bool = false) {
        self.id = id
        self.title = title
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.createdDate = createdDate
        self.isShared = isShared
    }
}

// MARK: - Dummy Data
extension TripModel {
    static func createDummyTrips() -> [TripModel] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            TripModel(
                title: "Tokyo Adventure",
                destination: "Tokyo, Japan",
                startDate: calendar.date(byAdding: .day, value: 30, to: today) ?? today,
                endDate: calendar.date(byAdding: .day, value: 37, to: today) ?? today
            ),
            TripModel(
                title: "European Backpacking",
                destination: "Paris, France",
                startDate: calendar.date(byAdding: .day, value: 60, to: today) ?? today,
                endDate: calendar.date(byAdding: .day, value: 74, to: today) ?? today
            ),
            TripModel(
                title: "Beach Vacation",
                destination: "Bali, Indonesia",
                startDate: calendar.date(byAdding: .day, value: 90, to: today) ?? today,
                endDate: calendar.date(byAdding: .day, value: 97, to: today) ?? today
            ),
            TripModel(
                title: "Business Trip",
                destination: "New York, USA",
                startDate: calendar.date(byAdding: .day, value: 14, to: today) ?? today,
                endDate: calendar.date(byAdding: .day, value: 17, to: today) ?? today
            ),
            TripModel(
                title: "Family Reunion",
                destination: "Melbourne, Australia",
                startDate: calendar.date(byAdding: .day, value: 120, to: today) ?? today,
                endDate: calendar.date(byAdding: .day, value: 130, to: today) ?? today
            )
        ]
    }
}