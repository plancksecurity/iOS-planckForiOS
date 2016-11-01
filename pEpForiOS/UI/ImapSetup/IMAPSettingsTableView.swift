//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIAlertController {
    func setupActionFromConnectionTransport(_ transport: ConnectionTransport, block: @escaping (ConnectionTransport) -> ()) {
        let action = UIAlertAction(title: transport.localizedString(), style: .default, handler: { action in
            block(transport)
        })
        addAction(action)
    }
}

class IMAPSettingsTableView: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!
    @IBOutlet weak var transportSecurity: UIButton!

    let viewWidthAligner = ViewWidthsAligner()

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!
    var fields = [UITextField]()
    var index = 0
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [serverValue, portValue]
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewWidthAligner.alignViews([
            serverTitle,
            portTitle
        ], parentView: view)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fields[index].resignFirstResponder()
        if model.serverIMAP == nil {
            serverValue.becomeFirstResponder()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model.serverIMAP
        portValue.text = String(model.portIMAP)
        transportSecurity.setTitle(model.transportIMAP.localizedString(), for: UIControlState())
    }

    @IBAction func alertWithSecurityValues(_ sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)

        let block: (ConnectionTransport) -> () = { transport in
            self.model.transportIMAP = transport
            self.updateView()
        }

        alertController.setupActionFromConnectionTransport(.plain, block: block)
        alertController.setupActionFromConnectionTransport(.TLS, block: block)
        alertController.setupActionFromConnectionTransport(.startTLS, block: block)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
            style: .cancel) { (action) in}
        alertController.addAction(cancelAction)
        present(alertController, animated: true) {}
    }

    @IBAction func changePort(_ sender: UITextField) {
        if let text = portValue.text {
            if let port = UInt16(text) {
                model.portIMAP = port
            }
        }
    }

    @IBAction func changeServer(_ sender: UITextField) {
        model.serverIMAP = serverValue.text!
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SMTPSettings" {
            if let destination = segue.destination as? SMTPSettingsTableView {
                destination.appConfig = self.appConfig
                destination.model = self.model
            }
        }
    }
    
    open func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        textfield.resignFirstResponder()
        
        index += 1
        if index < fields.count && textfield == fields[index - 1] {
            textfield.resignFirstResponder()
            fields[index].becomeFirstResponder()
        } else {
            index = 0
            fields[index].becomeFirstResponder()
        }
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        for (i, field) in fields.enumerated() {
            if field == textField {
                index = i
            }
        }
    }
}
