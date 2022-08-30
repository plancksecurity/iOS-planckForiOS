//
//  MDMAccountDeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class MDMAccountDeploymentViewController: UIViewController {
    // MARK: - Storyboard

    // TODO: Does not exist anymore, at the moment.
    @IBOutlet weak var messageLabel: UILabel!

    // TODO: Does not exist anymore, at the moment.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let viewModel = MDMAccountDeploymentViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Here we use the font extension.
        messageLabel.setPEPFont(style: .largeTitle, weight: .regular)
        configureView()

        if #available(iOS 13.0, *) {
            // Prevent the user to be able to "swipe down" this VC
            isModalInPresentation = true
        } else {
            // Modal is modal already?
        }

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        messageLabel.text = NSLocalizedString("Deploying Accounts",
                                              comment: "MDM deployment message")

        // TODO: Get the password from the user
        viewModel.deployAccount(password: "") { [weak self] result in
            guard let theSelf = self else {
                Log.shared.lostMySelf()
                return
            }

            theSelf.activityIndicator.stopAnimating()
            theSelf.activityIndicator.isHidden = true

            switch result {
            case .error(let message):
                theSelf.messageLabel.text = message
                // let this view hang there forever
            case .success(let message):
                theSelf.messageLabel.text = message
                theSelf.navigationController?.dismiss(animated: true)
            }
        }
    }

    // MARK: - Font Size

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Here we react to changes in the font size.
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureView()
        }
    }

    private func configureView() {
        view.setNeedsLayout()
    }
}
