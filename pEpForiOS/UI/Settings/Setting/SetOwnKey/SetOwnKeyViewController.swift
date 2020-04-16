//
//  SetOwnKeyViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SetOwnKeyViewController: UIViewController {
    @IBOutlet weak var fingerprintTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorTextField: UILabel!
    @IBOutlet weak var setOwnKeyButton: UIButton!
    

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }
    
    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    // MARK: - View life cycle etc.

    override func viewDidLoad() {
        super.viewDidLoad()
        convertTopEp(button: setOwnKeyButton)
        setOwnKeyButton.titleLabel?.numberOfLines = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        errorTextField.text = nil
        title = NSLocalizedString("Set Own Key", comment: "Set Own Key title")
    }

    // MARK: - Actions

    @IBAction func setOwnKeyButtonTapped(_ sender: Any) {
        viewModel.fingerprint = fingerprintTextField.text
        viewModel.email = emailTextField.text
        viewModel.setOwnKey()
        errorTextField.text = viewModel.rawErrorString
    }

    // MARK: - Private

    private let viewModel = SetOwnKeyViewModel()

    private func convertTopEp(button: UIButton) {
        button.backgroundColor = .white
        button.tintColor = .white
        button.setTitleColor(.pEpGreen, for: .normal)
    }
}
