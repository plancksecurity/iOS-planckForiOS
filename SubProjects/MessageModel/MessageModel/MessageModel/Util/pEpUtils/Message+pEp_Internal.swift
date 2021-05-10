//
//  Message+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

// MARK: - Internal
extension Message {
    func setOriginalRatingHeader(rating: String) {
        addToOptionalFields(key: Headers.originalRating.rawValue, value: rating)
    }

    func outgoingMessageRating(completion: @escaping (PEPRating)->Void) {
        return cdObject.outgoingMessageRating(completion: completion)
    }
}

// MARK: - Private

extension Message {
    var ratingIsOkToShowAttachments: Bool {
        let msgRatingInt = pEpRatingInt
        let rating = PEPUtils.pEpRatingFromInt(msgRatingInt)
        let isOkToShowAttachments = !rating.dontShowAttachments()
        return isOkToShowAttachments
    }
}

// MARK: - Private session and main session objects getters

extension Message {

    //!!!: MUST be changed while refactoring HandshakeView. MUST NOT use Message MM intarnally.
    static func pEpRating(message: Message,
                          session: Session,
                          completion: @escaping (PEPRating)->Void) {
        session.performAndWait {
            pEpRating(message: message, completion: completion)
        }
    }

    //!!!: MUST be changed while refactoring HandshakeView. MUST NOT use Message MM intarnally.
    static func pEpRating(message: Message,
                          completion: @escaping (PEPRating)->Void) {
        switch message.parent.folderType {
        case .outbox:
            return message.outgoingMessageRating(completion: completion)
        case .drafts:
            // In case we have en error while encrypting, the outgoingMessageRating might be
            // yellow/green but due to the error while encrypting the message is actually unencrypted.
            // Thus we show outgoingMessageRating only if no rating has been defined yet.
            if message.cdObject.pEpRating == PEPRating.undefined.rawValue {
                message.outgoingMessageRating(completion: completion)
            } else {
                completion(PEPUtils.pEpRatingFromInt(message.pEpRatingInt))
            }
        case .all, .archive, .inbox, .normal, .sent, .spam, .flagged, .trash:
            completion(PEPUtils.pEpRatingFromInt(message.pEpRatingInt))
        case .pEpSync:
            // messages from this folder should never be shown to the user
            completion(.unreliable)
        }
    }
}
