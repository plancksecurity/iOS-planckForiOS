//
//  KeyImortWizzard.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel


class KeyImportWizzard {
    enum WizardState {
        case INIT
        case BEACON_SENT
        case BEACON_RECEIVED
        case HANDSHAKE_REQUESTED
        case WAITING_FOR_PRIVATE_KEY
    }
    
    let keyImportService: KeyImportServiceProtocol
    let starter: Bool
    var account: Account?
    weak var delegate: KeyImportWizardDelegate?
    weak var startKeyImportDelegate: StartKeyImportDelegate?

    //??? We probably needs a KeyImportWizzardDelegate to inform the client (i.e. AutoWizardStepsViewModel)

    init(keyImportService: KeyImportServiceProtocol, starter: Bool) {
        self.starter = starter
        self.keyImportService = keyImportService
        self.keyImportService.delegate = self
    }

    var state: WizardState = WizardState.INIT;
    var senderFpr: String = ""
    var userAction: String = NSLocalizedString("Start", comment: "First KeyImport available action")
    var stepDescription: String = ""
    var isWaiting: Bool = false

    func start() {
        resetState()
        next()
    }

    func next()/* -> WizardState*/ {
        var nextState: WizardState
        guard let account = account else {
            Log.shared.errorAndCrash(component: #function, errorString: "Missing account?")
            return
        }

        switch state {
        case .INIT:
            keyImportService.sendInitKeyImportMessage(forAccount: account)
            if starter {
                nextState = WizardState.BEACON_SENT
            }
            else {
                nextState = WizardState.BEACON_RECEIVED
            }
            isWaiting = true


            break
        case .BEACON_SENT,
             .BEACON_RECEIVED:
            nextState = WizardState.HANDSHAKE_REQUESTED
            break
        case .HANDSHAKE_REQUESTED:
            nextState = WizardState.WAITING_FOR_PRIVATE_KEY
            break
        case .WAITING_FOR_PRIVATE_KEY:
            nextState = WizardState.INIT
            break
        }
        state = nextState
        //return state;
    }
    
    func finish() {
        resetState()
        userAction = NSLocalizedString("Start", comment: "First KeyImport available action")
        stepDescription = ""
        isWaiting = false
    }

    func resetState() {
        state = WizardState.INIT;
        senderFpr = ""
    }

}

// MARK: - KeyImportServiceDelegate

extension KeyImportWizzard: KeyImportServiceDelegate {

    /*
     Only called when not starter device*/
    func newInitKeyImportRequestMessageArrived(forAccount account: Account, fpr: String) {
        self.account = account
        startKeyImportDelegate?.startKeyImport(account: account)
    }

    func newHandshakeRequestMessageArrived(forAccount account: Account, fpr: String) {
		next()
        fatalError("Unimplemented stub")
    }

    func receivedPrivateKey(forAccount account: Account) {
        finish()
        fatalError("Unimplemented stub")
    }

    func errorOccurred(error: Error) {
//        delegate?.showError(error: error)
        //TODO: ask user to try later due to an error.
        //SMTP Error && Engine Error
        finish()
        fatalError("unimplemented stub")
    }

}

protocol StartKeyImportDelegate: class {
    func startKeyImport(account: Account);
}

