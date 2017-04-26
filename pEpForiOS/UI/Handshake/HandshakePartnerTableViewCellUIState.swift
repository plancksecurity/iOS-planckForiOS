//
//  HandshakePartnerTableViewCellUIState.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class HandshakePartnerTableViewCellUIState {
    /**
     The UI relevant state of the displayed identity.
     Independent of the state of the Identity, you can expand the cell.
     The expanded version will show the explanation.
     */
    enum IdentityState {
        case illegal

        /**
         The identity is mistrusted (red), which means that no trustwords whatsoever
         should be shown. You might be able to expand, which means you see the explanation.
         pEpForIOS-Handshake-Mistrusted.png
         pEpForIOS-Handshake-Mistrusted-ExpandedText.png
         */
        case mistrusted

        /**
         The identity is already secure (yellow, so to speak).
         Again, you can expand the cell, which will show you the explanation.
         */
        case secure

        /**
         The identity is already trusted (green).
         */
        case secureAndTrusted

        static func from(identity: Identity) -> IdentityState {
            let color = identity.pEpColor()
            switch color {
            case PEP_color_red:
                return .mistrusted
            case PEP_color_yellow:
                return .secure
            case PEP_color_green:
                return .secureAndTrusted
            default:
                return .illegal
            }
        }

        var showStopStartTrustButton: Bool {
            return self == .mistrusted || self == .secureAndTrusted
        }
    }

    enum ExpandedState {
        case notExpanded
        case expanded
    }

    var expandedState: ExpandedState
    var identityState: IdentityState
    var trustwordsLanguage: String
    var trustwordsFull: Bool

    let partnerIdentity: Identity

    var partnerImage: ObservableValue<UIImage> = ObservableValue(value: nil)
    var rating: PEP_rating = PEP_rating_undefined
    var trustwords: String?

    init(selfIdentity: Identity, partner: Identity, session: PEPSession?,
         imageProvider: IdentityImageProvider) {
        self.expandedState = .notExpanded
        self.identityState = IdentityState.from(identity: partner)
        self.trustwordsLanguage = "en"
        self.trustwordsFull = true
        self.partnerIdentity = partner

        imageProvider.image(forIdentity: partner) { [weak self] img, ident in
            if partner == ident {
                self?.partnerImage.value = img
            }
        }

        let theSession = session ?? PEPSession()
        self.rating = partner.pEpRating(session: theSession)

        let pEpSelf = selfIdentity.pEpIdentity().mutableDictionary().update(session: theSession)
        let pEpPartner = partner.pEpIdentity().mutableDictionary().update(session: theSession)
        self.trustwords = theSession.getTrustwordsIdentity1(
            pEpSelf.pEpIdentity(),
            identity2: pEpPartner.pEpIdentity(),
            language: trustwordsLanguage,
            full: trustwordsFull)
    }
}
