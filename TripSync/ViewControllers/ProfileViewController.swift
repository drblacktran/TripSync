//
//  ProfileViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit
import Firebase
import LocalAuthentication

class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let countryLabel = UILabel()
    private let currencyLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Properties
    private var userProfile: UserProfile?
    private var settingsSections: [SettingsSection] = []
    private let authManager = AuthenticationManager.shared
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadUserProfile()
        setupSettingsSections()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure table view height is updated after layout
        if settingsSections.count > 0 {
            updateTableViewHeight()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Add sign out button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        setupHeaderView()
        setupTableViewLayout()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 16
        contentView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile image
        profileImageView.backgroundColor = UIColor.systemBlue
        profileImageView.layer.cornerRadius = 50
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        headerView.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add camera icon overlay
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = UIColor.white
        cameraIcon.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        cameraIcon.layer.cornerRadius = 15
        cameraIcon.layer.masksToBounds = true
        cameraIcon.contentMode = .center
        profileImageView.addSubview(cameraIcon)
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.label
        headerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Country label with flag
        countryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        countryLabel.textAlignment = .center
        countryLabel.textColor = UIColor.secondaryLabel
        headerView.addSubview(countryLabel)
        countryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Currency label
        currencyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        currencyLabel.textAlignment = .center
        currencyLabel.textColor = UIColor.secondaryLabel
        currencyLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        currencyLabel.layer.cornerRadius = 8
        currencyLabel.layer.masksToBounds = true
        headerView.addSubview(currencyLabel)
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            cameraIcon.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -5),
            cameraIcon.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: -5),
            cameraIcon.widthAnchor.constraint(equalToConstant: 30),
            cameraIcon.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countryLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            countryLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            currencyLabel.topAnchor.constraint(equalTo: countryLabel.bottomAnchor, constant: 8),
            currencyLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            currencyLabel.widthAnchor.constraint(equalToConstant: 80),
            currencyLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupTableViewLayout() {
        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create height constraint that we can update later
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 600)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableViewHeightConstraint!,
            
            contentView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.isScrollEnabled = false // Keep disabled since parent scroll view handles scrolling
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
    }
    
    // MARK: - Data Loading
    private func loadUserProfile() {
        guard let currentUser = FirebaseManager.shared.getCurrentUser() else {
            return
        }
        
        // For now, create a default profile
        userProfile = UserProfile(
            id: currentUser.uid,
            firstName: "Tien",
            lastName: "Tran",
            email: currentUser.email ?? "user@tripsync.com",
            homeCountry: "Australia"
        )
        
        updateHeaderUI()
    }
    
    private func updateHeaderUI() {
        guard let profile = userProfile else { return }
        
        nameLabel.text = profile.fullName
        countryLabel.text = "\(profile.countryFlag) \(profile.homeCountry)"
        currencyLabel.text = profile.homeCurrency
        
        // Set default profile image with initials
        let initials = "\(profile.firstName.prefix(1))\(profile.lastName.prefix(1))".uppercased()
        profileImageView.image = createInitialsImage(initials: initials)
    }
    
    private func createInitialsImage(initials: String) -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemBlue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = initials.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        initials.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Settings Sections
    private func setupSettingsSections() {
        settingsSections = [
            SettingsSection(title: "Account", items: [
                SettingsItem(title: "Edit Profile", subtitle: "Update your personal information", icon: "person.fill", action: .navigation),
                SettingsItem(title: "Change Password", subtitle: "Update your account password", icon: "lock.fill", action: .navigation),
                SettingsItem(title: "Email Preferences", subtitle: "Manage notification emails", icon: "envelope.fill", action: .navigation)
            ]),
            
            SettingsSection(title: "Travel Preferences", items: [
                SettingsItem(title: "Home Country", subtitle: userProfile?.homeCountry ?? "Australia", icon: "globe", action: .navigation),
                SettingsItem(title: "Currency", subtitle: userProfile?.homeCurrency ?? "AUD", icon: "dollarsign.circle.fill", action: .navigation),
                SettingsItem(title: "Units", subtitle: userProfile?.preferredUnits.displayName ?? "Metric", icon: "ruler.fill", action: .navigation),
                SettingsItem(title: "Default Trip Length", subtitle: "\(userProfile?.travelPreferences.defaultTripLength ?? 7) days", icon: "calendar", action: .navigation)
            ]),
            
            SettingsSection(title: "Notifications", items: [
                SettingsItem(title: "Push Notifications", subtitle: "Receive trip reminders", icon: "bell.fill", action: .toggle, isEnabled: userProfile?.notificationSettings.pushNotifications ?? true),
                SettingsItem(title: "Flight Updates", subtitle: "Real-time flight status", icon: "airplane", action: .toggle, isEnabled: userProfile?.notificationSettings.flightUpdates ?? true),
                SettingsItem(title: "Budget Alerts", subtitle: "Spending notifications", icon: "chart.bar.fill", action: .toggle, isEnabled: userProfile?.notificationSettings.budgetAlerts ?? true)
            ]),
            
            SettingsSection(title: "Privacy & Security", items: [
                SettingsItem(title: "Session Duration", subtitle: authManager.sessionDuration.displayName, icon: "clock.fill", action: .navigation),
                SettingsItem(title: "Biometric Login", subtitle: getBiometricSubtitle(), icon: authManager.getBiometricType().iconName, action: .toggle, isEnabled: authManager.isBiometricEnabled),
                SettingsItem(title: "Passkeys", subtitle: "Secure passwordless login", icon: "key.fill", action: .toggle, isEnabled: authManager.isPasskeysEnabled),
                SettingsItem(title: "Share Location", subtitle: "For weather and recommendations", icon: "location.fill", action: .toggle, isEnabled: userProfile?.privacySettings.shareLocationData ?? true),
                SettingsItem(title: "Analytics", subtitle: "Help improve TripSync", icon: "chart.line.uptrend.xyaxis", action: .toggle, isEnabled: userProfile?.privacySettings.analyticsOptIn ?? true),
                SettingsItem(title: "Marketing Emails", subtitle: "Travel deals and updates", icon: "envelope.badge", action: .toggle, isEnabled: userProfile?.privacySettings.marketingEmails ?? false)
            ]),
            
            SettingsSection(title: "Support", items: [
                SettingsItem(title: "Help & FAQ", subtitle: "Get answers to common questions", icon: "questionmark.circle.fill", action: .navigation),
                SettingsItem(title: "Contact Support", subtitle: "Get help from our team", icon: "message.fill", action: .navigation),
                SettingsItem(title: "About TripSync", subtitle: "Version 1.0.0", icon: "info.circle.fill", action: .navigation)
            ])
        ]
        
        tableView.reloadData()
        updateTableViewHeight()
    }
    
    private func updateTableViewHeight() {
        // Force layout to get accurate size
        tableView.layoutIfNeeded()
        
        // Calculate content height
        let contentHeight = tableView.contentSize.height
        
        // Update the existing height constraint
        tableViewHeightConstraint?.constant = contentHeight
        
        // Force layout update
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    @objc private func profileImageTapped() {
        let alert = UIAlertController(title: "Update Profile Photo", message: "Choose how you'd like to update your profile photo", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            // TODO: Implement camera
            print("Take photo selected")
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            // TODO: Implement photo library
            print("Photo library selected")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = profileImageView
            popover.sourceRect = profileImageView.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func signOutTapped() {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            self.performSignOut()
        })
        
        present(alert, animated: true)
    }
    
    private func performSignOut() {
        authManager.logout()
        
        // Navigate back to auth screen
        DispatchQueue.main.async {
            let authVC = AuthViewController()
            let navController = UINavigationController(rootViewController: authVC)
            navController.modalPresentationStyle = .fullScreen
            
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = navController
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsSections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = settingsSections[indexPath.section].items[indexPath.row]
        
        switch item.action {
        case .toggle:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            cell.configure(with: item)
            cell.switchToggleHandler = { [weak self] isOn in
                self?.handleToggle(for: item, isEnabled: isOn)
            }
            return cell
            
        case .navigation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = item.subtitle
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = UIImage(systemName: item.icon)
            cell.imageView?.tintColor = UIColor.systemBlue
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = settingsSections[indexPath.section].items[indexPath.row]
        
        if item.action == .navigation {
            handleNavigation(for: item)
        }
    }
    
    private func handleToggle(for item: SettingsItem, isEnabled: Bool) {
        switch item.title {
        case "Biometric Login":
            handleBiometricToggle(isEnabled: isEnabled)
        case "Passkeys":
            handlePasskeyToggle(isEnabled: isEnabled)
        default:
            print("Toggle \(item.title): \(isEnabled)")
            // TODO: Update other user preferences in Firebase
        }
    }
    
    private func handleNavigation(for item: SettingsItem) {
        switch item.title {
        case "Session Duration":
            showSessionDurationPicker()
        case "Change Password":
            showChangePasswordAlert()
        default:
            print("Navigate to: \(item.title)")
            // TODO: Implement other specific settings screens
        }
    }
    
    // MARK: - Security Settings Helpers
    private func getBiometricSubtitle() -> String {
        let biometricType = authManager.getBiometricType()
        if biometricType == .none {
            return "Not available on this device"
        }
        return authManager.isBiometricEnabled ? "Enabled for \(biometricType.displayName)" : "Use \(biometricType.displayName) to sign in"
    }
    
    private func handleBiometricToggle(isEnabled: Bool) {
        let biometricType = authManager.getBiometricType()
        
        guard biometricType != .none else {
            showAlert(title: "Biometric Not Available", message: "This device doesn't support biometric authentication.")
            // Refresh the table to reset the switch
            setupSettingsSections()
            return
        }
        
        if isEnabled {
            // Test biometric authentication before enabling
            authManager.authenticateWithBiometrics { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.authManager.isBiometricEnabled = true
                        self?.showAlert(title: "Biometric Login Enabled", message: "You can now use \(biometricType.displayName) to sign into TripSync.")
                    } else {
                        self?.showAlert(title: "Authentication Failed", message: error?.localizedDescription ?? "Could not verify your identity.")
                        // Refresh the table to reset the switch
                        self?.setupSettingsSections()
                    }
                }
            }
        } else {
            authManager.isBiometricEnabled = false
            showAlert(title: "Biometric Login Disabled", message: "You will need to use your password to sign in.")
        }
    }
    
    private func handlePasskeyToggle(isEnabled: Bool) {
        if #available(iOS 16.0, *) {
            if isEnabled {
                // Attempt to register a passkey
                guard let currentUser = FirebaseManager.shared.getCurrentUser() else {
                    showAlert(title: "Error", message: "Unable to register passkey. Please ensure you're signed in.")
                    setupSettingsSections()
                    return
                }
                
                authManager.registerPasskey(for: currentUser.uid, email: currentUser.email ?? "") { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self?.authManager.isPasskeysEnabled = true
                            self?.showAlert(title: "Passkey Registered", message: "You can now use passkeys to sign into TripSync.")
                        case .failure(let error):
                            self?.showAlert(title: "Passkey Registration Failed", message: error.localizedDescription)
                            self?.setupSettingsSections()
                        }
                    }
                }
            } else {
                authManager.isPasskeysEnabled = false
                showAlert(title: "Passkeys Disabled", message: "You will need to use your password or biometric authentication to sign in.")
            }
        } else {
            showAlert(title: "Passkeys Not Available", message: "Passkeys require iOS 16.0 or later.")
            setupSettingsSections()
        }
    }
    
    private func showSessionDurationPicker() {
        let alert = UIAlertController(title: "Session Duration", message: "Choose how long you stay signed in", preferredStyle: .actionSheet)
        
        for duration in SessionDuration.allCases {
            let isSelected = authManager.sessionDuration == duration
            let title = isSelected ? "✓ \(duration.displayName)" : duration.displayName
            
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.authManager.sessionDuration = duration
                self?.setupSettingsSections()
                
                let message = duration == .never ? "You will stay signed in until you manually sign out." : "You will be automatically signed out after \(duration.displayName.lowercased()) of inactivity."
                self?.showAlert(title: "Session Duration Updated", message: message)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func showChangePasswordAlert() {
        authManager.requireReAuthentication(for: "Change Password") { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(title: "Change Password", message: "This feature will be implemented in a future update.")
                } else {
                    self?.showAlert(title: "Authentication Required", message: "You must verify your identity to change your password.")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Settings Models
struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let title: String
    let subtitle: String
    let icon: String
    let action: SettingsAction
    let isEnabled: Bool
    
    init(title: String, subtitle: String, icon: String, action: SettingsAction, isEnabled: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
    }
}

enum SettingsAction {
    case navigation
    case toggle
}

// MARK: - Custom Switch Cell
class SwitchTableViewCell: UITableViewCell {
    private let switchControl = UISwitch()
    var switchToggleHandler: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupSwitch()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSwitch() {
        switchControl.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        accessoryView = switchControl
    }
    
    func configure(with item: SettingsItem) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
        imageView?.image = UIImage(systemName: item.icon)
        imageView?.tintColor = UIColor.systemBlue
        switchControl.isOn = item.isEnabled
    }
    
    @objc private func switchToggled() {
        switchToggleHandler?(switchControl.isOn)
    }
}