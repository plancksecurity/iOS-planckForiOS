//
//  LoginViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import UIKit

class LoginViewController: UIViewController {


    var loginViewModel = LoginViewModel()
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var errorMessage: UILabel!


    @IBOutlet weak var manualConfigButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        MessageModelConfig.accountDelegate = self
        // Do any additional setup after loading the view.

    }

    func configureView() {
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.emailAddress.convertToLoginTextField(placeHolder: NSLocalizedString("Email", comment: "Email"))
        self.password.convertToLoginTextField(placeHolder: NSLocalizedString("Password", comment: "password"))
        self.loginButton.convertToLoginButton(placeHolder: NSLocalizedString("Sign In", comment: "Login"))
        self.userName.convertToLoginTextField(placeHolder: NSLocalizedString("Username", comment: "username"))
        self.userName.isHidden = true
        self.manualConfigButton.convertToLoginButton(placeHolder: NSLocalizedString("Manual configuration", comment: "manual"))
        self.manualConfigButton.isHidden = true
        self.errorMessage.convertToLoginErrorLabel(placeHolder: "")
        self.errorMessage.isHidden = true
        self.navigationController?.navigationBar.isHidden = loginViewModel.handleFirstLogin()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: Any) {
        if let email = emailAddress.text, email != "", let pass = password.text, pass != "" {
            loginViewModel.login(account: email, password: pass) { (err) in
                if let error = err {
                    handleLoginError(error: error, autoSegue: true)
                }
            }
        }
    }

    public func handleLoginError(error: NSError, autoSegue: Bool) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                                     comment: "the text in the title for the error message AlerView in account settings"),
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
        }))
        present(alertView, animated: true, completion: nil)

    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }


    @IBOutlet weak var cancleButton: UIBarButtonItem!

}

extension LoginViewController: AccountDelegate {

    public func didVerify(account: Account, error: NSError?) {
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
