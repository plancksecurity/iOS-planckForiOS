//
//  RecipientsBannerViewController.swift
//  pEpForiOS
//
//  Created by Martín Brude on 18/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class RecipientsBannerViewController: UIViewController {

    public var viewModel: RecipientsBannerViewModel?

    @IBOutlet private weak var unsecureRecipientsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let vm = viewModel else {
            // Valid case: The storyboard intanciates the VC before we have the chance to set a VM.
            return
        }
        unsecureRecipientsButton.setTitle(vm.buttonTitle, for: .normal)
    }

}
