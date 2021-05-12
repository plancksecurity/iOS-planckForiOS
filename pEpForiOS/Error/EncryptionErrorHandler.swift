//
//  EncryptionErrorHandler.swift
//  pEp
//
//  Created by Andreas Buff on 07.05.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import MessageModel

class EncryptionErrorHandler {

}

// MARK: - EncryptionErrorDelegate

extension EncryptionErrorHandler: EncryptionErrorDelegate {
    func handleCouldNotEncrypt(completion: @escaping (Bool) -> ()) {
        DispatchQueue.main.async {
            let title = NSLocalizedString("Could Not Encrypt",
                                          comment: "Alert title: In case we could not encrypt a messge that was previously shown as yellow or green.")
            let message = NSLocalizedString("An error occured while encrypting your message. Do you want to send the message unencrypted?",
                                            comment: "Alert message: In case we could not encrypt a messge that was previously shown as yellow or green.")
            let cancelButtonTitle = NSLocalizedString("No",
                                                      comment: "Cancel button title: In case we could not encrypt a messge that was previously shown as yellow or green, send message unencrypted?")
            let positiveButtonTitle = NSLocalizedString("Yes",
                                                        comment: "Positive button title: In case we could not encrypt a messge that was previously shown as yellow or green, send message unencrypted?")
            UIUtils.showTwoButtonAlert(withTitle: title,
                                       message: message,
                                       cancelButtonText: cancelButtonTitle,
                                       positiveButtonText: positiveButtonTitle,
                                       cancelButtonAction: {
                                        completion(SendUnencrypted(false))
                                       },
                                       positiveButtonAction: {
                                        completion(SendUnencrypted(true))
                                       }, style: .warn)
        }
    }
}
