//
//  PEPUtils.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PantomimeFramework
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS
import PEPObjCAdapterTypes_iOS

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

//!!!: Clean up! 1) Loads of topics mixed here. 2) Loads of public methods that expose CoreData.

public class PEPUtils {

    ///Delete pEp working data.
    //!!!: MUST go to test utils
    public static func pEpClean() -> Bool {
        PEPSession.cleanup()

        let homeString = PEPObjCAdapter.perUserDirectoryString()
        let homeUrl = URL(fileURLWithPath: homeString, isDirectory: true)

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: homeString) else {
            // Might happen if engine was never used.
            return true
        }

        guard let enumerator = fileManager.enumerator(atPath: homeString) else {
            // Since we already know the directory exists, not getting back
            // an enumerator is an error.
            return false
        }

        var success = true
        for path in enumerator {
            if let pathString = path as? String {
                let fileUrl = URL(fileURLWithPath: pathString, relativeTo: homeUrl)
                do {
                    try fileManager.removeItem(at: fileUrl)
                } catch {
                    success = false
                }
            } else {
                success = false
            }
        }

        return success
    }

    static func pEpRating(cdIdentity: CdIdentity,
                          context: NSManagedObjectContext = Stack.shared.mainContext,
                          completion: @escaping (Rating) -> Void) {
        var pepIdentity: PEPIdentity? = nil
        if context == Stack.shared.mainContext {
            pepIdentity = cdIdentity.pEpIdentity()
        } else {
            context.performAndWait {
                pepIdentity = cdIdentity.pEpIdentity()
            }
        }
        guard let savePepIdentity = pepIdentity else {
            Log.shared.errorAndCrash("No savePepIdentity")
            completion(.undefined)
            return
        }

        PEPSession().rating(for: savePepIdentity, errorCallback: { (error) in
            if error.isPassphraseError {
                Log.shared.info("Passphrase not accepted / known")
            } else {
                Log.shared.error(error: error)
            }
            completion(.undefined)
        }) { (rating) in
            completion(Rating(pEpRating: rating))
        }
    }
}
