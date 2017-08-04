//
//  UserInfoTableViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

import MessageModel

open class UserInfoTableViewController: UITableViewController, TextfieldResponder, UITextFieldDelegate {
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

    var appConfig: AppConfig?
    var fields = [UITextField]()
    var responder = 0
    var accounts = [Account]()
    
    open var model = AccountUserInput()

    let viewWidthAligner = ViewWidthsAligner()

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Account Configuration", comment: "Title for manual account setup")
        handleCancelButtonVisibility()
        passwordValue.delegate = self
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [nameValue, emailValue, usernameValue, passwordValue]
    }

    open override func viewDidLayoutSubviews() {
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

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = Account.all().isEmpty
        updateViewFromInitialModel()
        updateView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(!model.isValidName)
    }

    /**
     Puts the model into the view, in case it was set by the invoking view controller.
     */
    func updateViewFromInitialModel() {
        emailValue.text = model.email
        nameValue.text = model.name
        passwordValue.text = model.password
    }

    func updateView() {
        navigationItem.rightBarButtonItem?.isEnabled = model.isValidUser
    }

    //BUFF: delete or implement if required
//    /**
//     Sometimes you have to put stuff from the view into the model again.
//     */
//    func updateModel() {}

    open func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
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
        model.email = sender.text
        updateView()
    }

    @IBAction func changeUsername(_ sender: UITextField) {
        model.username = sender.text
        updateView()
    }

    @IBAction func changePassword(_ sender: UITextField) {
        model.password = sender.text
        updateView()
    }

    @IBAction func changedName(_ sender: UITextField) {
        model.name = sender.text
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
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
