//
//  TrustManagementViewController.swift
//  pEp
//
//  Created by Martin Brude on 7/3/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class TrustBannerViewController: UIViewController {

    public var viewModel: TrustBannerViewModel? {
        didSet {
            setupUI()
        }
    }

    @IBOutlet public private(set) weak var trustButton: UIButton?

    @IBAction private func trustButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleTrustButtonPressed()
    }
}

// MARK: - Private

extension TrustBannerViewController {

    private func setupUI() {
        trustButton?.setPEPFont(style: .footnote, weight: .regular)
        guard let vm = viewModel else {
            // No view model.
            trustButton?.setTitle("", for: .normal)
            return
        }
        trustButton?.setTitle(vm.buttonTitle, for: .normal)
    }
}
