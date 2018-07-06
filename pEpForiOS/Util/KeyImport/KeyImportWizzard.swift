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
    let account: Account

    //??? We probably needs a KeyImportWizzardDelegate to inform the client (i.e. AutoWizardStepsViewModel)

    init(keyImportService: KeyImportServiceProtocol, account: Account) {
        self.keyImportService = keyImportService
        self.account = account
    }

    var state: WizardState = WizardState.INIT;
    var senderFpr: String = ""
    
    
    func nextState() -> WizardState {
        var nextState: WizardState
        switch state {
        case .INIT:
            nextState = WizardState.BEACON_SENT
            break
        case .BEACON_SENT:
            nextState = WizardState.HANDSHAKE_REQUESTED
            break
        case .BEACON_RECEIVED:
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
        return state;
    }
    
    func finish() {
        state = WizardState.INIT
    }
}

// MARK: - KeyImportServiceDelegate

extension KeyImportWizzard: KeyImportServiceDelegate {
    func newInitKeyImportRequestMessageArrived(message: Message) {
        fatalError("Unimplemented stub")
    }

    func newHandshakeRequestMessageArrived(message: Message) {
        fatalError("Unimplemented stub")
    }

    func receivedPrivateKey(forAccount account: Account) {
        fatalError("Unimplemented stub")
    }

    func errorOccurred(error: Error) {
        fatalError("unimplemented stub")
    }
}
