//
//  SimplifiedKeyImporter.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SimplifiedKeyImporter {
    let trustedFingerPrint: String

    init(trustedFingerPrint: String) {
        self.trustedFingerPrint = trustedFingerPrint
    }

    public func process(message: PEPMessage, keys: NSArray) -> [PEPIdentity] {
        guard let (theOwnIdentity, theFingerprint) = parseOwnIdentityFromTextBody(
            message: message) else {
                return []
        }

        let session = PEPSession()

        if let signingKey = keys.firstObject as? String,
            signingKey == trustedFingerPrint,
            let theAttachments = message.attachments {
            for attachment in theAttachments {
                if attachment.mimeType == MimeTypeUtil.defaultMimeType {
                    if let string = String(data: attachment.data, encoding: .utf8) {
                        do {
                            // netpgp doesn't give us a list of imported keys, so ignore (mostly)
                            let _ = try session.importKey(string)

                            do {
                                try session.setOwnKey(theOwnIdentity, fingerprint: theFingerprint)
                                return [theOwnIdentity]
                            } catch {
                                // log, but otherwise ignore
                                Log.shared.error(
                                    component: #function,
                                    errorString:
                                    "Could not set own key on just imported key data",
                                    error: error)
                            }
                        } catch {
                            // log, but otherwise ignore
                            Log.shared.error(component: #function,
                                             errorString: "Could not import key data",
                                             error: error)
                        }
                    }
                }
            }
        }

        return []
    }

    /**
     Tries to parse a pEp own identity from the first 2 lines of the body text.
     The fingerprint is returned separately, because in the identity it's optional.
     */
    private func parseOwnIdentityFromTextBody(message: PEPMessage) -> (PEPIdentity, String)? {
        let newlines = ["\r\n", "\n"]

        for separator in newlines {
            if let (theEmail, theFingerprint) = emailAndFingerprintFromTextBody(
                message: message,
                separator: separator) {
                let theUserId = PEP_OWN_USERID

                let theIdent = PEPIdentity(
                    address: theEmail, userID: theUserId, userName: theUserId, isOwn: true)
                theIdent.fingerPrint = theFingerprint

                return (theIdent, theFingerprint)
            }
        }

        return nil
    }

    private func emailAndFingerprintFromTextBody(message: PEPMessage,
                                                 separator: String) -> (String, String)? {
        guard let theText = message.longMessage else {
            return nil
        }

        let theLines = theText.components(separatedBy: separator)
        guard theLines.count >= 2 else {
            return nil
        }

        let theEmail = theLines[0]

        guard theEmail.isProbablyValidEmail() else {
            return nil
        }

        let theFingerprint = String(theLines[1])

        if theFingerprint.count == 40 {
            return (theEmail, theFingerprint)
        } else {
            return nil
        }
    }
}
