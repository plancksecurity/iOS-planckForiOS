//
//  SetOwnKeyViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SetOwnKeyViewController: UIViewController {
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var fingerprintTextField: UITextField!
    @IBOutlet weak var setOwnKeyButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        convertTopEp(button: setOwnKeyButton)
    }

    @IBAction func setOwnKeyButtonTapped(_ sender: Any) {
        viewModel.userName = userNameTextField.text
        viewModel.fingerprint = fingerprintTextField.text
        viewModel.setOwnKey()
    }

    private let viewModel = SetOwnKeyViewModel()

    private func convertTopEp(button: UIButton) {
        button.backgroundColor = .white
        button.tintColor = .white
        button.setTitleColor(.pEpGreen, for: .normal)
    }
}
