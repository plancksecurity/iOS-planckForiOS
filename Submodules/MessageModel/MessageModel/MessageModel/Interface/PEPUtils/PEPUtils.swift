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
import PEPObjCAdapterFramework

//!!!: Clean up! 1) Loads of topics mixed here. 2) Loads of public methods that expose CoreData.

public class PEPUtils {

    /// Content type for MIME multipart/alternative.
    public static let kMimeTypeMultipartAlternative = "multipart/alternative"

    ///Delete pEp working data.
    //!!!: MUST go to test utils
    public static func pEpClean() -> Bool {
        PEPSession.cleanup()

        let homeString = PEPObjCAdapter.perUserDirectoryString()
        let homeUrl = URL(fileURLWithPath: homeString, isDirectory: true)

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: homeString) {
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
                Log.shared.error("%@", "\(error)")
            } else {
                Log.shared.errorAndCrash("%@", error.localizedDescription)
            }
            completion(.undefined)
        }) { (rating) in
            completion(Rating(pEpRating: rating))
        }
    }
}
