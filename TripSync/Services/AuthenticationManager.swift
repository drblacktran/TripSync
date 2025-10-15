//
//  AuthenticationManager.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import Foundation
import LocalAuthentication
import Firebase
import FirebaseAuth
import AuthenticationServices
import ObjectiveC

enum AuthMethod {
    case biometric
    case password
    case passkey
}

enum SessionDuration: Int, CaseIterable {
    case oneHour = 3600
    case oneDay = 86400
    case threeDays = 259200
    case oneWeek = 604800
    case oneMonth = 2592000
    case threeMonths = 7776000
    case never = 0
    
    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .oneDay: return "1 Day"
        case .threeDays: return "3 Days"
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .never: return "Never"
        }
    }
}

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainHelper()
    private var sessionTimer: Timer?
    
    // Keys for UserDefaults and Keychain
    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let lastActiveTime = "lastActiveTime"
        static let sessionDuration = "sessionDuration"
        static let biometricEnabled = "biometricEnabled"
        static let passkeysEnabled = "passkeysEnabled"
        static let userEmail = "userEmail"
        static let userUID = "userUID"
        static let authToken = "authToken"
    }
    
    // User-specific settings keys
    private func userSpecificKey(_ baseKey: String, for userID: String) -> String {
        return "\(userID)_\(baseKey)"
    }
    
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Session Management
    var isUserLoggedIn: Bool {
        guard userDefaults.bool(forKey: Keys.isLoggedIn) else { return false }
        return !isSessionExpired
    }
    
    var sessionDuration: SessionDuration {
        get {
            guard let userID = currentUserID else { return .oneDay }
            let key = userSpecificKey(Keys.sessionDuration, for: userID)
            let duration = userDefaults.integer(forKey: key)
            return SessionDuration(rawValue: duration) ?? .oneDay
        }
        set {
            guard let userID = currentUserID else { return }
            let key = userSpecificKey(Keys.sessionDuration, for: userID)
            userDefaults.set(newValue.rawValue, forKey: key)
        }
    }
    
    var isBiometricEnabled: Bool {
        get { 
            guard let userID = currentUserID else { return false }
            let key = userSpecificKey(Keys.biometricEnabled, for: userID)
            return userDefaults.bool(forKey: key)
        }
        set { 
            guard let userID = currentUserID else { return }
            let key = userSpecificKey(Keys.biometricEnabled, for: userID)
            userDefaults.set(newValue, forKey: key)
        }
    }
    
    var isPasskeysEnabled: Bool {
        get { 
            guard let userID = currentUserID else { return false }
            let key = userSpecificKey(Keys.passkeysEnabled, for: userID)
            return userDefaults.bool(forKey: key)
        }
        set { 
            guard let userID = currentUserID else { return }
            let key = userSpecificKey(Keys.passkeysEnabled, for: userID)
            userDefaults.set(newValue, forKey: key)
        }
    }
    
    private var isSessionExpired: Bool {
        guard sessionDuration != .never else { return false }
        guard let userID = currentUserID else { return true }
        
        let key = userSpecificKey(Keys.lastActiveTime, for: userID)
        let lastActive = userDefaults.double(forKey: key)
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastActive
        
        return elapsed > Double(sessionDuration.rawValue)
    }
    
    private init() {
        setupSessionTimer()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        sessionTimer?.invalidate()
    }
    
    // MARK: - Login Methods
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        FirebaseManager.shared.signIn(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let userID):
                self?.saveSession(userID: userID, email: email)
                completion(.success(userID))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loginWithBiometrics(completion: @escaping (Result<String, Error>) -> Void) {
        guard isBiometricEnabled else {
            completion(.failure(AuthError.biometricNotEnabled))
            return
        }
        
        authenticateWithBiometrics { [weak self] success, error in
            if success {
                // Retrieve stored credentials and authenticate
                guard let userID = self?.keychain.get(Keys.userUID),
                      let email = self?.keychain.get(Keys.userEmail) else {
                    completion(.failure(AuthError.credentialsNotFound))
                    return
                }
                
                // Use stored auth token or re-authenticate silently
                self?.restoreFirebaseSession(userID: userID, email: email, completion: completion)
            } else {
                completion(.failure(error ?? AuthError.biometricFailed))
            }
        }
    }
    
    func loginWithPasskey(completion: @escaping (Result<String, Error>) -> Void) {
        guard isPasskeysEnabled else {
            completion(.failure(AuthError.passkeysNotEnabled))
            return
        }
        
        guard #available(iOS 16.0, *) else {
            completion(.failure(AuthError.passkeysNotSupported))
            return
        }
        
        // Create passkey assertion request
        let challenge = generateChallenge()
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "tripsync.app")
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        
        // Get stored user handle if available
        if let userHandle = keychain.get(Keys.userUID)?.data(using: .utf8) {
            request.allowedCredentials = [ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: userHandle)]
        }
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        // Store delegates as instance variables to prevent deallocation
        let authDelegate = PasskeyAuthDelegate(completion: completion)
        let contextProvider = PasskeyPresentationContextProvider()
        
        // Store delegates in the auth controller's associated objects to keep them alive
        objc_setAssociatedObject(authController, "delegate", authDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(authController, "contextProvider", contextProvider, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        authController.delegate = authDelegate
        authController.presentationContextProvider = contextProvider
        authController.performRequests()
    }
    
    func registerPasskey(for userID: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard #available(iOS 16.0, *) else {
            completion(.failure(AuthError.passkeysNotSupported))
            return
        }
        
        // Create passkey registration request
        let challenge = generateChallenge()
        let userIDData = userID.data(using: .utf8)!
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "tripsync.app")
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: email,
            userID: userIDData
        )
        
        request.displayName = email
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        // Store delegates as instance variables to prevent deallocation
        let registrationDelegate = PasskeyRegistrationDelegate(completion: completion)
        let contextProvider = PasskeyPresentationContextProvider()
        
        // Store delegates in the auth controller's associated objects to keep them alive
        objc_setAssociatedObject(authController, "delegate", registrationDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(authController, "contextProvider", contextProvider, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        authController.delegate = registrationDelegate
        authController.presentationContextProvider = contextProvider
        authController.performRequests()
    }
    
    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        let reason = "Use Face ID or Touch ID to access TripSync securely"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                completion(success, authError)
            }
        }
    }
    
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        default:
            return .none
        }
    }
    
    // MARK: - Session Management
    private func saveSession(userID: String, email: String) {
        userDefaults.set(true, forKey: Keys.isLoggedIn)
        
        // Store last active time with user-specific key
        let lastActiveKey = userSpecificKey(Keys.lastActiveTime, for: userID)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastActiveKey)
        
        // Store sensitive data in keychain
        keychain.save(userID, forKey: Keys.userUID)
        keychain.save(email, forKey: Keys.userEmail)
        
        startSessionTimer()
    }
    
    private func restoreFirebaseSession(userID: String, email: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if Firebase user is still valid
        if let currentUser = Auth.auth().currentUser, currentUser.uid == userID {
            updateLastActiveTime()
            completion(.success(userID))
        } else {
            // Session expired, need to re-authenticate
            completion(.failure(AuthError.sessionExpired))
        }
    }
    
    func updateLastActiveTime() {
        guard let userID = currentUserID else { return }
        let key = userSpecificKey(Keys.lastActiveTime, for: userID)
        userDefaults.set(Date().timeIntervalSince1970, forKey: key)
    }
    
    private func setupSessionTimer() {
        guard sessionDuration != .never else { return }
        
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            if self?.isSessionExpired == true {
                self?.logout()
            }
        }
    }
    
    private func startSessionTimer() {
        setupSessionTimer()
    }
    
    // MARK: - Logout
    func logout() {
        // Get current user ID before clearing session
        let userID = currentUserID
        
        // Clear Firebase session
        try? FirebaseManager.shared.signOut()
        
        // Clear local session
        userDefaults.removeObject(forKey: Keys.isLoggedIn)
        
        // Clear user-specific settings if we have a user ID
        if let userID = userID {
            let lastActiveKey = userSpecificKey(Keys.lastActiveTime, for: userID)
            userDefaults.removeObject(forKey: lastActiveKey)
            // Note: Keep user preferences (sessionDuration, biometricEnabled, passkeysEnabled) 
            // so they persist when user logs back in
        }
        
        // Clear sensitive keychain data
        keychain.delete(Keys.userUID)
        keychain.delete(Keys.userEmail)
        keychain.delete(Keys.authToken)
        
        sessionTimer?.invalidate()
        
        // Post notification for UI update
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    // MARK: - Re-authentication for Sensitive Actions
    func requireReAuthentication(for action: String, completion: @escaping (Bool) -> Void) {
        // Check if biometric is enabled and available
        if isBiometricEnabled && getBiometricType() != .none {
            authenticateWithBiometrics { success, error in
                completion(success)
            }
        } else {
            // Show password re-authentication
            showPasswordReAuthentication(for: action, completion: completion)
        }
    }
    
    private func showPasswordReAuthentication(for action: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            guard let topViewController = self.getTopViewController() else {
                completion(false)
                return
            }
            
            let reAuthVC = ReAuthViewController(actionTitle: action, completion: completion)
            reAuthVC.modalPresentationStyle = .overFullScreen
            reAuthVC.modalTransitionStyle = .crossDissolve
            topViewController.present(reAuthVC, animated: true)
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        
        if let navController = topController as? UINavigationController {
            return navController.visibleViewController
        }
        
        if let tabController = topController as? UITabBarController {
            return tabController.selectedViewController
        }
        
        return topController
    }
    
    // MARK: - User Settings Persistence
    func saveUserSettings(_ profile: UserProfile) {
        guard let userID = currentUserID else {
            print("❌ [AUTH MANAGER] Cannot save settings: No current user ID")
            return
        }

        print("🔄 [AUTH MANAGER] Starting user settings save for userID: \(userID)")
        print("📋 [AUTH MANAGER] Settings to save:")
        print("   - Name: \(profile.fullName)")
        print("   - Country: \(profile.homeCountry)")
        print("   - Currency: \(profile.homeCurrency)")
        print("   - Units: \(profile.preferredUnits.rawValue)")

        // Save locally first (offline-first approach)
        saveUserSettingsLocally(profile, userID: userID)

        // Sync to Firestore in background
        FirebaseManager.shared.saveAllUserSettings(profile) { result in
            switch result {
            case .success:
                print("✅ [AUTH MANAGER] Settings synced to Firestore successfully")
            case .failure(let error):
                print("❌ [AUTH MANAGER] Failed to sync settings to Firestore: \(error.localizedDescription)")
                // Local storage already saved, so user experience isn't affected
            }
        }
    }
    
    private func saveUserSettingsLocally(_ profile: UserProfile, userID: String) {
        print("💾 [AUTH MANAGER] Saving settings locally to UserDefaults...")

        // Save travel preferences
        if let travelData = try? JSONEncoder().encode(profile.travelPreferences) {
            let key = userSpecificKey("travelPreferences", for: userID)
            userDefaults.set(travelData, forKey: key)
            print("✅ [AUTH MANAGER] Travel preferences saved locally (key: \(key))")
            print("   - Trip length: \(profile.travelPreferences.defaultTripLength)")
        }

        // Save notification settings
        if let notificationData = try? JSONEncoder().encode(profile.notificationSettings) {
            let key = userSpecificKey("notificationSettings", for: userID)
            userDefaults.set(notificationData, forKey: key)
            print("✅ [AUTH MANAGER] Notification settings saved locally (key: \(key))")
            print("   - Push: \(profile.notificationSettings.pushNotifications)")
        }

        // Save privacy settings
        if let privacyData = try? JSONEncoder().encode(profile.privacySettings) {
            let key = userSpecificKey("privacySettings", for: userID)
            userDefaults.set(privacyData, forKey: key)
            print("✅ [AUTH MANAGER] Privacy settings saved locally (key: \(key))")
            print("   - Share location: \(profile.privacySettings.shareLocationData)")
        }

        // Save basic profile info
        let profileKey = userSpecificKey("userProfile", for: userID)
        let profileInfo = [
            "homeCountry": profile.homeCountry,
            "homeCurrency": profile.homeCurrency,
            "preferredUnits": profile.preferredUnits.rawValue,
            "languageCode": profile.languageCode,
            "timeZone": profile.timeZone
        ]
        userDefaults.set(profileInfo, forKey: profileKey)
        print("✅ [AUTH MANAGER] Profile info saved locally (key: \(profileKey))")
        print("   - Country: \(profile.homeCountry)")
        print("   - Currency: \(profile.homeCurrency)")
        print("   - Units: \(profile.preferredUnits.rawValue)")

        print("💾 [AUTH MANAGER] All local settings saved successfully")
    }
    
    func loadUserSettings(for profile: UserProfile, completion: @escaping (UserProfile) -> Void) {
        guard let userID = currentUserID else { 
            completion(profile)
            return 
        }
        
        // Try to load from Firestore first
        FirebaseManager.shared.loadAllUserSettings { [weak self] result in
            var finalProfile = profile
            
            switch result {
            case .success(let firestoreProfile):
                if let loadedProfile = firestoreProfile {
                    // Use Firestore data
                    finalProfile = loadedProfile
                    // Save to local storage for offline access
                    self?.saveUserSettingsLocally(loadedProfile, userID: userID)
                    print("✅ Settings loaded from Firestore")
                } else {
                    // No Firestore data, load from local storage
                    self?.loadUserSettingsLocally(for: &finalProfile, userID: userID)
                    print("📱 Settings loaded from local storage")
                }
            case .failure(let error):
                print("❌ Failed to load from Firestore: \(error.localizedDescription)")
                // Fall back to local storage
                self?.loadUserSettingsLocally(for: &finalProfile, userID: userID)
            }
            
            completion(finalProfile)
        }
    }
    
    private func loadUserSettingsLocally(for profile: inout UserProfile, userID: String) {
        // Load travel preferences
        let travelKey = userSpecificKey("travelPreferences", for: userID)
        if let travelData = userDefaults.data(forKey: travelKey),
           let travelPrefs = try? JSONDecoder().decode(TravelPreferences.self, from: travelData) {
            profile.travelPreferences = travelPrefs
        }
        
        // Load notification settings
        let notificationKey = userSpecificKey("notificationSettings", for: userID)
        if let notificationData = userDefaults.data(forKey: notificationKey),
           let notificationSettings = try? JSONDecoder().decode(NotificationSettings.self, from: notificationData) {
            profile.notificationSettings = notificationSettings
        }
        
        // Load privacy settings
        let privacyKey = userSpecificKey("privacySettings", for: userID)
        if let privacyData = userDefaults.data(forKey: privacyKey),
           let privacySettings = try? JSONDecoder().decode(PrivacySettings.self, from: privacyData) {
            profile.privacySettings = privacySettings
        }
        
        // Load basic profile info
        let profileKey = userSpecificKey("userProfile", for: userID)
        if let profileInfo = userDefaults.dictionary(forKey: profileKey) {
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
    }
    
    // MARK: - App Lifecycle
    @objc private func appDidBecomeActive() {
        if isUserLoggedIn {
            updateLastActiveTime()
        } else if userDefaults.bool(forKey: Keys.isLoggedIn) {
            // Session expired, logout
            logout()
        }
    }
    
    @objc private func appWillResignActive() {
        updateLastActiveTime()
    }
}

// MARK: - Supporting Types
enum BiometricType {
    case none
    case faceID
    case touchID
    case opticID
    
    var displayName: String {
        switch self {
        case .none: return "None Available"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "lock.fill"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        }
    }
}

enum AuthError: LocalizedError {
    case biometricNotEnabled
    case biometricFailed
    case passkeysNotEnabled
    case passkeysNotSupported
    case credentialsNotFound
    case sessionExpired
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .passkeysNotEnabled:
            return "Passkeys are not enabled"
        case .passkeysNotSupported:
            return "Passkeys require iOS 16.0 or later"
        case .credentialsNotFound:
            return "Stored credentials not found"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
    static let requirePasswordReauth = Notification.Name("requirePasswordReauth")
    static let sessionExpired = Notification.Name("sessionExpired")
}

// MARK: - Passkey Delegates
@available(iOS 16.0, *)
class PasskeyAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<String, Error>) -> Void
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // In a real implementation, you would verify the assertion with your server
            // For now, we'll extract the user identifier and treat it as successful auth
            let userID = String(data: credential.userID, encoding: .utf8) ?? ""
            completion(.success(userID))
        } else {
            completion(.failure(AuthError.notImplemented))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

@available(iOS 16.0, *)
class PasskeyRegistrationDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // In a real implementation, you would send the credential to your server for storage
            // For now, we'll just treat registration as successful
            print("Passkey registered with credential ID: \(credential.credentialID.base64EncodedString())")
            completion(.success(()))
        } else {
            completion(.failure(AuthError.notImplemented))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

class PasskeyPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}