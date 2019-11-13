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
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    @objc func adjustForKeyboard(notification: NSNotification) {
        scrollViewBottomConstraint.constant = viewNewCenter(notification: notification)
////        if UIScreen.main.traitCollection.verticalSizeClass == .compact {
//            buttonsViewCenterYhRConstraint.constant = viewNewCenter(notification: notification)
////        } else {

//        }
    }
}

// MARK: - Private
extension LoginViewController {


    private func viewNewCenter(notification: NSNotification) -> CGFloat {
        guard notification.name == UIResponder.keyboardWillShowNotification,
            let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                //Keyboard is hidding, move view to original center
                return 0
        }

        return -keyboardValue.cgRectValue.height

//        if UIScreen.main.traitCollection.verticalSizeClass == .compact {
//            return heightCompactViewCenter(keyboardValue: keyboardValue)
//        } else {
//            return heightRegularViewCenter(keyboardValue: keyboardValue)
//        }
    }

//    private func heightCompactViewCenter(keyboardValue: NSValue) -> CGFloat {
//        return 0
//    }
//
//    func heightRegularViewCenter(keyboardValue: NSValue) -> CGFloat {
//        return -keyboardValue.cgRectValue.height / 2
//    }
}

