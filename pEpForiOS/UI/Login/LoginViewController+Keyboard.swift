//
//  LoginViewController+Keyboard.swift
//  pEp
//
//  Created by Alejandro Gelos on 3/10/2019.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

extension LoginViewController {

    func configureKeyboardAwareness() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateScrollViewToHideyboard),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateScrollViewToShowKeyboard),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    @objc func updateScrollViewToHideyboard(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.contentInset.top = 0
        adjustScrollViewHeight(notification: notification)
    }

    @objc func updateScrollViewToShowKeyboard(notification: NSNotification) {
        adjustScrollViewHeight(notification: notification)

        if let textField = firstResponderTextField() {
            let scrollViewHeight = scrollView.frame.maxY
                + abs(scrollViewBottomConstraint.constant)
                - keyBoardHeight(notification: notification)
            scrollAndMakeVisible(textField, scrollViewHeight: scrollViewHeight)
        }
    }

    private func adjustScrollViewHeight(notification: NSNotification) {
        scrollViewBottomConstraint.constant = -keyBoardHeight(notification: notification)

        guard let animationDuration = keyBoardAnimationDuration(notification: notification) else {
            return
        }
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
        })
    }

    private func firstResponderTextField() -> UITextField? {
        if emailAddress.isFirstResponder {
            return emailAddress
        }
        if password.isFirstResponder {
            return password
        }
        if user.isFirstResponder {
            return user
        }
        return nil
    }
}

// MARK: - Private

extension LoginViewController {

    private func keyBoardHeight(notification: NSNotification) -> CGFloat {
        guard notification.name == UIResponder.keyboardWillShowNotification,
            let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                //Keyboard is hidding, move view to original center
                return 0
        }

        return keyboardValue.cgRectValue.height
    }

    private func keyBoardAnimationDuration(notification: NSNotification) -> Double? {
        guard let duration =
            notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return nil
        }
        return duration
    }
}
