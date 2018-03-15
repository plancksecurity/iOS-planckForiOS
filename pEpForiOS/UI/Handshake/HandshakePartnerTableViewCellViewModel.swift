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
    var trustwords: String?

    /**
     pEp session usable on the main thread.
     */
    let session: PEPSession

    var isPartnerpEpUser = false

    /**
     Cache the updated own identity.
     */
    let pEpSelf: PEPIdentity

    /**
     Cache the updated partner identity.
     */
    var pEpPartner: PEPIdentity

    lazy var contactImageTool = IdentityImageTool()

    init(ownIdentity: Identity, partner: Identity, session: PEPSession) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        self.session = session
        self.identityColor = partner.pEpColor(session: session)

        pEpSelf = ownIdentity.updatedIdentity(session: session)
        pEpPartner = partner.updatedIdentity(session: session)

        isPartnerpEpUser = session.isPEPUser(pEpPartner)
        setPartnerImage(for: partner)
        updateTrustwords(session: session)
    }

    private func setPartnerImage(`for` partnerIdentity: Identity) {
        if let cachedContactImage =
            contactImageTool.cachedIdentityImage(forIdentity: partnerIdentity) {
            partnerImage.value = cachedContactImage
        } else {
            DispatchQueue.global().async {
                let contactImage = self.contactImageTool.identityImage(for: partnerIdentity)
                self.partnerImage.value = contactImage
            }
        }
    }

    func updateTrustwords(session: PEPSession = PEPSession()) {
        if !isPartnerpEpUser,
            let fprSelf = pEpSelf.fingerPrint,
            let fprPartner = pEpPartner.fingerPrint {
            let fprPrettySelf = fprSelf.prettyFingerPrint()
            let fprPrettyPartner = fprPartner.prettyFingerPrint()
            self.trustwords =
                "\(partnerIdentity.userName ?? partnerIdentity.address):\n\(fprPrettyPartner)\n\n" +
            "\(ownIdentity.userName ?? ownIdentity.address):\n\(fprPrettySelf)"
        } else {
            self.trustwords = determineTrustwords(identitySelf: pEpSelf,
                                                  identityPartner: pEpPartner)
        }
    }

    /**
     If the message is defined, and the partner is the sender, tries message trustwords.
     If not, or message trustwords does not compute, it determines the trustwords between
     the 2 identities.
     */
    func determineTrustwords(identitySelf: PEPIdentity, identityPartner: PEPIdentity) -> String? {
        let trustwordsResult = session.getTrustwordsIdentity1(
            identitySelf,
            identity2: identityPartner,
            language: trustwordsLanguage,
            full: trustwordsFull)
        return trustwordsResult
    }

    func toggleTrustwordsLength() {
        trustwordsFull = !trustwordsFull
        updateTrustwords(session: session)
    }

    func invokeTrustAction(action: (PEPIdentity) -> ()) {
        action(pEpPartner)
        identityColor = partnerIdentity.pEpColor(session: session)
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

    public func resetTrust() {
        invokeTrustAction() { thePartner in
            session.keyResetTrust(thePartner)
        }
    }
}
