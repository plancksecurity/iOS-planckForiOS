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

    @IBOutlet private weak var alertTitle: UILabel!
    @IBOutlet private weak var alertMessage: UILabel!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private(set) weak var textView: AlertTextView!
    private var viewModel: PEPAlertViewModelProtocol
    private var titleString: String?
    private var message: String?
    private var action = [PEPUIAlertAction]()
    private static let storyboardId = "PEPAlertWithTextViewViewController"

    public final var placeholderText: String?

    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        setUp(title: titleString, message: message)
        setUp(actions: action)
        textView.placeholderText = placeholderText ?? ""
        textView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
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
    }

    private func setUp(actions: [PEPUIAlertAction]) {
        actions.forEach { action in
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(action.style, for: .normal)
            setUp(alertButton: button, style: viewModel.alertType)
            button.backgroundColor = .white
            button.tag = viewModel.alertActionsCount
            button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
            viewModel.add(action: action)
            buttonsStackView.addArrangedSubview(button)
        }
    }

    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
        view.endEditing(true)
    }
}
