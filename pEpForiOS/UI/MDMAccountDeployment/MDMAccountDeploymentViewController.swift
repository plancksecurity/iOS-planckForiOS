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

    @IBOutlet weak var stackView: UIStackView!

    let viewModel = MDMAccountDeploymentViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

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
    }

    // MARK: - Build the UI

    func setupUI() {
        // TODO: Here we use the font extension.
        // messageLabel.setPEPFont(style: .largeTitle, weight: .regular)

        configureView()
    }

    // MARK: - Actions

    @IBAction func deployButtonTapped() {
    }

    // MARK: - Deploy

    func deploy() {
        let _ = NSLocalizedString("Deploying Accounts",
                                              comment: "MDM deployment message")

        // TODO: Get the password from the user
        viewModel.deployAccount(password: "") { [weak self] result in
            guard let theSelf = self else {
                Log.shared.lostMySelf()
                return
            }

            switch result {
            case .error(let message):
                // TODO
                break
            case .success(let message):
                // TODO
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
