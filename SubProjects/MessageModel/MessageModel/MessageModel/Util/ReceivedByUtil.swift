//
//  ReceivedByUtil.swift
//  MessageModel
//
//  Created by Andreas Buff on 30.06.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import PantomimeFramework
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// Use to figure out the best possible `receivedby`value.
struct ReceivedByUtil {

    /// Computes the best receivedBy possible from the data given in `pantomimeMessage`, finds or
    /// creats an CdIdentity and sets it to `cdMessage.receivedBy`.
    /// - See spec in IOS-2811.
    /// - Parameters:
    ///   - pantomimeMessage:   message holding all headers which are taken to decide for the best
    ///                         possible `receivedby` email address
    ///   - cdMessage: message to set `receivedBy on`
    static func setReceivedBy(fromDataOf pantomimeMessage: CWIMAPMessage,
                                      to cdMessage: CdMessage,
                                      context: NSManagedObjectContext) {
        guard cdMessage.receivedBy == nil else {
            Log.shared.info("cdMessage.receivedBy has already been set. Deny to reset.")
            return
        }
        let headersDict = pantomimeMessage.allHeaders()
        var xOriginalToIdentity: CdIdentity? = nil
        var deliveredToIdentity: CdIdentity? = nil
        var receivedIdentity: CdIdentity? = nil
        for key in headersDict.keys {
            guard let keyString = key as? String else {
                Log.shared.errorAndCrash("Issue casting")
                continue
            }
            if keyString == "X-Original-To" {
                guard let value = headersDict[key] else {
                    Log.shared.errorAndCrash("key without value?")
                    continue
                }
                guard let email = try? validatedEmailString(from: value) else {
                    Log.shared.warn("Somthing is unexpected with value")
                    continue
                }
                xOriginalToIdentity = CdIdentity.updateOrCreate(withAddress: email,
                                                                context: context)
            } else if keyString == "Delivered-To" {
                guard let value = headersDict[key] else {
                    Log.shared.errorAndCrash("key without value?")
                    continue
                }
                guard let email = try? validatedEmailString(from: value) else {
                    Log.shared.warn("Somthing is unexpected with value")
                    continue
                }
                deliveredToIdentity = CdIdentity.updateOrCreate(withAddress: email,
                                                                context: context)
            } else if keyString == "Received" {
                guard let value = headersDict[key] as? String else {
                    Log.shared.errorAndCrash("key without value?")
                    continue
                }
                /*
                 Example:
                 (lldb) po value
                 by peptest.ch (Postfix, from userid 10000)    id 2733A101079; Thu, 24 Jun 2021 11:29:37 +0200 (CEST) from pretty.Easy.privacy (109-226-168-249.cable.swschwedt.net [109.226.168.249])    (using TLSv1.2 with cipher ECDHE-RSA-AES128-GCM-SHA256 (128/128 bits))    (No client certificate requested)    by peptest.ch (Postfix) with ESMTPSA id 8938C101079    for <iostest005@peptest.ch>; Thu, 24 Jun 2021 11:29:36 +0200 (CEST)
                 */
                let devidedByFor = value.components(separatedBy: " for <")
                if devidedByFor.count > 1 {
                    let postFor = devidedByFor[1]
                    // iostest005@peptest.ch>; Thu, 24 Jun 2021 11:29:36 ...
                    let devidedByClosingBracket = postFor.components(separatedBy: ">")
                    if devidedByClosingBracket.count > 0 {
                        let email = devidedByClosingBracket[0]
                        guard email.isProbablyValidEmail() else {
                            Log.shared.errorAndCrash("Error parsing")
                            continue
                        }
                        if receivedIdentity == nil {
                            // We must take the first "Received:" into account only
                            receivedIdentity = CdIdentity.updateOrCreate(withAddress: email,
                                                                         context: context)
                            // we break here (and only here) because we found our prefered option (first "Received:")
                            break
                        }
                    }
                }
            }
        }
        cdMessage.receivedBy = receivedIdentity ?? xOriginalToIdentity ?? deliveredToIdentity

        if cdMessage.receivedBy == nil {
            Log.shared.warn("Fallback used: Uses account's Identity as receivedBy. The specified algorythm did not give any result.")
            cdMessage.receivedBy = cdMessage.parent?.account?.identity
        }
        // Sanity check
        guard cdMessage.receivedBy != nil else {
            Log.shared.errorAndCrash("Nothing found for receivedBy. Not even the fallback!")
            return
        }
    }

    static private func validatedEmailString(from cwHeadersValue: Any) throws -> String {
        guard let email = cwHeadersValue as? String else {
            Log.shared.warn("Is not the expected type")
            throw "Is not the expected type"
        }
        guard email.isProbablyValidEmail() else {
            Log.shared.warn("Seems not to be a valid mail address: %@", email)
            throw "Seems not to be a valid mail address: \(email)"
        }
        return email
    }
}
