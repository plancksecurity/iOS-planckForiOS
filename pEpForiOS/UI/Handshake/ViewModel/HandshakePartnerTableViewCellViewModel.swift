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

    /**
     The background changes depending on the position in the list, alternating between
     light and dark.
     */
    var backgroundColorDark = true

    /** Do we show the trustwords for this identity? */
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

    /**
     The rating of the partner.
     */
    var partnerRating: PEPRating

    /**
     The color of the partner.
     */
    var partnerColor: PEPColor

    var trustwordsLanguage: String {
        didSet{
            updateTrustwords()
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

    /**
     Have to store this for some future access from the owning VC.
     */
    let ownIdentity: Identity

    private let partnerIdentity: Identity

    /**
     Cache the updated own identity.
     */
    var pEpSelf: PEPIdentity

    /**
     Cache the updated partner identity.
     */
    var pEpPartner: PEPIdentity

    lazy var contactImageTool = IdentityImageTool()

    init(ownIdentity: Identity, partner: Identity) {
        self.expandedState = .notExpanded
        self.trustwordsLanguage = "en"
        self.ownIdentity = ownIdentity
        self.partnerIdentity = partner
        self.partnerRating = PEPUtils.pEpRating(identity: partner)
        self.pEpPartner = partner.updatedIdentity()
        self.pEpSelf = ownIdentity.updatedIdentity()
        self.partnerColor = partnerRating.pEpColor()

        do {
            isPartnerpEpUser = try PEPSession().isPEPUser(pEpPartner).boolValue
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            isPartnerpEpUser = false
        }

        partnerIdentity.session.performAndWait { [weak self] in
            self?.setPartnerImage(for: partner)
        }
        updateTrustwords()
    }

    private func setPartnerImage(`for` partnerIdentity: Identity) {
        if let cachedContactImage =
            contactImageTool.cachedIdentityImage(for: IdentityImageTool.IdentityKey(identity: partnerIdentity)) {
            partnerImage.value = cachedContactImage
        } else {
            let session = Session()
            let safePartnerIdentity = partnerIdentity.safeForSession(session)
            DispatchQueue.global().async { [weak self] in
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

    func determineTrustwords(identitySelf: PEPIdentity, identityPartner: PEPIdentity) -> String? {
        do {
            return try PEPSession().getTrustwordsIdentity1(
                identitySelf,
                identity2: identityPartner,
                language: trustwordsLanguage,
                full: trustwordsFull)
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            return nil
        }
    }

    func toggleTrustwordsLength() {
        trustwordsFull = !trustwordsFull
        updateTrustwords()
    }

    func invokeTrustAction(action: (PEPIdentity) -> ()) {
        let theBackup = PEPIdentity(identity: pEpPartner)
        action(pEpPartner)
        pEpPartner = theBackup

        do {
            partnerRating = try PEPSession().rating(for: pEpPartner).pEpRating
            partnerColor = PEPUtils.pEpColor(pEpRating: partnerRating)
        } catch let error as NSError {
            assertionFailure("\(error)")
        }

        updateTrustwords()
    }

    public func confirmTrust() {
        invokeTrustAction() { thePartner in
            do {
                try PEPSession().trustPersonalKey(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    public func denyTrust() {
        invokeTrustAction() { thePartner in
            do {
                try PEPSession().keyMistrusted(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }

    /**
     Used for undoing a trust or mistrust.
     - Note: Since undoLastMistrust is currently not implemented with all consequences,
     it is not used.
     */
    public func resetOrUndoTrustOrMistrust() {
        invokeTrustAction() { thePartner in
            do {
                try PEPSession().keyResetTrust(thePartner)
            } catch let error as NSError {
                assertionFailure("\(error)")
            }
        }
    }
}
