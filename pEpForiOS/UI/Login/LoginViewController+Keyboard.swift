//
//  LoginViewController+Keyboard.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 20/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


extension LoginViewController {

    func configureKeyboardAwareness() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShow(notification:NSNotification){

        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue else {
            return
        }

        if UIDevice.current.userInterfaceIdiom == .pad && self.traitCollection.horizontalSizeClass == .regular {
            var loginButtonUnderSpace = loginButton.frame.maxY
            loginButtonUnderSpace = self.view.frame.height - loginButtonUnderSpace
            
            var contentInset:UIEdgeInsets = contentScrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height - loginButtonUnderSpace
            contentScrollView.contentInset = contentInset
            contentScrollView.scrollIndicatorInsets = contentInset
            
            var biggerLoginButtonFrame = loginButton.frame
            biggerLoginButtonFrame.size = CGSize(width: loginButton.frame.width, height: loginButton.frame.height + 20)
            contentScrollView.scrollRectToVisible(biggerLoginButtonFrame, animated: true)
        }
        else {
            var contentInset:UIEdgeInsets = contentScrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            contentScrollView.contentInset = contentInset
            contentScrollView.scrollIndicatorInsets = contentInset
            contentScrollView.scrollRectToVisible(loginButton.frame, animated: true)

        }
    }

    @objc func keyboardWillHide(notification:NSNotification){

        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.contentScrollView.contentInset = contentInset
    }

}
