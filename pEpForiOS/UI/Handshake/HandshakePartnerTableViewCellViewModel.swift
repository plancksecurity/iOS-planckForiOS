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
    enum ExpandedState {
        case notExpanded
        case expanded
    }

    /**
     The background changes depending on the position in the list, alternating between
     light and dark.
     */
    var backgroundColorDark = true

    /** Do we show the trustwords for this identity? */
    var showTrustwords: Bool {
        return identityColor == PEP_color_yellow
    }

    /** Show the button for start/stop trusting? */
    var showStopStartTrustButton: Bool {
        return identityColor == PEP_color_red || identityColor == PEP_color_green
    }

    var expandedState: ExpandedState
    var identityColor: PEP_color
    var trustwordsLanguage: String
    var trustwordsFull = false

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

    var isPartnerPGPUser = false

    /**
     Cache the updated own identity.
     */
    let pEpSelf: NSMutableDictionary

    /**
     Cache the updated partner identity.
     */
    var pEpPartner: NSMutableDictionary

    init(ownIdentity: Identity, partner: Identity, session: PEPSession,
         imageProvider: IdentityImageProvider) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        self.session = session
        self.identityColor = partner.pEpColor(session: session)

        self.rating = partner.pEpRating(session: session)

        pEpSelf = ownIdentity.updatedIdentityDictionary(session: session)
        pEpPartner = partner.updatedIdentityDictionary(session: session)

        isPartnerPGPUser = pEpPartner.isPGP

        imageProvider.image(forIdentity: partner) { [weak self] img, ident in
            if partner == ident {
                self?.partnerImage.value = img
            }
        }

        updateTrustwords(session: session)
    }

    func updateTrustwords(session: PEPSession) {
        if isPartnerPGPUser,
            let fprSelf = pEpSelf.object(forKey: kPepFingerprint) as? String,
            let fprPartner = pEpPartner.object(forKey: kPepFingerprint) as? String {
            let fprPrettySelf = fprSelf.prettyFingerPrint()
            let fprPrettyPartner = fprPartner.prettyFingerPrint()
            self.trustwords =
                "\(partnerIdentity.userName ?? partnerIdentity.address):\n\(fprPrettyPartner)\n\n" +
            "\(ownIdentity.userName ?? ownIdentity.address):\n\(fprPrettySelf)"
        } else {
            self.trustwords = session.getTrustwordsIdentity1(
                pEpSelf.pEpIdentity(),
                identity2: pEpPartner.pEpIdentity(),
                language: trustwordsLanguage,
                full: trustwordsFull)
        }
    }

    func toggleTrustwordsLength() {
        trustwordsFull = !trustwordsFull
        updateTrustwords(session: session)
    }

    func invokeTrustAction(action: (NSMutableDictionary) -> ()) {
        pEpPartner = partnerIdentity.updatedIdentityDictionary(session: session)
        action(pEpPartner)
        pEpPartner = partnerIdentity.updatedIdentityDictionary(session: session)
        isPartnerPGPUser = pEpPartner.isPGP
        identityColor = partnerIdentity.pEpColor(session: session)
        rating = partnerIdentity.pEpRating(session: session)
        updateTrustwords(session: session)
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
