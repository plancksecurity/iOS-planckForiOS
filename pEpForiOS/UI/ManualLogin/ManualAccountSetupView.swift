//
//  ManualAccountSetupView.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class ManualAccountSetupView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var secondTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var thirdTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var fourthTextField: AnimatedPlaceholderTextfield!

    //TODO: ALE  add doc
    @IBOutlet private weak var cancelLeftButton: UIButton!
    @IBOutlet private weak var continueRightButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!

    var textFieldsDelegate: UITextFieldDelegate? {
        didSet {
            updateTextFeildsDelegates()
        }
    }

    override func awakeFromNib() {
        setUpTextFieldsColor()
        hideSpecificDeviceButton()
        updateTextFeildsDelegates()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideSpecificDeviceButton),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    static func loadViewFromNib() -> ManualAccountSetupView? {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        guard let manualSetupView =
            nib.instantiate(withOwner: nil, options: nil).first as? ManualAccountSetupView else {
                Log.shared.errorAndCrash("Fail to load ManualAccountSetupView from xib")
                return nil
        }
        return manualSetupView
    }
}

// MARK: - Private

extension ManualAccountSetupView {
    private func setUpTextFieldsColor() {
        firstTextField.textColorWithText = .pEpGreen
        secondTextField.textColorWithText = .pEpGreen
        thirdTextField.textColorWithText = .pEpGreen
        fourthTextField.textColorWithText = .pEpGreen
    }

    @objc private func hideSpecificDeviceButton() {
        let isLandscape = UIDevice.current.orientation.isLandscape

        cancelLeftButton.isHidden = !isLandscape
        continueRightButton.isHidden = !isLandscape

        cancelButton.isHidden = isLandscape
        continueButton.isHidden = isLandscape
    }

    private func updateTextFeildsDelegates() {
        firstTextField?.delegate = textFieldsDelegate
        secondTextField?.delegate = textFieldsDelegate
        thirdTextField?.delegate = textFieldsDelegate
        fourthTextField?.delegate = textFieldsDelegate
    }
}
