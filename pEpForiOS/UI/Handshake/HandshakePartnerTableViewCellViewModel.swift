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

    var isPartnerPGPUser = false

    init(ownIdentity: Identity, partner: Identity, session: PEPSession?,
         imageProvider: IdentityImageProvider) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.trustwordsFull = true
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        let theSession = session ?? PEPSession()
        self.session = theSession
        self.identityColor = partner.pEpColor(session: theSession)

        imageProvider.image(forIdentity: partner) { [weak self] img, ident in
            if partner == ident {
                self?.partnerImage.value = img
            }
        }

        self.rating = partner.pEpRating(session: theSession)

        let pEpSelf = ownIdentity.updatedIdentityDictionary(session: theSession)
        let pEpPartner = partner.updatedIdentityDictionary(session: theSession)

        isPartnerPGPUser = pEpPartner.isPGP
        if isPartnerPGPUser,
            let fprSelf = pEpSelf.object(forKey: kPepFingerprint) as? String,
            let fprPartner = pEpPartner.object(forKey: kPepFingerprint) as? String {
            let fprPrettySelf = fprSelf.prettyFingerPrint()
            let fprPrettyPartner = fprPartner.prettyFingerPrint()
            self.trustwords =
                "\(partner.userName ?? partner.address):\n\(fprPrettyPartner)\n\n" +
                "\(ownIdentity.userName ?? ownIdentity.address):\n\(fprPrettySelf)"
        } else {
            self.trustwords = theSession.getTrustwordsIdentity1(
                pEpSelf.pEpIdentity(),
                identity2: pEpPartner.pEpIdentity(),
                language: trustwordsLanguage,
                full: trustwordsFull)
        }
    }

    func invokeTrustAction(action: (NSMutableDictionary) -> ()) {
        let thePartner = partnerIdentity.updatedIdentityDictionary(session: session)
        action(thePartner)
        identityColor = partnerIdentity.pEpColor(session: session)
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
