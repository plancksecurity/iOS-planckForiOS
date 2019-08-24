//
//  HandshakePartnerTableViewCellViewModel.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework
import PEPObjCAdapterFramework

class HandshakePartnerTableViewCellViewModel {

    enum ExpandedState {
        case notExpanded
        case expanded
    }

    ///The background changes depending on the position in the list, alternating between
    ///light and dark.
    var backgroundColorDark = true

    ///Do we show the trustwords for this identity?
    var showTrustwords: Bool {
        switch partnerColor {
        case .yellow:
            return true
        default:
            return false
        }
    }

    /** Show the button for start/stop trusting? */
    var showStopStartTrustButton: Bool {
        return partnerColor == .green || partnerColor == PEPColor.red ||
            partnerRating == .haveNoKey
    }

    var expandedState: ExpandedState

    /// The rating of the partner.
    var partnerRating: PEPRating

    /// The color of the partner.
    var partnerColor: PEPColor

    var trustwordsLanguage: String {
        didSet{
            updateTrustwords(pEpSession: PEPSession())
        }
    }
    var trustwordsFull = false

    var ownName: String {
        return pEpSelf.userName ?? pEpSelf.address
    }

    var partnerName: String {
        return pEpPartner.userName ?? pEpPartner.address
    }

    var partnerImage = ObservableValue<UIImage>()
    var trustwords: String?

    var isPartnerpEpUser = false

    /// Have to store this for some future access from the owning VC.
    let ownIdentity: Identity

    private let partnerIdentity: Identity

    ///Cache the updated own identity.
    var pEpSelf: PEPIdentity

    /// Cache the updated partner identity.
    var pEpPartner: PEPIdentity

    lazy var contactImageTool = IdentityImageTool()

    init(ownIdentity: Identity, partner: Identity) {
        let pEpSession = PEPSession()
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        self.partnerRating = partner.pEpRating(pEpSession: pEpSession)
        self.pEpPartner = partner.updatedIdentity(pEpSession: pEpSession)
        self.pEpSelf = ownIdentity.updatedIdentity(pEpSession: pEpSession)
        self.partnerColor = partnerRating.pEpColor()

        do {
            isPartnerpEpUser = try pEpSession.isPEPUser(pEpPartner).boolValue
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            isPartnerpEpUser = false
        }

        partnerIdentity.session.performAndWait { [weak self] in
            self?.setPartnerImage(for: partner)
        }
        updateTrustwords(pEpSession: pEpSession)
    }

    private func setPartnerImage(`for` partnerIdentity: Identity) {
        if let cachedContactImage =
            contactImageTool.cachedIdentityImage(for: IdentityImageTool.IdentityKey(identity: partnerIdentity)) {
            partnerImage.value = cachedContactImage
        } else {
            let session = Session()
            let safePartnerIdentity = partnerIdentity.safeForSession(session)
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                session.performAndWait {
                    let contactImage = me.contactImageTool.identityImage(for:
                        IdentityImageTool.IdentityKey(identity: safePartnerIdentity))
                    me.partnerImage.value = contactImage
                }
            }
        }
    }

    func updateTrustwords(pEpSession: PEPSession) {
        if !isPartnerpEpUser,
            let fprSelf = pEpSelf.fingerPrint,
            let fprPartner = pEpPartner.fingerPrint {
            let fprPrettySelf = fprSelf.prettyFingerPrint()
            let fprPrettyPartner = fprPartner.prettyFingerPrint()
            self.trustwords =
                "\(partnerName):\n\(fprPrettyPartner)\n\n" + "\(ownName):\n\(fprPrettySelf)"
        } else {
            self.trustwords = determineTrustwords(identitySelf: pEpSelf,
                                                  identityPartner: pEpPartner,
                                                  pEpSession: pEpSession)
        }
    }

    func determineTrustwords(identitySelf: PEPIdentity,
                             identityPartner: PEPIdentity,
                             pEpSession: PEPSession) -> String? {
        do {
            return try pEpSession.getTrustwordsIdentity1(identitySelf,
                                                           identity2: identityPartner,
                                                           language: trustwordsLanguage,
                                                           full: trustwordsFull)
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            return nil
        }
    }

    func toggleTrustwordsLength(pEpSession: PEPSession) {
        trustwordsFull = !trustwordsFull
        updateTrustwords(pEpSession: pEpSession)
    }

    func invokeTrustAction(pEpSession: PEPSession, action: (PEPIdentity) -> ()) {
        let theBackup = PEPIdentity(identity: pEpPartner)
        action(pEpPartner)
        pEpPartner = theBackup

        do {
            partnerRating = try pEpSession.rating(for: pEpPartner).pEpRating
            partnerColor = PEPUtils.pEpColor(pEpRating: partnerRating, pEpSession: pEpSession)
        } catch let error as NSError {
            assertionFailure("\(error)")
        }

        updateTrustwords(pEpSession: pEpSession)
    }

    public func confirmTrust(pEpSession: PEPSession) {
        invokeTrustAction(pEpSession: pEpSession) { thePartner in
            do {
                try pEpSession.trustPersonalKey(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    public func denyTrust(pEpSession: PEPSession) {
        invokeTrustAction(pEpSession: pEpSession) { thePartner in
            do {
                try pEpSession.keyMistrusted(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    /// Used for undoing a trust or mistrust.
    /// - Note: Since undoLastMistrust is currently not implemented with all consequences,
    /// it is not used.
    public func resetOrUndoTrustOrMistrust(pEpSession: PEPSession) {
        invokeTrustAction(pEpSession: pEpSession) { thePartner in
            do {
                try pEpSession.keyResetTrust(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }
}
