//
//  ViewController.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

public class ModelUserInfoTable {

    public var email: String?
    public var username: String?
    public var password: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.StartTLS

    public var isValidEmail: Bool {
        return email != nil && email!.isProbablyValidEmail()
    }

    public var isValidPassword: Bool {
        return password != nil && password!.characters.count > 0
    }

    public var isValidUser: Bool {
        return isValidEmail && isValidPassword
    }

    public var isValidImap: Bool {
        return false
    }

    public var isValidSmtp: Bool {
        return false
    }
}

public class UserInfoTableView: UITableViewController {

    @IBOutlet weak var emailValue: UITextField!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var passwordValue: UITextField!

    var appConfig: AppConfig?

    public var model = ModelUserInfoTable()

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if appConfig == nil {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appConfig = appDelegate.appConfig
            }
        }

        if model.email == nil {
            emailValue.becomeFirstResponder()
        }

        updateView()
    }

    func updateView() {
        self.navigationItem.rightBarButtonItem?.enabled = model.isValidUser
        // TODO: update the complete view (email etc.)
    }

    /**
     Sometimes you have to put stuff from the view into the model again.
     */
    func updateModel() {}

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IMAPSettings" {
             let destination = segue.destinationViewController as! IMAPSettingsTableView
                destination.appConfig = appConfig
                destination.model = model
        }
    }

    @IBAction func changeEmail(sender: UITextField) {
        model.email = sender.text
        updateView()
    }

    @IBAction func changeUsername(sender: UITextField) {
        model.username = sender.text
        updateView()
    }

    @IBAction func changePassword(sender: UITextField) {
        model.password = sender.text
        updateView()
    }

    /*
    // protocols delegate
    func saveServerInformation(server: String?) {
        self.model.serverIMAP = server
    }

    func savePortInformation(port: UInt16?) {
          self.model.portIMAP = port
    }

    func saveServerTransport(transport: ConnectionTransport?) {
        self.model.transportIMAP = transport
    }

    func saveServerInformationSMTP(server: String?) {
        self.model.serverSMTP = server
    }

    func savePortInformationSMTP(port: UInt16?) {
        self.model.portSMTP = port
    }

    func saveServerTransportSMTP (transport: ConnectionTransport?) {
        self.model.transportSMTP = transport
    }
 */
}