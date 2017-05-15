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

    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        // Do any additional setup after loading the view.

    }

    func configureView() {
        self.view.applyGradient(colours: [UIColor.pEpGreen, UIColor.pEpDarkGreen])
        self.emailAddress.convertToLoginTextField(placeHolder: NSLocalizedString("Email", comment: "Email"))
        self.password.convertToLoginTextField(placeHolder: NSLocalizedString("Password", comment: "password"))
        self.loginButton.convertToLoginButton(placeHolder: NSLocalizedString("Sign In", comment: "Login"))

        self.navigationController?.navigationBar.isHidden = loginViewModel.handleFirstLogin()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: Any) {
        if let email = emailAddress.text, let pass = password.text {
            loginViewModel.login(account: email, password: pass) { (res, acc) in
                switch res.satus {
                case .ERROR:
                    //jump to auto config
                    break
                case .FAILED:
                    //don't know
                    break
                case .OK:
                    MessageModelConfig.accountDelegate = self
                    break
                }
            }
        }
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }


    @IBOutlet weak var cancleButton: UIBarButtonItem!

    func showErrorMessage (_ message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                                     comment: "the text in the title for the error message AlerView in account settings"),
            message:message, preferredStyle: .alert)
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
            style: .default, handler: nil))
        present(alertView, animated: true, completion: nil)
    }

}

extension LoginViewController: AccountDelegate {

    public func didVerify(account: Account, error: NSError?) {
        GCD.onMain() {
            //self.status.activityIndicatorViewEnable = false
            //self.updateView()

            if let err = error {
                self.showErrorMessage(err.localizedDescription)
            } else {
                // unwind back to INBOX on success
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

}
