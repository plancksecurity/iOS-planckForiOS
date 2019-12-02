//
//  ManualAccountSetupView.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Protocol to handle ManualAccountSetupView events
protocol ManualAccountSetupViewDelegate: class {
    func didPressCancelButton()
    func didPressNextButton()
    func didChangePEPSyncSwitch(isOn: Bool)

    func didChangeFirst(_ textField: UITextField)
    func didChangeSecond(_ textField: UITextField)
    func didChangeThierd(_ textField: UITextField)
    func didChangeFourth(_ textField: UITextField)
}

extension ManualAccountSetupViewDelegate {
    func didChangePEPSyncSwitch(isOn: Bool){}
}

// Did not crate a nested class for LoginScrollView, since its not visible from Interface builder

/// View used to set uo a manual account, during the login process
final class ManualAccountSetupView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var secondTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var thirdTextField: AnimatedPlaceholderTextfield!
    @IBOutlet weak var fourthTextField: AnimatedPlaceholderTextfield!

    @IBOutlet weak var cancelLeftButton: UIButton!
    @IBOutlet weak var nextRightButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pEpSyncSwitch: UISwitch!
    @IBOutlet weak var pEpSyncView: UIView!
    @IBOutlet weak var pEpSyncViewRight: UIView!
    
    @IBOutlet weak var scrollView: LoginScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!

    weak var delegate: ManualAccountSetupViewDelegate?

    var textFieldsDelegate: UITextFieldDelegate? {
        didSet {
            updateTextFeildsDelegates()
        }
    }

    override func awakeFromNib() {
        setUpTextFieldsColor()
        hideSpecificDeviceButton()
        updateTextFeildsDelegates()
        scrollView.loginScrollViewDelegate = self

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
    @IBAction func didPressCancel(_ sender: UIButton) {
        delegate?.didPressCancelButton()
    }

    @IBAction func didPressNext(_ sender: UIButton) {
        delegate?.didPressNextButton()
    }

    @IBAction func didChange(_ sender: UITextField) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            scrollView.scrollAndMakeVisible(sender)
        }
        switch sender {
        case firstTextField:
            delegate?.didChangeFirst(sender)
        case secondTextField:
            delegate?.didChangeSecond(sender)
        case thirdTextField:
            delegate?.didChangeThierd(sender)
        case fourthTextField:
            delegate?.didChangeFourth(sender)
        default:
            Log.shared.errorAndCrash("didChange should handle all cases in ManualAccountSetupView")
        }
    }

    @IBAction func didChangePEPSyncSwitch(_ sender: UISwitch) {
        delegate?.didChangePEPSyncSwitch(isOn: sender.isOn)
    }
}

// MARK: - LoginScrollViewDelegate

extension ManualAccountSetupView: LoginScrollViewDelegate {
    var firstResponder: UIView? {
        get { textFields().first { $0.isFirstResponder }}
    }

    var bottomConstraint: NSLayoutConstraint {
        get { scrollViewBottomConstraint }
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
        let isLandscape = self.isLandscape()

        cancelLeftButton?.isHidden = !isLandscape
        nextRightButton?.isHidden = !isLandscape

        cancelButton?.isHidden = isLandscape
        nextButton?.isHidden = isLandscape
    }

    private func updateTextFeildsDelegates() {
        firstTextField?.delegate = textFieldsDelegate
        secondTextField?.delegate = textFieldsDelegate
        thirdTextField?.delegate = textFieldsDelegate
        fourthTextField?.delegate = textFieldsDelegate
    }

    private func textFields() -> [UITextField] {
        return [firstTextField, secondTextField, thirdTextField, fourthTextField]
    }

    private func isLandscape() -> Bool {
        if UIDevice.current.orientation.isFlat  {
            return UIApplication.shared.statusBarOrientation.isLandscape
        } else {
            return UIDevice.current.orientation.isLandscape
        }
    }
}
