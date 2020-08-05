//
//  Message+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import CoreData
import PEPObjCAdapterFramework

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
        var isOkToShowAttachments = true
        let msgRatingInt = pEpRatingInt
        if let rating = PEPUtils.pEpRatingFromInt(msgRatingInt) {
            isOkToShowAttachments = !rating.dontShowAttachments()
        }
        return isOkToShowAttachments
    }

    private func getOriginalRatingHeader() -> String? {
        return optionalFields[Headers.originalRating.rawValue]
    }

    private func getOriginalRatingHeaderRating() -> PEPRating? {
        guard let originalRatingStr = getOriginalRatingHeader() else {
            return nil
        }
        return PEPRating.fromString(str: originalRatingStr)
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
        let originalRating = message.getOriginalRatingHeaderRating()
        switch message.parent.folderType {
        case .sent, .trash, .drafts:
            completion(originalRating ?? bestFallbackPepRatingWeCanGet(forCdMessage: message.cdObject))
        case .outbox:
            return message.outgoingMessageRating(completion: completion)//!!!: IOS-2325_!
        case .all, .archive, .inbox, .normal, .spam, .flagged:
            if message.cdObject.isOnTrustedServer {
                completion(originalRating ?? bestFallbackPepRatingWeCanGet(forCdMessage: message.cdObject))
            } else {
                completion(PEPUtils.pEpRatingFromInt(message.pEpRatingInt) ?? .undefined)
            }
        case .pEpSync:
            // messages from this folder should never be shown to the user
            completion(.unreliable)
        }
    }

    static private func bestFallbackPepRatingWeCanGet(forCdMessage cdMsg: CdMessage) -> PEPRating {
        return PEPRating(rawValue: Int32(cdMsg.pEpRating)) ?? .undefined
    }
}
