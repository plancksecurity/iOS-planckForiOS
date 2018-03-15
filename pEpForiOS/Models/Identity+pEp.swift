//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Identity {
    open static func from(pEpIdentityDict: PEPIdentityDict) -> Identity? {
        if let address = pEpIdentityDict[kPepAddress] as? String {
            let id = Identity.create(address: address,
                                     userID: pEpIdentityDict[kPepUserID] as? String,
                                     userName: pEpIdentityDict[kPepUsername] as? String)
            return id
        }
        return nil
    }

    open static func from(pEpIdentity: PEPIdentity) -> Identity {
        let id = Identity.create(address: pEpIdentity.address, userID: pEpIdentity.userID,
                                 userName: pEpIdentity.userName)
        return id
    }

    public func pEpRating(session: PEPSession = PEPSession()) -> PEP_rating {
        return PEPUtil.pEpRating(identity: self, session: session)
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEP_color {
        return PEPUtil.pEpColor(identity: self, session: session)
    }

    public func pEpIdentity() -> PEPIdentity {
        return PEPUtil.pEp(identity: self)
    }
    
    open func fingerPrint(session: PEPSession = PEPSession()) throws -> String? {
        return try PEPUtil.fingerPrint(identity: self, session: session)
    }

    public func canHandshakeOn(session: PEPSession = PEPSession()) -> Bool {
        if isMySelf {
            return false
        }
        let rating = pEpRating(session: session)
        return rating == PEP_rating_reliable
    }

    public func canResetTrust(session: PEPSession = PEPSession()) -> Bool {
        let color = pEpColor(session: session)
        return color == PEP_color_green || color == PEP_color_red
    }

    public func decorateButton(button: UIButton, session: PEPSession = PEPSession()) {
        button.setTitleColor(.black, for: .normal)
        if let color = pEpColor(session: session).uiColor() {
            button.backgroundColor = color
        } else {
            let buttonDefault = UIButton()
            button.backgroundColor = buttonDefault.backgroundColor
            button.tintColor = buttonDefault.tintColor
        }
    }

    /**
     Will use update_identity() for other identities, and myself() for own ones.
     Returns: A `PEPIdentity` that has been updated and thus should contain the fingerprint.
     */
    public func updatedIdentity(session: PEPSession = PEPSession()) -> PEPIdentity {
        let md = pEpIdentity()
        do {
            if md.isOwn {
                try session.mySelf(md)
            } else {
                try session.update(md)
            }
        } catch let error as NSError {
            assertionFailure("\(error)")
        }
        return md
    }
}
