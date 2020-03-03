//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// View that lists all imported client certificates and let's the user choose one.
final class ClientCertificateManagementViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!

    public var viewModel: ClientCertificateManagementViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupViewModel()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewController {
    private func setupViewModel() {
        guard viewModel == nil else {
            // Already setup.
            // Nothing to do.
            return
        }
        viewModel = ClientCertificateManagementViewModel()
    }

    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
    }
}
