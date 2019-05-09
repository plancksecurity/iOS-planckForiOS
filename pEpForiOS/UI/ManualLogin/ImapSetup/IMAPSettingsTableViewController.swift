//
//  IMAPSettingsTableViewController.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import PantomimeFramework
import MessageModel

extension UIAlertController {
    func setupActionFromConnectionTransport(_ transport: ConnectionTransport,
                                            block: @escaping (ConnectionTransport) -> ()) {
        let action = UIAlertAction(title: transport.localizedString(), style: .default,
                                   handler: { action in
            block(transport)
        })
        addAction(action)
    }
}

class IMAPSettingsTableViewController: BaseTableViewController, TextfieldResponder, UITextFieldDelegate {
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var serverTitle: UILabel!
    @IBOutlet weak var portTitle: UILabel!
    @IBOutlet weak var transportSecurity: UIButton!

    let viewWidthAligner = ViewWidthsAligner()

    var model: VerifiableAccountProtocol?
    var fields = [UITextField]()
    var responder = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("IMAP", comment: "Manual account setup")
        UIHelper.variableCellHeightsTableView(tableView)
        fields = [serverValue, portValue]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        viewWidthAligner.alignViews([
            serverTitle,
            portTitle
            ], parentView: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder(model?.serverIMAP == nil)
    }

    private func updateView() {
        serverValue.text = model?.serverIMAP
        if let thePort = model?.portIMAP {
            portValue.text = String(thePort)
        }
        transportSecurity.setTitle(model?.transportIMAP.localizedString(), for: UIControl.State())
    }

    @IBAction func alertWithSecurityValues(_ sender: UIButton) {
        let alertController = UIAlertController.pEpAlertController(
            title: NSLocalizedString("Transport protocol",
                                     comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                                       comment: "UI alert message for transport protocol"),
            preferredStyle: .actionSheet)
        let block: (ConnectionTransport) -> () = { transport in
            self.model?.transportIMAP = transport
            self.updateView()
        }

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender
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
                model?.portIMAP = port
            }
        }
    }

    @IBAction func changeServer(_ sender: UITextField) {
        model?.serverIMAP = serverValue.text
    }

    public func textFieldShouldReturn(_ textfield: UITextField) -> Bool {
        nextResponder(textfield)
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        changedResponder(textField)
    }
}

// MARK: - Navigation

extension IMAPSettingsTableViewController: SegueHandlerType {

    public enum SegueIdentifier: String {
        case SMTPSettings
        case noSegue
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .SMTPSettings:
            if let destination = segue.destination as? SMTPSettingsTableViewController {
                destination.appConfig = appConfig
                destination.model = model
            } else {
                Log.shared.errorAndCrash(
                    "Seque is .SMTPSettings, but controller is not a SMTPSettingsTableViewController")
            }
            break
        default:()
        }
    }
}
