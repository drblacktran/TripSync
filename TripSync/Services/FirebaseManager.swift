//
//  FirebaseManager.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    // MARK: - Trip Management
    func saveTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        do {
            let tripData = try JSONEncoder().encode(trip)
            guard let tripDict = try JSONSerialization.jsonObject(with: tripData) as? [String: Any] else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode trip"])))
                return
            }
            
            db.collection("users").document(userId).collection("trips").document(trip.id).setData(tripDict) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("users").document(userId).collection("trips").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            var trips: [Trip] = []
            
            for document in documents {
                do {
                    let data = try JSONSerialization.data(withJSONObject: document.data())
                    let trip = try JSONDecoder().decode(Trip.self, from: data)
                    trips.append(trip)
                } catch {
                    print("Failed to decode trip: \(error)")
                    continue
                }
            }
            
            // Sort trips by creation date (newest first)
            trips.sort { $0.createdDate > $1.createdDate }
            completion(.success(trips))
        }
    }
    
    func deleteTrip(tripId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("users").document(userId).collection("trips").document(tripId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        // Update is the same as save for Firestore
        saveTrip(trip, completion: completion)
    }
    
    func initializeUserWithSampleTrips(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Check if user already has trips
        db.collection("users").document(userId).collection("trips").getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // If user already has trips, don't add sample data
            if let documents = snapshot?.documents, !documents.isEmpty {
                completion(.success(()))
                return
            }
            
            // Add sample trips for new users
            let sampleTrips = Trip.createMockTrips()
            let group = DispatchGroup()
            var errors: [Error] = []
            
            for trip in sampleTrips {
                group.enter()
                self?.saveTrip(trip) { result in
                    switch result {
                    case .success():
                        break
                    case .failure(let error):
                        errors.append(error)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if errors.isEmpty {
                    completion(.success(()))
                } else {
                    completion(.failure(errors.first!))
                }
            }
        }
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found"])))
                return
            }
            
            completion(.success(user.uid))
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user created"])))
                return
            }
            
            completion(.success(user.uid))
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func getCurrentUser() -> User? {
        return auth.currentUser
    }
    
    var isUserLoggedIn: Bool {
        return auth.currentUser != nil
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}