//
//  LoginViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

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

    }

    @IBAction func cancelButtonTapped(_ sender: Any) {

        let _ =  navigationController?.popViewController(animated: true)

    }


    @IBOutlet weak var cancleButton: UIBarButtonItem!

}
