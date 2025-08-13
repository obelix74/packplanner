//
//  LoadingStateManager.swift
//  PackPlanner
//
//  Created by Claude on UX Improvements
//

import UIKit
import SwiftUI

/**
 * LoadingStateManager - Centralized loading state and progress indication system
 * 
 * This utility provides consistent loading indicators, progress displays, and empty states
 * across both UIKit and SwiftUI interfaces, improving user experience during async operations.
 * 
 * Key Features:
 * - Thread-safe loading indicator management
 * - Support for both UIKit and SwiftUI loading states
 * - Progress indicators with percentage display
 * - Table view loading and empty states
 * - Customizable messages and actions
 * - Automatic cleanup and memory management
 * 
 * Usage:
 * UIKit:
 * - viewController.showLoading() / hideLoading()
 * - tableView.showLoadingState() / hideLoadingState()
 * - tableView.showEmptyState(title:message:actionTitle:action:)
 * 
 * SwiftUI:
 * - Use LoadingView(), ProgressHUD(), or EmptyStateView() directly
 * - Use performAsyncOperation for automatic loading state management
 */

// MARK: - Loading State Manager

class LoadingStateManager {
    static let shared = LoadingStateManager()
    
    private var activeLoadingViews: [UIView] = []
    private let queue = DispatchQueue(label: "com.packplanner.loading", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - UIKit Loading Indicators
    
    func showLoading(on viewController: UIViewController, message: String = "Loading...") {
        DispatchQueue.main.async {
            let loadingView = self.createLoadingView(message: message)
            viewController.view.addSubview(loadingView)
            
            // Auto layout constraints
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                loadingView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                loadingView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
                loadingView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                loadingView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
            ])
            
            // Animate in
            loadingView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                loadingView.alpha = 1
            }
            
            self.queue.async(flags: .barrier) {
                self.activeLoadingViews.append(loadingView)
            }
        }
    }
    
    func hideLoading(from viewController: UIViewController) {
        DispatchQueue.main.async {
            let loadingViews = viewController.view.subviews.filter { $0.tag == 9999 }
            
            for loadingView in loadingViews {
                UIView.animate(withDuration: 0.3, animations: {
                    loadingView.alpha = 0
                }, completion: { _ in
                    loadingView.removeFromSuperview()
                    
                    self.queue.async(flags: .barrier) {
                        self.activeLoadingViews.removeAll { $0 == loadingView }
                    }
                })
            }
        }
    }
    
    func showProgressHUD(on viewController: UIViewController, progress: Float, message: String) {
        DispatchQueue.main.async {
            // Remove existing progress views
            self.hideLoading(from: viewController)
            
            let progressView = self.createProgressView(progress: progress, message: message)
            viewController.view.addSubview(progressView)
            
            // Auto layout constraints
            progressView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                progressView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                progressView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
                progressView.widthAnchor.constraint(equalToConstant: 200),
                progressView.heightAnchor.constraint(equalToConstant: 120)
            ])
            
            // Animate in
            progressView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                progressView.alpha = 1
            }
        }
    }
    
    // MARK: - Table View Loading States
    
    func showTableViewLoading(on tableView: UITableView, message: String = "Loading data...") {
        DispatchQueue.main.async {
            let loadingView = self.createTableLoadingView(message: message)
            tableView.backgroundView = loadingView
            tableView.separatorStyle = .none
        }
    }
    
    func hideTableViewLoading(from tableView: UITableView) {
        DispatchQueue.main.async {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
    
    func showEmptyState(on tableView: UITableView, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let emptyView = self.createEmptyStateView(title: title, message: message, actionTitle: actionTitle, action: action)
            tableView.backgroundView = emptyView
            tableView.separatorStyle = .none
        }
    }
    
    // MARK: - SwiftUI Loading States
    
    func performAsyncOperation<T>(
        operation: @escaping () async throws -> T,
        onStart: @escaping () -> Void = {},
        onSuccess: @escaping (T) -> Void,
        onError: @escaping (Error) -> Void,
        onComplete: @escaping () -> Void = {}
    ) {
        Task {
            DispatchQueue.main.async {
                onStart()
            }
            
            do {
                let result = try await operation()
                DispatchQueue.main.async {
                    onSuccess(result)
                    onComplete()
                }
            } catch {
                DispatchQueue.main.async {
                    onError(error)
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createLoadingView(message: String) -> UIView {
        let containerView = UIView()
        containerView.tag = 9999
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 10
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ])
        
        return containerView
    }
    
    private func createProgressView(progress: Float, message: String) -> UIView {
        let containerView = UIView()
        containerView.tag = 9999
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 10
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = progress
        progressView.tintColor = .systemBlue
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        let percentLabel = UILabel()
        percentLabel.text = "\(Int(progress * 100))%"
        percentLabel.textColor = .white
        percentLabel.font = .systemFont(ofSize: 14)
        percentLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [messageLabel, progressView, percentLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        return containerView
    }
    
    private func createTableLoadingView(message: String) -> UIView {
        let containerView = UIView()
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .systemBlue
        activityIndicator.startAnimating()
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [activityIndicator, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    private func createEmptyStateView(title: String, message: String, actionTitle: String?, action: (() -> Void)?) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        var arrangedSubviews: [UIView] = [titleLabel, messageLabel]
        
        if let actionTitle = actionTitle, let action = action {
            let actionButton = UIButton(type: .system)
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            actionButton.backgroundColor = .systemBlue
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.cornerRadius = 8
            actionButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
            
            actionButton.addAction(UIAction { _ in action() }, for: .touchUpInside)
            
            arrangedSubviews.append(actionButton)
        }
        
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -40)
        ])
        
        return containerView
    }
}

// MARK: - SwiftUI Loading Views

struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
    }
}

struct ProgressHUD: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 16, weight: .medium))
            
            VStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    func showLoading(message: String = "Loading...") {
        LoadingStateManager.shared.showLoading(on: self, message: message)
    }
    
    func hideLoading() {
        LoadingStateManager.shared.hideLoading(from: self)
    }
    
    func showProgress(progress: Float, message: String) {
        LoadingStateManager.shared.showProgressHUD(on: self, progress: progress, message: message)
    }
}

// MARK: - UITableView Extension

extension UITableView {
    func showLoadingState(message: String = "Loading data...") {
        LoadingStateManager.shared.showTableViewLoading(on: self, message: message)
    }
    
    func hideLoadingState() {
        LoadingStateManager.shared.hideTableViewLoading(from: self)
    }
    
    func showEmptyState(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        LoadingStateManager.shared.showEmptyState(on: self, title: title, message: message, actionTitle: actionTitle, action: action)
    }
}