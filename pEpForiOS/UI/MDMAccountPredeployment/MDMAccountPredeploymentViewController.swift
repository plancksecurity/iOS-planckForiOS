//
//  MDMAccountPredeploymentViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

class MDMAccountPredeploymentViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let viewModel = MDMAccountPredeploymentViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Here we use the font extension.
        messageLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        configureView(for: traitCollection)

        setFonts()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Here we react to changes in the font size.
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureView(for: traitCollection)
        }
    }

    private func configureView(for traitCollection: UITraitCollection) {
        // TODO: reload the view
    }

    private func setFonts() {
        messageLabel.setPEPFont(style: .callout, weight: .regular)
    }
}
