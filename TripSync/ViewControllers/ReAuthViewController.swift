//
//  ReAuthViewController.swift
//  TripSync
//
//  Created by Tien Tran on 17/9/2025.
//

import UIKit
import Firebase
import FirebaseAuth

class ReAuthViewController: UIViewController {
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let passwordTextField = UITextField()
    private let authenticateButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let stackView = UIStackView()
    
    // MARK: - Properties
    private let actionTitle: String
    private let completion: (Bool) -> Void
    
    // MARK: - Initialization
    init(actionTitle: String, completion: @escaping (Bool) -> Void) {
        self.actionTitle = actionTitle
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordTextField.becomeFirstResponder()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Container view
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.text = "Verify Identity"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        
        // Message label
        messageLabel.text = "Please enter your password to \(actionTitle.lowercased())"
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageLabel.textAlignment = .center
        messageLabel.textColor = UIColor.secondaryLabel
        messageLabel.numberOfLines = 0
        
        // Password text field
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.font = UIFont.systemFont(ofSize: 16)
        passwordTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordEntered), for: .editingDidEndOnExit)
        
        // Authenticate button
        authenticateButton.setTitle("Authenticate", for: .normal)
        authenticateButton.backgroundColor = UIColor.systemBlue
        authenticateButton.setTitleColor(UIColor.white, for: .normal)
        authenticateButton.layer.cornerRadius = 8
        authenticateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        authenticateButton.addTarget(self, action: #selector(authenticateButtonTapped), for: .touchUpInside)
        authenticateButton.isEnabled = false
        authenticateButton.alpha = 0.5
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(authenticateButton)
        stackView.addArrangedSubview(cancelButton)
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            authenticateButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    @objc private func textFieldChanged() {
        let hasText = !(passwordTextField.text?.isEmpty ?? true)
        authenticateButton.isEnabled = hasText
        authenticateButton.alpha = hasText ? 1.0 : 0.5
    }
    
    @objc private func passwordEntered() {
        if authenticateButton.isEnabled {
            authenticateButtonTapped()
        }
    }
    
    @objc private func authenticateButtonTapped() {
        guard let password = passwordTextField.text, !password.isEmpty else { return }
        
        // Disable button and show loading state
        authenticateButton.isEnabled = false
        authenticateButton.setTitle("Authenticating...", for: .normal)
        passwordTextField.isEnabled = false
        
        // Get current user's email
        guard let currentUser = Auth.auth().currentUser,
              let email = currentUser.email else {
            showError("Unable to verify credentials")
            return
        }
        
        // Re-authenticate with Firebase
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        currentUser.reauthenticate(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.showError("Invalid password. Please try again.")
                } else {
                    self?.authenticateSuccess()
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        completion(false)
        dismiss(animated: true)
    }
    
    private func authenticateSuccess() {
        completion(true)
        dismiss(animated: true)
    }
    
    private func showError(_ message: String) {
        // Reset button state
        authenticateButton.isEnabled = true
        authenticateButton.setTitle("Authenticate", for: .normal)
        passwordTextField.isEnabled = true
        passwordTextField.text = ""
        textFieldChanged()
        
        // Show error alert
        let alert = UIAlertController(title: "Authentication Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.passwordTextField.becomeFirstResponder()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let containerBottom = containerView.frame.maxY
        let viewHeight = view.frame.height
        
        if containerBottom > viewHeight - keyboardHeight {
            let offset = containerBottom - (viewHeight - keyboardHeight) + 20
            containerView.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        containerView.transform = .identity
    }
}