//
//  FirebaseManager.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation
// import Firebase
// import FirebaseFirestore
// import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    // TODO: Initialize Firebase when SDK is added
    // private let db = Firestore.firestore()
    
    // MARK: - Trip Management
    func syncTrip(_ trip: Trip) {
        // TODO: Implement Firebase sync
    }
    
    func fetchTrips(completion: @escaping ([Trip]?, Error?) -> Void) {
        // TODO: Implement Firebase fetch
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Implement Firebase Auth
    }
    
    func signOut() {
        // TODO: Implement Firebase signout
    }
}