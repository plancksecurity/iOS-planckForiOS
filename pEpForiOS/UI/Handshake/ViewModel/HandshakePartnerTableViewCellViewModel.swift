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
        switch partnerColor {
        case PEP_color_yellow:
            return true
        default:
            return false
        }
    }

    /** Show the button for start/stop trusting? */
    var showStopStartTrustButton: Bool {
        switch partnerColor {
        case PEP_color_green, PEP_color_red:
            return true
        default:
            return false
        }
    }

    var expandedState: ExpandedState

    /**
     The rating of the partner.
     */
    var partnerRating: PEP_rating

    /**
     The color of the partner.
     */
    var partnerColor: PEP_color

    var trustwordsLanguage: String
    var trustwordsFull = false

    var ownName: String {
        return pEpSelf.userName ?? pEpSelf.address
    }

    var partnerName: String {
        return pEpPartner.userName ?? pEpPartner.address
    }

    var partnerImage = ObservableValue<UIImage>()
    var trustwords: String?

    /**
     pEp session usable on the main thread.
     */
    let session: PEPSession

    var isPartnerpEpUser = false

    /**
     Have to store this for some future access from the owning VC.
     */
    let ownIdentity: Identity

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
        self.session = session
        self.partnerRating = PEPUtil.pEpRating(identity: partner, session: session)
        self.partnerColor = partnerRating.pepColor()
        self.ownIdentity = ownIdentity

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
                "\(partnerName):\n\(fprPrettyPartner)\n\n" + "\(ownName):\n\(fprPrettySelf)"
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
        let theBackup = PEPIdentity(identity: pEpPartner)
        action(pEpPartner)
        pEpPartner = theBackup

        do {
            try session.rating(&partnerRating, for: pEpPartner)
            partnerColor = PEPUtil.pEpColor(pEpRating: partnerRating)
        } catch let error as NSError {
            assertionFailure("\(error)")
        }

        updateTrustwords(session: session)
    }

    public func confirmTrust() {
        invokeTrustAction() { thePartner in
            do {
                try session.trustPersonalKey(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    public func denyTrust() {
        invokeTrustAction() { thePartner in
            do {
                try session.keyMistrusted(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    /**
     Used for undoing a trust or mistrust.

     - Note: Since undoLastMistrust is currently not
     implemented with all consequences, it is not used.
     */
    public func resetTrustOrUndoMistrust() {
        invokeTrustAction() { thePartner in
            do {
                try session.keyResetTrust(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }
}
