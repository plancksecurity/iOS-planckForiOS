//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Identity {
    open static func from(pEpIdentity: PEPIdentityDict) -> Identity? {
        if let address = pEpIdentity[kPepAddress] as? String {
            let id = Identity.create(address: address, userID: pEpIdentity[kPepUserID] as? String,
                                     userName: pEpIdentity[kPepUsername] as? String)
            return id
        }
        return nil
    }

    public func pEpRating(session: PEPSession = PEPSession()) -> PEP_rating {
        return PEPUtil.pEpRating(identity: self, session: session)
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEP_color {
        return PEPUtil.pEpColor(identity: self, session: session)
    }

    public func pEpIdentity() -> PEPIdentityDict {
        return PEPUtil.pEp(identity: self)
    }
    
    open func fingerPrint(session: PEPSession = PEPSession()) -> String? {
        return PEPUtil.fingerPrint(identity: self, session: session)
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
     Returns: A NSMutableDictionary that has been updated and thus should contain
     the fingerprint.
     */
    public func updatedIdentityDictionary(session: PEPSession = PEPSession()) -> PEPIdentity {
        let md = pEpIdentity()
        session.updateIdentity(md)
        return md
    }
}
