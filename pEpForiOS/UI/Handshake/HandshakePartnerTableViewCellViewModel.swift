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

    /**
     A copy of the partner dictionary, in case the user wants to undo a "Mistrust" action.
     See ENGINE-254.
     */
    let pEpPartnerCopy: NSDictionary

    /**
     The message the status/trustwords are invoked for
     */
    let message: Message?

    init(message: Message?, ownIdentity: Identity, partner: Identity, session: PEPSession,
         imageProvider: IdentityImageProviderProtocol) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        self.session = session
        self.identityColor = partner.pEpColor(session: session)

        self.rating = partner.pEpRating(session: session)

        pEpSelf = ownIdentity.updatedIdentityDictionary(session: session)
        pEpPartner = partner.updatedIdentityDictionary(session: session)

        // backup the partner dict
        pEpPartnerCopy = NSDictionary(dictionary: pEpPartner)

        isPartnerPGPUser = pEpPartner.containsPGPCommType
        self.message = message

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
            self.trustwords = determineTrustwords(
                message: message, identitySelf: pEpSelf.pEpIdentity(),
                identityPartner: pEpPartner.pEpIdentity())
        }
    }

    /**
     If the message is defined, and the partner is the sender, tries message trustwords.
     If not, or message trustwords does not compute, it determines the trustwords between
     the 2 identies.
     */
    func determineTrustwords(
        message: Message?, identitySelf: PEPIdentity, identityPartner: PEPIdentity) -> String? {
        if let msg = message,
            let from = msg.from,
            let partnerAddress = identityPartner[kPepAddress] as? String,
            from.address == partnerAddress {
            var pEpMessage = msg.pEpMessage()
            pEpMessage[kPepFrom] = identityPartner as AnyObject
            var pEpResult = PEP_UNKNOWN_ERROR
            let trustwordsResult = session.getTrustwordsMessageDict(
                pEpMessage, receiverDict: identitySelf,
                keysArray: msg.keyListFromDecryption,
                language: trustwordsLanguage, full: trustwordsFull,
                resultingStatus: &pEpResult)
            if pEpResult != PEP_STATUS_OK {
                Log.shared.errorComponent(
                    #function,
                    message: "cannot get message trustwords: result \(pEpResult)")
            } else {
                return trustwordsResult
            }
        }
        let trustwordsResult = session.getTrustwordsIdentity1(
            pEpSelf.pEpIdentity(),
            identity2: pEpPartner.pEpIdentity(),
            language: trustwordsLanguage,
            full: trustwordsFull)
        return trustwordsResult
    }

    func toggleTrustwordsLength() {
        trustwordsFull = !trustwordsFull
        updateTrustwords(session: session)
    }

    func invokeTrustAction(action: (NSMutableDictionary) -> ()) {
        pEpPartner.diff(otherDict: pEpPartnerCopy)
        pEpPartner = NSMutableDictionary(dictionary: pEpPartnerCopy)
        action(pEpPartner)
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

    public func resetTrust() {
        invokeTrustAction() { thePartner in
            session.keyResetTrust(thePartner)
        }
    }
}
