//
//  MDMAccountPredeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class MDMAccountPredeploymentViewController: UIViewController {
    // MARK: - Storyboard

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let viewModel = MDMAccountPredeploymentViewModel()

    static let storyboardId = "mdmAccountPredeploymentViewController"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Here we use the font extension.
        messageLabel.setPEPFont(style: .largeTitle, weight: .regular)
        configureView(for: traitCollection)

        if #available(iOS 13.0, *) {
            // Prevent the user to be able to "swipe down" this VC
            isModalInPresentation = true
        } else {
            // Modal is modal already?
        }

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        messageLabel.text = NSLocalizedString("Deploying Accounts",
                                              comment: "MDM predeployment message")

        viewModel.predeployAccounts { [weak self] maybeError in
            guard let theSelf = self else {
                Log.shared.lostMySelf()
                return
            }
            theSelf.activityIndicator.stopAnimating()
            theSelf.activityIndicator.isHidden = true

            if let error = maybeError {
                switch error {
                case .networkError:
                    theSelf.messageLabel.text = NSLocalizedString("MDM Error: Could not connect to account",
                                                                  comment: "MDM predeployment error")
                case .malformedAccountData:
                    theSelf.messageLabel.text = NSLocalizedString("MDM Error: Wrong Account Data",
                                                                  comment: "MDM predeployment error")
                }
            } else {
                theSelf.messageLabel.text = NSLocalizedString("Accounts Deployed",
                                                              comment: "MDM predeployment message, all ok")
                theSelf.navigationController?.dismiss(animated: true)
            }
        }
    }

    // MARK: - Font Size

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Here we react to changes in the font size.
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureView(for: traitCollection)
        }
    }

    private func configureView(for traitCollection: UITraitCollection) {
        view.setNeedsLayout()
    }
}
