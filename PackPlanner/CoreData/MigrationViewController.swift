//
//  MigrationViewController.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import UIKit

class MigrationViewController: UIViewController {

    // MARK: - UI Components

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0.0
        return progress
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Upgrading PackPlanner"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Preparing your data..."
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill")
        imageView.tintColor = .systemBlue
        return imageView
    }()

    // MARK: - Properties

    var onMigrationComplete: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startMigration()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(progressView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Icon
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Progress View
            progressView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            // Activity Indicator
            activityIndicator.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Migration

    private func startMigration() {
        activityIndicator.startAnimating()

        // First, backup Realm
        let backupSuccess = RealmToCoreDataMigration.shared.backupRealmFile()
        if !backupSuccess {
            showAlert(title: "Backup Warning", message: "Could not create backup, but migration will proceed.")
        }

        // Start migration
        RealmToCoreDataMigration.shared.migrate(
            progressHandler: { [weak self] message, progress in
                DispatchQueue.main.async {
                    self?.updateProgress(message: message, progress: Float(progress))
                }
            },
            completion: { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.handleMigrationComplete(success: success, error: error)
                }
            }
        )
    }

    private func updateProgress(message: String, progress: Float) {
        messageLabel.text = message
        progressView.setProgress(progress, animated: true)

        if progress >= 1.0 {
            activityIndicator.stopAnimating()
            iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            iconImageView.tintColor = .systemGreen
        }
    }

    private func handleMigrationComplete(success: Bool, error: Error?) {
        activityIndicator.stopAnimating()

        if success {
            iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            iconImageView.tintColor = .systemGreen
            titleLabel.text = "Upgrade Complete!"
            messageLabel.text = "Your data has been successfully migrated."

            // Wait a moment, then dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.onMigrationComplete?()
            }
        } else {
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            iconImageView.tintColor = .systemRed
            titleLabel.text = "Migration Failed"
            messageLabel.text = error?.localizedDescription ?? "An unknown error occurred."

            // Show retry button
            showRetryButton()
        }
    }

    private func showRetryButton() {
        let retryButton = UIButton(type: .system)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        retryButton.addTarget(self, action: #selector(retryMigration), for: .touchUpInside)

        view.addSubview(retryButton)

        NSLayoutConstraint.activate([
            retryButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func retryMigration() {
        // Reset UI
        iconImageView.image = UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill")
        iconImageView.tintColor = .systemBlue
        titleLabel.text = "Upgrading PackPlanner"
        messageLabel.text = "Preparing your data..."
        progressView.progress = 0.0

        // Remove retry button if exists
        view.subviews.filter { $0 is UIButton }.forEach { $0.removeFromSuperview() }

        // Restart migration
        startMigration()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
