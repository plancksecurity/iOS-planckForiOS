//
//  RecipientsBannerViewController.swift
//  pEpForiOS
//
//  Created by Martín Brude on 18/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class RecipientsBannerViewController: UIViewController {

    public var viewModel: RecipientsBannerViewModel? {
        didSet {
            setupUI()
        }
    }

    @IBOutlet public private(set) weak var unsecureRecipientsButton: UIButton!

    @IBAction private func unsecureRecipientsButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleRecipientsButtonPressed()
    }
}

// MARK: - Private

extension RecipientsBannerViewController {

    private func setupUI() {
        unsecureRecipientsButton.setPEPFont(style: .footnote, weight: .regular)
        guard let vm = viewModel else {
            // No view model.
            unsecureRecipientsButton.setTitle("", for: .normal)
            return
        }
        unsecureRecipientsButton.setTitle(vm.buttonTitle, for: .normal)
    }

}
