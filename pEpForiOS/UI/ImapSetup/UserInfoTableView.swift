//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

public struct ModelUserInfoTable {

    public var emailTextExist: Bool = false
    public var passwordTextExist: Bool = false

    public var email: String?
    public var username: String?
    public var password: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16?
    public var transportIMAP: ConnectionTransport?
    public var serverSMTP: String?
    public var portSMTP: UInt16?
    public var transportSMTP: ConnectionTransport?

    public var isValidEmail: Bool {
        return email != nil && email!.isProboblyValidEmail()
    }

    public var isValidPassword: Bool {
        return password != nil && password!.characters.count > 0
    }

    public var isValiUser: Bool {
        return isValidEmail && isValidPassword
    }
}

public class UserInfoTableView: UITableViewController, DataEnteredDelegate {

    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!


    var appConfig: AppConfig?

    public var model: ModelUserInfoTable?

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem!.enabled = false
        model = ModelUserInfoTable()
        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }
        emailValue.becomeFirstResponder()
    }


    func updateView() {
        self.navigationItem.rightBarButtonItem!.enabled = model!.isValiUser
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IMAPSettings" {
             let destination = segue.destinationViewController as! IMAPSettingsTableView
                destination.delegate = self
                destination.appConfig = appConfig
                destination.model = self.model
        }
    }

    @IBAction func introduceEmail(sender: UITextField) {
        model!.emailTextExist = emailValue.text != ""
        model!.email = emailValue.text!
        updateView()
    }

    @IBAction func introducedUsername(sender: UITextField) {
        if (usernameValue.text != nil) {
            model!.username = usernameValue.text!
        }
        else {
            model!.username = emailValue.text!
        }
    }

    @IBAction func introducedPassword(sender: UITextField) {
        model!.passwordTextExist = passwordValue.text != ""
        model!.password = passwordValue.text!
        updateView()
    }

    // protocols delegate
    func saveServerInformation(server: String?) {
        self.model!.serverIMAP = server
    }

    func savePortInformation(port: UInt16?) {
          self.model!.portIMAP = port
    }

    func saveServerTransport(transport: ConnectionTransport?) {
        self.model!.transportIMAP = transport
    }

    func saveServerInformationSMTP(server: String?) {
        self.model!.serverSMTP = server
    }

    func savePortInformationSMTP(port: UInt16?) {
        self.model!.portSMTP = port
    }

    func saveServerTransportSMTP (transport: ConnectionTransport?) {
        self.model!.transportSMTP = transport
    }


}