//
//  KeyImortWizzard.swift
//  pEp
//
//  Created by Andreas Buff on 28.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

class KeyImortWizzard {
     let keyImportService: KeyImportServiceProtocol
    //??? We probably needs a KeyImportWizzardDelegate to inform the client (i.e. AutoWizardStepsViewModel)

    init(keyImportService: KeyImportServiceProtocol) {
        self.keyImportService = keyImportService
    }
}

// MARK: - KeyImportServiceDelegate

extension KeyImortWizzard: KeyImportServiceDelegate {
    func newKeyImportMessageArrived(message: Message) {
        fatalError("Unimplemented stub")
    }

    func receivedPrivateKey(forAccount account: Account) {
        fatalError("Unimplemented stub")
    }
}
