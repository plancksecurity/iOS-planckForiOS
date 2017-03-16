//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

import MessageModel

fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

open class ModelUserInfoTable {

    open var email: String?

    /**
     The actual name of the user, or nick name.
     */
    open var name: String?

    /**
     An optional name for the servers, if needed.
     */
    open var username: String?
    open var password: String?
    open var serverIMAP: String?
    open var portIMAP: UInt16 = 993
    open var transportIMAP = ConnectionTransport.TLS
    open var serverSMTP: String?
    open var portSMTP: UInt16 = 587
    open var transportSMTP = ConnectionTransport.startTLS

    open var isValidEmail: Bool {
        if let em = email {
            return em.isProbablyValidEmail()
        }
        return false
    }

    open var isValidPassword: Bool {
        if let pass = password {
            return pass.characters.count > 0
        }
        return false
    }

    open var isValidName: Bool {
        return name?.characters.count >= 3
    }

    open var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    open var isValidImap: Bool {
        return false
    }

    open var isValidSmtp: Bool {
        return false
    }
}

open class UserInfoTableView: UITableViewController, TextfieldResponder, UITextFieldDelegate {
    
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
    
    open var model = ModelUserInfoTable()

    let viewWidthAligner = ViewWidthsAligner()

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "NewAccount.title".localized
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

        if appConfig == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }

        navigationItem.hidesBackButton = Account.all().isEmpty
        updateView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        firstResponder(!model.isValidName)
    }

    func updateView() {
        navigationItem.rightBarButtonItem?.isEnabled = model.isValidUser
    }

    /**
     Sometimes you have to put stuff from the view into the model again.
     */
    func updateModel() {}

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

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

extension UserInfoTableView: SegueHandlerType {
    
    public enum SegueIdentifier: String {
        case IMAPSettings
        case noSegue
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .IMAPSettings:
            if let destination = segue.destination as? IMAPSettingsTableView {
                destination.appConfig = appConfig
                destination.model = model
            }
            break
        default:()
        }
    }
}
