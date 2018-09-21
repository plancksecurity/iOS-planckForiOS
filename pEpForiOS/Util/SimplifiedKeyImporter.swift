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
        var result = [PEPIdentity]()

        let session = PEPSession()

        if let signingKey = keys.firstObject as? String,
            signingKey == trustedFingerPrint,
            let theAttachments = message.attachments {
            for attachment in theAttachments {
                if attachment.mimeType == MimeTypeUtil.defaultMimeType {
                    if let string = String(data: attachment.data, encoding: .utf8) {
                        do {
                            let identities = try session.importKey(string)
                            for ident in identities {
                                if let fpr = ident.fingerPrint {
                                    do {
                                        try session.setOwnKey(ident, fingerprint: fpr)
                                        result.append(ident)
                                    } catch {
                                        // log, but otherwise ignore
                                        Log.shared.error(
                                            component: #function,
                                            errorString:
                                            "Could not set own key on just imported key data",
                                            error: error)
                                    }
                                } else {
                                    // log, but otherwise ignore
                                    Log.shared.error(
                                        component: #function,
                                        errorString: "No fingerprint for imported identity")
                                }
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

        return result
    }
}
