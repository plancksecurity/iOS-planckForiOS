//
//  RatingReEvaluator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import PEPObjCAdapterFramework
import pEpIOSToolbox

protocol RatingReEvaluatorProtocol {
    /// Reevaluates the pEp rating of the given message and saves it.
    /// - Parameters:
    ///   - message: message to re-evaluate rating for. Must be save to use on `Session.main`.
    ///   - completion: called when done reevaluating. I quaranteed to be called on the main queue.
    static func reevaluate(message: Message, completion:  @escaping ()->Void)
}

public class RatingReEvaluator {

    // Is currently pure static
    private init() {}
}

extension RatingReEvaluator: RatingReEvaluatorProtocol {
    
    static public func reevaluate(message: Message, completion:  @escaping ()->Void) {
        let pEpMessage = message.cdObject.pEpMessage()
        if pEpMessage.direction == .outgoing {
            PEPSession().outgoingRating(for: pEpMessage, errorCallback: { (error) in
                Log.shared.errorAndCrash("%@", error.localizedDescription)
                completion()
            }) { (rating) in
                storeNewRating(pEpRating: rating, to: message.cdObject, completion: completion)
            }
        } else {
            let keys = message.cdObject.keysFromDecryption?.array as? [String]
            var originaRating = PEPRating.undefined
            if let originalRatingString = message.optionalFields[Headers.originalRating.rawValue] {
                originaRating = PEPRating.fromString(str: originalRatingString)
            }
            PEPSession().reEvaluateMessage(pEpMessage, xKeyList: keys, originalRating: originaRating, errorCallback: { (error) in
                Log.shared.errorAndCrash("%@", error.localizedDescription)
                completion()
            }) { (newRating) in
                storeNewRating(pEpRating: newRating, to: message.cdObject, completion: completion)
            }
        }
    }
}

// MARK: - PRIVATE

extension RatingReEvaluator {
    static private func storeNewRating(pEpRating: PEPRating,
                                  to cdMessage: CdMessage,
                                  completion:  @escaping ()->Void) {
        DispatchQueue.main.async {
            cdMessage.pEpRating = Int16(pEpRating.rawValue)
            cdMessage.managedObjectContext?.saveAndLogErrors()
            completion()
        }
    }
}
