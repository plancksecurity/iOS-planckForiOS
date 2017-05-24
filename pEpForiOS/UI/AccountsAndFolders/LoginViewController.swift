//
//  LoginViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {


    var loginViewModel = LoginViewModel()
    var extendedLogin = false
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var manualConfigButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!

    var activeField: UITextField?


    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        MessageModelConfig.accountDelegate = self
    }

    func configureView() {
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.emailAddress.delegate = self
        self.password.delegate = self
        self.userName.delegate = self
        self.emailAddress.convertToLoginTextField(placeHolder: NSLocalizedString("Email", comment: "Email"))
        self.password.convertToLoginTextField(placeHolder: NSLocalizedString("Password", comment: "password"))
        self.loginButton.convertToLoginButton(placeHolder: NSLocalizedString("Sign In", comment: "Login"))
        self.userName.convertToLoginTextField(placeHolder: NSLocalizedString("Username", comment: "username"))
        self.userName.isHidden = true
        self.manualConfigButton.convertToLoginButton(placeHolder: NSLocalizedString(
            "Manual configuration", comment: "manual"))
        self.manualConfigButton.isHidden = true
        self.errorMessage.convertToLoginErrorLabel(placeHolder: "")
        self.errorMessage.isHidden = true
        self.navigationController?.navigationBar.isHidden = !loginViewModel.isThereAnAccount()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func login(_ sender: Any) {
        if let email = emailAddress.text, email != "", let pass = password.text, pass != "" {
            if extendedLogin {
                if let username = userName.text, username != "" {
                    loginViewModel.login(account: email, password: pass, username: username) { (err) in
                        if let error = err {
                            handleLoginError(error: error, autoSegue: true)
                        }
                    }
                } else {
                    noAllDataFilled()
                }
            } else {
                loginViewModel.login(account: email, password: pass) { (err) in
                    if let error = err {
                        handleLoginError(error: error, autoSegue: true)
                    }
                }
            }
        } else {
            noAllDataFilled()
        }
    }

    public func handleLoginError(error: Error, autoSegue: Bool) {
        let alertView = UIAlertController(
            title: NSLocalizedString(
                "Error",comment: "the text in the title for the error message AlerView in account settings"),
            message:error.localizedDescription, preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "View log",
                comment: "Button for viewing the log on error"),
            style: .default, handler: { action in
                //self.viewLog()
        }))
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString(
                "Ok",
                comment: "confirmation button text for error message AlertView in account settings"),
            style: .default, handler: {action in
                if autoSegue {
                    
                }
                self.userName.isHidden = false
                self.manualConfigButton.isHidden = false
                self.errorMessage.isHidden = false
                self.errorMessage.text = error.localizedDescription
                self.extendedLogin = true
        }))
        present(alertView, animated: true, completion: nil)

    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    


    @IBOutlet weak var cancleButton: UIBarButtonItem!

}

extension LoginViewController: AccountDelegate {

    public func didVerify(account: Account, error: Error?) {
        GCD.onMain() {
            if let err = error {
                self.handleLoginError(error: err, autoSegue: false)
            } else {
                // unwind back to INBOX on success
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

}

extension LoginViewController {

    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)

        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets

        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.activeField {
            if (!aRect.contains(activeField.frame.origin)){
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }

    func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.isScrollEnabled = false
    }

    func textFieldDidBeginEditing(_ textField: UITextField){
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }
    

}
