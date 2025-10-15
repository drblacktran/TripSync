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
    
    // MARK: - Settings Management
    func saveUserSetting<T: Codable>(_ setting: T, type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        do {
            let settingData = try JSONEncoder().encode(setting)
            guard let settingDict = try JSONSerialization.jsonObject(with: settingData) as? [String: Any] else {
                completion(.failure(NSError(domain: "FirebaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize setting"])))
                return
            }
            
            db.collection("users").document(userId).collection("settings").document(type).setData(settingDict) { error in
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
    
    func loadUserSetting<T: Codable>(_ type: T.Type, settingType: String, completion: @escaping (Result<T?, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("users").document(userId).collection("settings").document(settingType).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(.success(nil)) // No setting found
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let setting = try JSONDecoder().decode(type, from: jsonData)
                completion(.success(setting))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func saveAllUserSettings(_ profile: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = getCurrentUser()?.uid else {
            print("❌ [FIRESTORE] Save failed: User not authenticated")
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        print("🔄 [FIRESTORE] Starting user settings save for userId: \(userId)")
        print("📊 [FIRESTORE] Profile data to save:")
        print("   - Name: \(profile.fullName)")
        print("   - Email: \(profile.email)")
        print("   - Home Country: \(profile.homeCountry)")
        print("   - Currency: \(profile.homeCurrency)")
        print("   - Units: \(profile.preferredUnits.rawValue)")

        let batch = db.batch()
        let userSettingsRef = db.collection("users").document(userId).collection("settings")

        do {
            // Save travel preferences
            let travelData = try JSONEncoder().encode(profile.travelPreferences)
            if let travelDict = try JSONSerialization.jsonObject(with: travelData) as? [String: Any] {
                batch.setData(travelDict, forDocument: userSettingsRef.document("travelPreferences"))
                print("📝 [FIRESTORE] Travel preferences encoded:")
                print("   - Default trip length: \(profile.travelPreferences.defaultTripLength)")
                print("   - Transport mode: \(profile.travelPreferences.preferredTransportMode.rawValue)")
                print("   - Budget range: \(profile.travelPreferences.budgetRange.rawValue)")
            }

            // Save notification settings
            let notificationData = try JSONEncoder().encode(profile.notificationSettings)
            if let notificationDict = try JSONSerialization.jsonObject(with: notificationData) as? [String: Any] {
                batch.setData(notificationDict, forDocument: userSettingsRef.document("notificationSettings"))
                print("🔔 [FIRESTORE] Notification settings encoded:")
                print("   - Push notifications: \(profile.notificationSettings.pushNotifications)")
                print("   - Flight updates: \(profile.notificationSettings.flightUpdates)")
                print("   - Budget alerts: \(profile.notificationSettings.budgetAlerts)")
            }

            // Save privacy settings
            let privacyData = try JSONEncoder().encode(profile.privacySettings)
            if let privacyDict = try JSONSerialization.jsonObject(with: privacyData) as? [String: Any] {
                batch.setData(privacyDict, forDocument: userSettingsRef.document("privacySettings"))
                print("🔒 [FIRESTORE] Privacy settings encoded:")
                print("   - Share location: \(profile.privacySettings.shareLocationData)")
                print("   - Analytics opt-in: \(profile.privacySettings.analyticsOptIn)")
                print("   - Marketing emails: \(profile.privacySettings.marketingEmails)")
            }

            // Save basic profile info
            let profileInfo: [String: Any] = [
                "homeCountry": profile.homeCountry,
                "homeCurrency": profile.homeCurrency,
                "preferredUnits": profile.preferredUnits.rawValue,
                "languageCode": profile.languageCode,
                "timeZone": profile.timeZone,
                "lastUpdated": Timestamp()
            ]
            batch.setData(profileInfo, forDocument: userSettingsRef.document("profileSettings"))
            print("👤 [FIRESTORE] Profile settings encoded:")
            print("   - Home country: \(profile.homeCountry)")
            print("   - Currency: \(profile.homeCurrency)")
            print("   - Units: \(profile.preferredUnits.rawValue)")
            print("   - Language: \(profile.languageCode)")
            print("   - Timezone: \(profile.timeZone)")

            // Commit batch
            print("💾 [FIRESTORE] Committing batch write to users/\(userId)/settings/...")
            batch.commit { error in
                if let error = error {
                    print("❌ [FIRESTORE] Batch commit failed: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ [FIRESTORE] Successfully saved all user settings")
                    print("📍 [FIRESTORE] Documents saved:")
                    print("   - users/\(userId)/settings/travelPreferences")
                    print("   - users/\(userId)/settings/notificationSettings")
                    print("   - users/\(userId)/settings/privacySettings")
                    print("   - users/\(userId)/settings/profileSettings")
                    completion(.success(()))
                }
            }
        } catch {
            print("❌ [FIRESTORE] JSON encoding failed: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func loadAllUserSettings(completion: @escaping (Result<UserProfile?, Error>) -> Void) {
        guard let currentUser = getCurrentUser() else {
            completion(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let userSettingsRef = db.collection("users").document(currentUser.uid).collection("settings")
        let group = DispatchGroup()
        
        var travelPreferences: TravelPreferences?
        var notificationSettings: NotificationSettings?
        var privacySettings: PrivacySettings?
        var profileSettings: [String: Any]?
        var loadError: Error?
        
        // Load travel preferences
        group.enter()
        userSettingsRef.document("travelPreferences").getDocument { document, error in
            defer { group.leave() }
            if let error = error {
                loadError = error
                return
            }
            if let data = document?.data() {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    travelPreferences = try JSONDecoder().decode(TravelPreferences.self, from: jsonData)
                } catch {
                    print("Failed to decode travel preferences: \(error)")
                }
            }
        }
        
        // Load notification settings
        group.enter()
        userSettingsRef.document("notificationSettings").getDocument { document, error in
            defer { group.leave() }
            if let error = error {
                loadError = error
                return
            }
            if let data = document?.data() {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    notificationSettings = try JSONDecoder().decode(NotificationSettings.self, from: jsonData)
                } catch {
                    print("Failed to decode notification settings: \(error)")
                }
            }
        }
        
        // Load privacy settings
        group.enter()
        userSettingsRef.document("privacySettings").getDocument { document, error in
            defer { group.leave() }
            if let error = error {
                loadError = error
                return
            }
            if let data = document?.data() {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    privacySettings = try JSONDecoder().decode(PrivacySettings.self, from: jsonData)
                } catch {
                    print("Failed to decode privacy settings: \(error)")
                }
            }
        }
        
        // Load profile settings
        group.enter()
        userSettingsRef.document("profileSettings").getDocument { document, error in
            defer { group.leave() }
            if let error = error {
                loadError = error
                return
            }
            profileSettings = document?.data()
        }
        
        group.notify(queue: .main) {
            if let error = loadError {
                completion(.failure(error))
                return
            }
            
            // Create profile with loaded settings or defaults
            var profile = UserProfile(
                id: currentUser.uid,
                firstName: "User", // Will be updated from Firebase Auth if available
                lastName: "",
                email: currentUser.email ?? "user@tripsync.com"
            )
            
            // Apply loaded settings
            if let travelPrefs = travelPreferences {
                profile.travelPreferences = travelPrefs
            }
            if let notificationSettings = notificationSettings {
                profile.notificationSettings = notificationSettings
            }
            if let privacySettings = privacySettings {
                profile.privacySettings = privacySettings
            }
            if let profileInfo = profileSettings {
                if let homeCountry = profileInfo["homeCountry"] as? String {
                    profile.homeCountry = homeCountry
                }
                if let homeCurrency = profileInfo["homeCurrency"] as? String {
                    profile.homeCurrency = homeCurrency
                }
                if let unitsRaw = profileInfo["preferredUnits"] as? String,
                   let units = MeasurementUnit(rawValue: unitsRaw) {
                    profile.preferredUnits = units
                }
                if let languageCode = profileInfo["languageCode"] as? String {
                    profile.languageCode = languageCode
                }
                if let timeZone = profileInfo["timeZone"] as? String {
                    profile.timeZone = timeZone
                }
            }
            
            completion(.success(profile))
        }
    }
    
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