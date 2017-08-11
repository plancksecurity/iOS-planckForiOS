//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Identity {
    open static func from(pEpIdentity: PEPIdentity) -> Identity? {
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

    public func pEpIdentity() -> PEPIdentity {
        return PEPUtil.pEp(identity: self)
    }
    
    open func fingerPrint(session: PEPSession? = PEPSession()) -> String? {
        return PEPUtil.fingerPrint(identity: self, session: session ?? PEPSession())
    }

    public func canHandshakeOn(session: PEPSession? = PEPSession()) -> Bool {
        if isMySelf {
            return false
        }
        let rating = pEpRating(session: session ?? PEPSession())
        return rating.rawValue >= PEP_rating_reliable.rawValue || rating == PEP_rating_mistrust
    }

    public func canResetTrust(session: PEPSession? = PEPSession()) -> Bool {
        let color = pEpColor(session: session ?? PEPSession())
        return color == PEP_color_green || color == PEP_color_red
    }

    public func decorateButton(button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        if let color = pEpColor().uiColor() {
            button.backgroundColor = color
        } else {
            let buttonDefault = UIButton()
            button.backgroundColor = buttonDefault.backgroundColor
            button.tintColor = buttonDefault.tintColor
        }
    }

    /**
     Returns: A NSMutableDictionary that has been updated and thus should contain
     the fingerprint.
     */
    public func updatedIdentityDictionary(session: PEPSession) -> NSMutableDictionary {
        let md = pEpIdentity().mutableDictionary()
        md.update(session: session)
        return md
    }
}
