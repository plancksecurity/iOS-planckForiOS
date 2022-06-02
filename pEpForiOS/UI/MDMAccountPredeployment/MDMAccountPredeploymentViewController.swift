//
//  MDMAccountPredeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

class MDMAccountPredeploymentViewController: UIViewController {
    // MARK: - Storyboard

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let viewModel = MDMAccountPredeploymentViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Here we use the font extension.
        messageLabel.setPEPFont(style: .largeTitle, weight: .regular)
        configureView(for: traitCollection)

        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false

        viewModel.predeployAccounts()
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

extension MDMAccountPredeploymentViewController: MDMAccountPredeploymentViewModelDelegate {
    func handle(predeploymentError: MDMPredeployedError) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        messageLabel.text = NSLocalizedString("MDM Error",
                                              comment: "MDM Predeployment went wrong")
    }
}
