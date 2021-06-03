//
//  PEPAlertViewControllerWithTextView.swift
//  pEp
//
//  Created by Martín Brude on 24/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class PEPAlertWithTextViewViewController: UIViewController {

    @IBOutlet private weak var keyInputView: KeyInputView!
    @IBOutlet private weak var alertTitle: UILabel!
    @IBOutlet private weak var alertMessage: UILabel!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private(set) weak var fingerprintTextView: AlertTextView!
    @IBOutlet private(set) weak var emailTextView: AlertTextView!

    private var viewModel: PEPAlertViewModelProtocol
    private var titleString: String?
    private var message: String?
    private var action = [PEPUIAlertAction]()
    private static let storyboardId = "PEPAlertWithTextViewViewController"

    public final var fingerprintPlaceholderText: String?
    public final var emailPlaceholderText: String?

    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()

        setUp(title: titleString, message: message)
        setUp(actions: action)
        fingerprintTextView.placeholderText = fingerprintPlaceholderText ?? ""
        emailTextView.placeholderText = emailPlaceholderText ?? ""
        fingerprintTextView.delegate = self
        emailTextView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                keyInputView.backgroundColor = .secondarySystemBackground
            } else {
                keyInputView.backgroundColor = .systemGroupedBackground
            }
        } else {
            keyInputView.backgroundColor = .white
        }
    }

    /// Add an action to the alert view controller.
    /// - Parameter action: The action to be executed
    public func add(action: PEPUIAlertAction) {
        self.action.append(action)
    }
}

// MARK: - Instanciation

extension PEPAlertWithTextViewViewController {

    static func fromStoryboard(title: String? = nil,
                               message: String? = nil,
                               viewModel: PEPAlertViewModelProtocol = PEPAlertViewModel())
    -> PEPAlertWithTextViewViewController? {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: .main)
        guard let pepAlertWithTextViewViewController = storyboard.instantiateViewController(
                withIdentifier: PEPAlertWithTextViewViewController.storyboardId) as? PEPAlertWithTextViewViewController else {
            Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertWithTextViewViewController")
            return nil
        }
        pepAlertWithTextViewViewController.viewModel = viewModel
        pepAlertWithTextViewViewController.titleString = title
        pepAlertWithTextViewViewController.message = message
        DispatchQueue.main.async {
            pepAlertWithTextViewViewController.modalPresentationStyle = .overFullScreen
            pepAlertWithTextViewViewController.modalTransitionStyle = .crossDissolve
        }
        return pepAlertWithTextViewViewController
    }
}

// MARK: - Keyboard Related Issues

extension PEPAlertWithTextViewViewController {

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        view.frame.origin.y = -keyboardSize.height / (UIDevice.isSmall && UIDevice.isPortrait ? 2 : 4)
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }

    private func keyBoardHeight(notification: NSNotification) -> CGFloat {
        guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return 0
        }
        return keyboardSize.height
    }
}

// MARK: - UITextViewDelegate

extension PEPAlertWithTextViewViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let alertTextView = textView as? AlertTextView else {
            // TextView is not Alert Text view.
            // Nothing to do.
            return
        }
        alertTextView.beginEditing()

    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let alertTextView = textView as? AlertTextView else {
            // TextView is not Alert Text view.
            // Nothing to do.
            return
        }
        alertTextView.endEditing()
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let alertTextView = textView as? AlertTextView else {
            // TextView is not Alert Text view.
            // Nothing to do.
            return
        }
        alertTextView.didChange()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let inValidCharacterSet = NSCharacterSet.whitespacesAndNewlines
        guard let firstChar = text.unicodeScalars.first else {
            return true
        }

        if textView == emailTextView && firstChar == "\n" {
            textView.resignFirstResponder()
            fingerprintTextView.becomeFirstResponder()
        }
        return !inValidCharacterSet.contains(firstChar)
    }
}

// MARK: - Private

extension PEPAlertWithTextViewViewController {

    @objc private func didPress(sender: UIButton) {
        viewModel.handleButtonEvent(tag: sender.tag)
    }

    private func setUp(title: String?, message: String?) {
        alertMessage.text = message
        alertMessage.font = UIFont.pepFont(style: .footnote, weight: .regular)
        alertTitle.font = UIFont.pepFont(style: .body, weight: .semibold)
        alertTitle.text = title
    }

    private func setUp(alertButton: UIButton, style: PEPAlertViewModel.AlertType) {
        switch style {
        case .pEpSyncWizard:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .body, weight: .semibold)
        case .pEpDefault:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .callout, weight: .semibold)
        }
        if #available(iOS 13.0, *) {
            alertButton.setTitleColor(.label, for: .normal)
        } else {
            alertButton.setTitleColor(.pEpBlack, for: .normal)
        }
    }

    private func setUp(actions: [PEPUIAlertAction]) {
        actions.forEach { action in
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(action.style, for: .normal)
            setUp(alertButton: button, style: viewModel.alertType)
            if #available(iOS 13.0, *) {
                button.backgroundColor = .secondarySystemBackground
            } else {
                button.backgroundColor = .white
            }
            button.tag = viewModel.alertActionsCount
            button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
            viewModel.add(action: action)
            buttonsStackView.addArrangedSubview(button)
        }
    }

    @objc private func dismissKeyboard() {
        fingerprintTextView.resignFirstResponder()
        emailTextView.resignFirstResponder()
        view.endEditing(true)
    }
}

// MARK: - Trait Collection

extension PEPAlertWithTextViewViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                view.layoutIfNeeded()
            }
        }
    }
}
