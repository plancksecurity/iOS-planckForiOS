//
//  HandshakePartnerTableViewCellViewModel.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class HandshakePartnerTableViewCellViewModel {
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

        static func from(identity: Identity, session: PEPSession = PEPSession()) -> IdentityState {
            let color = identity.pEpColor(session: session)
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

        var showTrustwords: Bool {
            return self == .secure
        }
    }

    enum ExpandedState {
        case notExpanded
        case expanded
    }

    /**
     The background changes depending on the position in the list, alternating between
     light and dark.
     */
    var backgroundColorDark = true

    /**
     Do we show the trustwords for this identity?
     */
    var showTrustwords: Bool {
        return identityState.showTrustwords
    }

    var expandedState: ExpandedState
    var identityState: IdentityState
    var trustwordsLanguage: String
    var trustwordsFull: Bool

    /**
     The own identity that is concerned with the trust.
     */
    let ownIdentity: Identity

    /**
     The partner identity that we want to trust (or not).
     */
    let partnerIdentity: Identity
    var partnerName: String? {
        return partnerIdentity.userName ?? partnerIdentity.address
    }

    var partnerImage = ObservableValue<UIImage>()
    var rating: PEP_rating = PEP_rating_undefined
    var trustwords: String?

    /**
     pEp session usable on the main thread.
     */
    let session: PEPSession

    init(ownIdentity: Identity, partner: Identity, session: PEPSession?,
         imageProvider: IdentityImageProvider) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.trustwordsFull = true
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        let theSession = session ?? PEPSession()
        self.session = theSession
        self.identityState = IdentityState.from(identity: partner, session: theSession)

        imageProvider.image(forIdentity: partner) { [weak self] img, ident in
            if partner == ident {
                self?.partnerImage.value = img
            }
        }

        self.rating = partner.pEpRating(session: theSession)

        let pEpSelf = ownIdentity.pEpIdentity().mutableDictionary().update(session: theSession)
        let pEpPartner = partner.pEpIdentity().mutableDictionary().update(session: theSession)
        self.trustwords = theSession.getTrustwordsIdentity1(
            pEpSelf.pEpIdentity(),
            identity2: pEpPartner.pEpIdentity(),
            language: trustwordsLanguage,
            full: trustwordsFull)
    }

    func invokeTrustAction(action: (NSMutableDictionary) -> ()) {
        let thePartner = partnerIdentity.pEpIdentity().mutableDictionary().update(
            session: session)
        action(thePartner)
        identityState = IdentityState.from(identity: partnerIdentity, session: session)
        rating = partnerIdentity.pEpRating(session: session)
    }

    public func confirmTrust() {
        invokeTrustAction() { thePartner in
            session.trustPersonalKey(thePartner)
        }
    }

    public func denyTrust() {
        invokeTrustAction() { thePartner in
            session.keyMistrusted(thePartner)
        }
    }

    public func startStopTrusting() {
        invokeTrustAction() { thePartner in
            session.keyResetTrust(thePartner)
        }
    }
}
