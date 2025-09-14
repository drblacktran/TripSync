//
//  Constants.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation

struct Constants {
    
    // MARK: - Firebase
    struct Firebase {
        static let tripsCollection = "trips"
        static let usersCollection = "users"
        static let activitiesCollection = "activities"
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let tripUpdated = "tripUpdated"
        static let participantJoined = "participantJoined"
    }
    
    // MARK: - UI
    struct UI {
        static let cornerRadius: CGFloat = 8.0
        static let defaultPadding: CGFloat = 16.0
        static let cellHeight: CGFloat = 80.0
    }
}