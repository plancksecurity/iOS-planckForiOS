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

    func outgoingMessageRating() -> PEPRating {
        return cdObject.outgoingMessageRating()
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
    static func pEpRating(message: Message, session: Session) -> PEPRating {
        var result: PEPRating?
        session.performAndWait {
            result = pEpRating(message: message)
        }
        guard let safeResut = result else {
            Log.shared.errorAndCrash("Fail to get pEpRating in private session")
            return .undefined
        }
        return safeResut
    }

    //!!!: MUST be changed while refactoring HandshakeView. MUST NOT use Message MM intarnally.
    static func pEpRating(message: Message) -> PEPRating {
        let originalRating = message.getOriginalRatingHeaderRating()
        switch message.parent.folderType {
        case .sent, .trash, .drafts:
            return originalRating ?? bestFallbackPepRatingWeCanGet(forCdMessage: message.cdObject)
        case .outbox:
            return message.outgoingMessageRating()
        case .all, .archive, .inbox, .normal, .spam, .flagged:
            if message.cdObject.isOnTrustedServer {
                return originalRating ?? bestFallbackPepRatingWeCanGet(forCdMessage: message.cdObject)
            } else {
                return PEPUtils.pEpRatingFromInt(message.pEpRatingInt) ?? .undefined
            }
        case .pEpSync:
            // messages from this folder should never be shown to the user
            return .unreliable
        }
    }

    static private func bestFallbackPepRatingWeCanGet(forCdMessage cdMsg: CdMessage) -> PEPRating {
        return PEPRating(rawValue: Int32(cdMsg.pEpRating)) ?? .undefined
    }
}
