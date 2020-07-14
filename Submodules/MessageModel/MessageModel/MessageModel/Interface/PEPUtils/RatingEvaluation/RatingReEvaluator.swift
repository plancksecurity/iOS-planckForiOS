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
    ///
    /// - Parameter message: message to re-evaluate rating for
    static func reevaluate(message: Message)
}

public class RatingReEvaluator {

    // Is currently pure static
    private init() {}
}

extension RatingReEvaluator: RatingReEvaluatorProtocol {

    static public func reevaluate(message: Message) {//!!!: IOS-2325_!

        let pepMessage = message.cdObject.pEpMessage()
        do {
            let keys = message.cdObject.keysFromDecryption?.array as? [String] //!!!: Needs to be extented when implementing "Extra Keys" feature to take X-KeyList header into account
            var newRating = PEPRating.undefined
            try PEPSession().reEvaluateMessage(pepMessage,//!!!: IOS-2325_!
                                               xKeyList: keys,
                                               rating: &newRating,
                                               status: nil)
            message.cdObject.pEpRating = Int16(newRating.rawValue)
            message.session.moc.performAndWait {
                message.session.moc.saveAndLogErrors()
            }

        } catch let error as NSError {
            Log.shared.log(error: error)
        }
    }
}
