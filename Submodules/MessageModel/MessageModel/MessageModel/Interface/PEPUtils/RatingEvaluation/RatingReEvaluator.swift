//
//  RatingReEvaluator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData
import PEPObjCAdapterFramework

protocol RatingReEvaluatorProtocol {
    /// Reevaluates the pEp rating of the given message and saves it.
    /// - Parameters:
    ///   - message: message to re-evaluate rating for
    ///   - completion: called when done reevaluating. I quaranteed to be called on the main queue.
    static func reevaluate(message: Message, completion:  @escaping ()->Void)
}

public class RatingReEvaluator {

    // Is currently pure static
    private init() {}
}

extension RatingReEvaluator: RatingReEvaluatorProtocol {
    
    static public func reevaluate(message: Message, completion:  @escaping ()->Void) {
        let pepMessage = message.cdObject.pEpMessage()
        let keys = message.cdObject.keysFromDecryption?.array as? [String]
        var originaRating = PEPRating.undefined
        if let originalRatingString = message.optionalFields[Headers.originalRating.rawValue] {
            originaRating = PEPRating.fromString(str: originalRatingString)
        }
        PEPAsyncSession().reEvaluateMessage(pepMessage, xKeyList: keys, originalRating: originaRating, errorCallback: { (error) in
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            completion()
        }) { (newRating) in
            DispatchQueue.main.async {
                message.cdObject.pEpRating = Int16(newRating.rawValue)
                message.session.moc.saveAndLogErrors()
                completion()
            }
        }
    }
}
