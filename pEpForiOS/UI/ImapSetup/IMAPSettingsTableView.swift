//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit


protocol DataEnteredDelegate: class {
    func saveServerInformation(server:String?)
    func savePortInformation(port: UInt16?)
    func saveServerTransport(transport: ConnectionTransport?)
    func saveServerInformationSMTP(server:String?)
    func savePortInformationSMTP(port: UInt16?)
    func saveServerTransportSMTP(transport: ConnectionTransport?)
}

class IMAPSettingsTableView: UITableViewController, SecondDataEnteredDelegate  {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    weak var delegate: DataEnteredDelegate? = nil

    var appConfig: AppConfig?
    var model: ModelUserInfoTable?

    override func viewDidLoad() {
        super.viewDidLoad()
        serverValue.becomeFirstResponder()
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model!.serverIMAP
        if (model!.portIMAP != nil) {
            portValue.text = String(model!.portIMAP!)
        }
        if let transport = model!.transportIMAP{
            switch transport {
            case .StartTLS:
                self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
            case .Plain:
                self.transportSecurity.setTitle("Plain >", forState: .Normal)
            default:
                self.transportSecurity.setTitle("TLS >", forState: .Normal)
            }
        } else {
            self.transportSecurity.setTitle("Plain >", forState: .Normal)
        }
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(title: "Security protocol", message: "Choose a Security protocol for your accont", preferredStyle: .ActionSheet)

        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(CancelAction)

        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in
            self.model!.transportIMAP = ConnectionTransport.StartTLS
            self.delegate?.saveServerTransport(ConnectionTransport.StartTLS)
            self.updateView()
        }
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in
            self.model!.transportIMAP = ConnectionTransport.TLS
            self.delegate?.saveServerTransport(ConnectionTransport.TLS)
            self.updateView()
        }
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "Plain", style: .Default) { (action) in
            self.model!.transportIMAP = ConnectionTransport.Plain
            self.delegate?.saveServerTransport(ConnectionTransport.Plain)
            self.updateView()
        }
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
    }

    @IBAction func editedPort(sender: UITextField) {
        model!.portIMAP = UInt16(portValue.text!)
        delegate?.savePortInformation(UInt16(portValue.text!))
    }

    @IBAction func editedServer(sender: UITextField) {
        model!.serverIMAP = serverValue.text!
        delegate?.saveServerInformation(serverValue.text!)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                destination.delegate = self
                destination.appConfig = self.appConfig
                destination.model = self.model
            }
        }
    }

    //protocols delegate methods
    func saveServerInformationSMTP(server:String?) {
        model!.serverSMTP = server
        delegate?.saveServerInformationSMTP(server)
    }

    func savePortInformationSMTP(port: UInt16?) {
        model!.portSMTP = port
        delegate?.savePortInformationSMTP(port)
    }

    func savePortTransportSMTP(transport: ConnectionTransport?) {
        model!.transportSMTP = transport
        delegate?.saveServerTransportSMTP(transport)
    }
}
