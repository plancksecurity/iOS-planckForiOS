//
//  UserInfoTableViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

class UserInfoTableViewController: BaseTableViewController, TextfieldResponder, UITextFieldDelegate {
    let comp = "UserInfoTableView"

    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!
    @IBOutlet weak var nameValue: UITextField!

    @IBOutlet weak var emailTitle: UILabel!
    @IBOutlet weak var usernameTitle: UILabel!
    @IBOutlet weak var passwordTitle: UILabel!
    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet weak var cancelBarbutton: UIBarButtonItem!

    var fields = [UITextField]()
    var responder = 0
    var accounts = [Account]()
    
    public var model = AccountUserInput()

    let viewWidthAligner = ViewWidthsAligner()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Account", comment: "Title for manual account setup")
        handleCancelButtonVisibility()
        passwordValue.delegate = self
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [nameValue, emailValue, usernameValue, passwordValue]
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        viewWidthAligner.alignViews([
            emailTitle,
            usernameTitle,
            passwordTitle,
            nameTitle
            ], parentView: view)
    }

    func handleCancelButtonVisibility() {
        accounts = Account.all()
        if accounts.isEmpty {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = Account.all().isEmpty
        updateViewFromInitialModel()
        updateView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(!model.isValidName)
    }

    /**
     Puts the model into the view, in case it was set by the invoking view controller.
     */
    func updateViewFromInitialModel() {
        emailValue.text = model.address
        nameValue.text = model.userName
        passwordValue.text = model.password
    }

    func updateView() {
        navigationItem.rightBarButtonItem?.isEnabled = model.isValidUser
    }

    public func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        
        if model.isValidUser {
            performSegue(withIdentifier: .IMAPSettings , sender: self)
        }
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }

    @IBAction func changeEmail(_ sender: UITextField) {
        model.address = sender.text
        updateView()
    }

    @IBAction func changeUsername(_ sender: UITextField) {
        model.loginName = sender.text
        updateView()
    }

    @IBAction func changePassword(_ sender: UITextField) {
        model.password = sender.text
        updateView()
    }

    @IBAction func changedName(_ sender: UITextField) {
        model.userName = sender.text
        updateView()
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation

extension UserInfoTableViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case IMAPSettings
        case noSegue
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .IMAPSettings:
            if let destination = segue.destination as? IMAPSettingsTableViewController {
                destination.appConfig = appConfig
                destination.model = model
            }
            break
        default:
            break
        }
    }
}
