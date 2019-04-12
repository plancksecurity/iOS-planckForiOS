//
//  LoginViewController+Keyboard.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 20/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation


extension LoginViewController: UIScrollViewDelegate {

    func configureKeyboardAwareness() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }

    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue else {
                return
        }
        if UIDevice.current.userInterfaceIdiom == .pad && self.traitCollection.verticalSizeClass == .regular {
            var loginButtonUnderSpace = loginButton.frame.maxY
            loginButtonUnderSpace = self.view.frame.height - loginButtonUnderSpace
            
            var contentInset:UIEdgeInsets = contentScrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height - loginButtonUnderSpace
            contentScrollView.contentInset = contentInset
            contentScrollView.scrollIndicatorInsets = contentInset
            
            var biggerLoginButtonFrame = loginButton.frame
            biggerLoginButtonFrame.size = CGSize(width: loginButton.frame.width, height: loginButton.frame.height + 20)
            contentScrollView.scrollRectToVisible(biggerLoginButtonFrame, animated: true)
            contentScrollView.isScrollEnabled = false
            
        }
        else if self.traitCollection.verticalSizeClass == .compact {
            var contentInset:UIEdgeInsets = contentScrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            contentScrollView.contentInset = contentInset
            contentScrollView.scrollIndicatorInsets = contentInset
            self.contentScrollView.delegate = self

            if self.password.isFirstResponder {
                contentScrollView.isScrollEnabled = true
                var textFieldsFrame = self.textFieldsContainerView.frame
                textFieldsFrame.size = CGSize(width: textFieldsContainerView.frame.width, height: textFieldsContainerView.frame.height + 20)
                self.contentScrollView.scrollRectToVisible(textFieldsFrame, animated: false)
            }
            else {
                self.contentScrollView.scrollRectToVisible(self.loginButton.frame, animated: false)
            }
            
        }
        else {
            var contentInset:UIEdgeInsets = contentScrollView.contentInset
            contentInset.bottom = keyboardFrame.size.height
            contentScrollView.contentInset = contentInset
            contentScrollView.scrollIndicatorInsets = contentInset
            self.contentScrollView.delegate = self
            self.contentScrollView.scrollRectToVisible(self.loginButton.frame, animated: false)
        }
    }

    @objc func keyboardWillHide(notification:NSNotification){

        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.contentScrollView.contentInset = contentInset
        contentScrollView.isScrollEnabled = true
        self.contentScrollView.delegate = nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentScrollView.isScrollEnabled = false
    }

}
