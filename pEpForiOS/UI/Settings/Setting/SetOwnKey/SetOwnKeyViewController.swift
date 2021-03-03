//
//  SetOwnKeyViewController.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SetOwnKeyViewController: UIViewController {
    private let viewModel = SetOwnKeyViewModel()

    @IBOutlet weak var fingerprintTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorTextField: UILabel!
    @IBOutlet weak var setOwnKeyButton: UIButton!
    @IBOutlet weak var fingerprintStackView: UIStackView!
    @IBOutlet weak var emailStackView: UIStackView!
    
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
        setOwnKeyButton.titleLabel?.setPEPFont(style: .callout, weight: .regular)
        setOwnKeyButton.titleLabel?.numberOfLines = 0
        configureView(for: traitCollection)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showNavigationBar()
        errorTextField.text = nil
        title = NSLocalizedString("Set Own Key", comment: "Set Own Key title")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
        configureView(for: traitCollection)
      }
    }
    
    private func configureView(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        let axis : NSLayoutConstraint.Axis = contentSize.isAccessibilityCategory ? .vertical : .horizontal
        emailStackView.axis = axis
        fingerprintStackView.axis = axis
    }
    
    // MARK: - Actions

    @IBAction func setOwnKeyButtonTapped(_ sender: Any) {
        viewModel.fingerprint = fingerprintTextField.text
        viewModel.email = emailTextField.text
        viewModel.setOwnKey { [weak self] errorString in
            // Weak self because the VC can out of scope by user's decision
            DispatchQueue.main.async {
                self?.errorTextField.text = errorString
            }
        }
    }

    // MARK: - Private

    private func convertTopEp(button: UIButton) {
        button.setTitleColor(.pEpGreen, for: .normal)
        button.backgroundColor = .clear
    }
}
