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

class IMAPSettingsTableView: UITableViewController, TextfieldResponder, UITextFieldDelegate {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!
    @IBOutlet weak var transportSecurity: UIButton!

    let viewWidthAligner = ViewWidthsAligner()

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!
    var fields = [UITextField]()
    var responder = 0
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ImapSettings.title".localized
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
        
       firstResponder(model.serverIMAP == nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model.serverIMAP
        portValue.text = String(model.portIMAP)
        transportSecurity.setTitle(model.transportIMAP.localizedString(), for: UIControlState())
    }

    @IBAction func alertWithSecurityValues(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = sender

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
    
    open func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

// MARK: - Navigation

extension IMAPSettingsTableView: SegueHandlerType {
    
    public enum SegueIdentifier: String {
        case SMTPSettings
        case noSegue
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .SMTPSettings:
            let destination = segue.destination as! SMTPSettingsTableView
            destination.appConfig = self.appConfig
            destination.model = self.model
            break
        default:()
        }
        
    }
    
}
