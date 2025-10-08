//
//  AuthViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit
 import FirebaseAuth

class AuthViewController: UIViewController {
    
    // MARK: - UI Elements
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)
    private let forgotPasswordButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Properties
    private var isLoginMode = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupUI()
        setupConstraints()
        setupActions()
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupScrollView() {
        view.backgroundColor = UIColor.systemBackground
        
        // Add scroll view to main view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Scroll view constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupUI() {
        // Add all subviews to content view
        [logoImageView, titleLabel, subtitleLabel, emailTextField, passwordTextField, 
         loginButton, signUpButton, forgotPasswordButton, activityIndicator].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Configure logo image view
        logoImageView.image = UIImage(systemName: "airplane.circle.fill")
        logoImageView.tintColor = UIColor.systemBlue
        logoImageView.contentMode = .scaleAspectFit
        
        // Configure title label
        titleLabel.text = "Welcome to TripSync"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor.label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Configure subtitle label
        subtitleLabel.text = "Your travel companion"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        // Configure email text field
        setupTextField(emailTextField, placeholder: "Email", keyboardType: .emailAddress)
        
        // Configure password text field
        setupTextField(passwordTextField, placeholder: "Password", isSecure: true)
        
        // Configure login button
        setupPrimaryButton(loginButton, title: "Sign In")
        
        // Configure sign up button
        setupSecondaryButton(signUpButton, title: "Create Account")
        
        // Configure forgot password button
        forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
        forgotPasswordButton.setTitleColor(UIColor.systemBlue, for: .normal)
        forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        // Configure activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.systemBlue
        
        // Set up text field delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    private func setupTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) {
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = isSecure
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = UIColor.systemBackground
        
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightViewMode = .always
    }
    
    private func setupPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
    }
    
    private func setupSecondaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Logo constraints
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Subtitle label constraints
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Email text field constraints
            emailTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password text field constraints
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login button constraints
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 32),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Sign up button constraints
            signUpButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            signUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            signUpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Forgot password button constraints
            forgotPasswordButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 24),
            forgotPasswordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Activity indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 20),
            
            // Content view bottom constraint
            contentView.bottomAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 40)
        ])
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Actions
    @objc private func loginButtonTapped() {
        if isLoginMode {
            signInUser()
        } else {
            signUpUser()
        }
    }
    
    @objc private func signUpButtonTapped() {
        toggleAuthMode()
    }
    
    @objc private func forgotPasswordButtonTapped() {
        showForgotPasswordAlert()
    }
    
    // MARK: - Authentication Methods
    private func signInUser() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password.")
            return
        }
        
        startLoading()
        
        FirebaseManager.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                
                switch result {
                case .success(let userId):
                    print("Sign in successful for user: \(userId)")
                    self?.navigateToMainApp()
                case .failure(let error):
                    self?.showAlert(title: "Sign In Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func signUpUser() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password.")
            return
        }
        
        guard password.count >= 6 else {
            showAlert(title: "Error", message: "Password must be at least 6 characters long.")
            return
        }
        
        startLoading()
        
        FirebaseManager.shared.signUp(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.stopLoading()
                
                switch result {
                case .success(let userId):
                    print("Sign up successful for user: \(userId)")
                    // Initialize sample trips for new users
                    FirebaseManager.shared.initializeUserWithSampleTrips { result in
                        DispatchQueue.main.async {
                            // Navigate to main app regardless of sample trip initialization result
                            self?.navigateToMainApp()
                            
                            if case .failure(let error) = result {
                                print("Failed to initialize sample trips: \(error.localizedDescription)")
                            }
                        }
                    }
                case .failure(let error):
                    self?.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showForgotPasswordAlert() {
        let alert = UIAlertController(title: "Reset Password", message: "Enter your email address to reset your password.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        
        let resetAction = UIAlertAction(title: "Reset", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text, !email.isEmpty else {
                self?.showAlert(title: "Error", message: "Please enter a valid email address.")
                return
            }
            
            self?.resetPassword(email: email)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func resetPassword(email: String) {
        FirebaseManager.shared.resetPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.showAlert(title: "Reset Email Sent", message: "Please check your email for password reset instructions.")
                case .failure(let error):
                    self?.showAlert(title: "Reset Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func toggleAuthMode() {
        isLoginMode.toggle()
        
        if isLoginMode {
            loginButton.setTitle("Sign In", for: .normal)
            signUpButton.setTitle("Create Account", for: .normal)
            titleLabel.text = "Welcome Back"
            subtitleLabel.text = "Sign in to continue your journey"
        } else {
            loginButton.setTitle("Create Account", for: .normal)
            signUpButton.setTitle("Already have an account?", for: .normal)
            titleLabel.text = "Join TripSync"
            subtitleLabel.text = "Start planning your perfect trip"
        }
    }
    
    private func startLoading() {
        activityIndicator.startAnimating()
        loginButton.isEnabled = false
        signUpButton.isEnabled = false
    }
    
    private func stopLoading() {
        activityIndicator.stopAnimating()
        loginButton.isEnabled = true
        signUpButton.isEnabled = true
    }
    
    private func navigateToMainApp() {
        // Create the main tab bar controller programmatically
        let tabBarController = UITabBarController()
        
        // Create TripListViewController
        let tripListVC = TripListViewController()
        let tripListNavController = UINavigationController(rootViewController: tripListVC)
        tripListNavController.tabBarItem = UITabBarItem(title: "My Trips", image: UIImage(systemName: "suitcase"), tag: 0)
        
        // Create other view controllers as needed
        let discoverVC = UIViewController()
        discoverVC.view.backgroundColor = UIColor.systemBackground
        discoverVC.title = "Discover"
        let discoverNavController = UINavigationController(rootViewController: discoverVC)
        discoverNavController.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "globe"), tag: 1)
        
        let documentsVC = UIViewController()
        documentsVC.view.backgroundColor = UIColor.systemBackground
        documentsVC.title = "Documents"
        let documentsNavController = UINavigationController(rootViewController: documentsVC)
        documentsNavController.tabBarItem = UITabBarItem(title: "Documents", image: UIImage(systemName: "folder"), tag: 2)
        
        let profileVC = ProfileViewController()
        let profileNavController = UINavigationController(rootViewController: profileVC)
        profileNavController.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 3)
        
        // Set view controllers for tab bar
        tabBarController.viewControllers = [tripListNavController, discoverNavController, documentsNavController, profileNavController]
        
        // Set as root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            
            // Smooth transition
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginButtonTapped()
        }
        return true
    }
}
