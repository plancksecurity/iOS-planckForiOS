//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

extension Identity {
    public static func from(pEpIdentityDict: PEPIdentityDict) -> Identity? {
        if let address = pEpIdentityDict[kPepAddress] as? String {
            let id = Identity(address: address,
                              userID: pEpIdentityDict[kPepUserID] as? String,
                              userName: pEpIdentityDict[kPepUsername] as? String)
            return id
        }
        return nil
    }

    public static func from(pEpIdentity: PEPIdentity) -> Identity {
        let id = Identity(address: pEpIdentity.address,
                          userID: pEpIdentity.userID,
                          userName: pEpIdentity.userName)
        return id
    }

    public func pEpRating(session: PEPSession = PEPSession()) -> PEPRating {
        return PEPUtil.pEpRating(identity: self, session: session)
    }

    public func canResetTrust(session: PEPSession = PEPSession()) -> Bool {
        let color = PEPUtil.pEpColor(identity: self, session: session)
        return color == .green || color == PEPColor.red
    }

    public func decorateButton(button: UIButton, session: PEPSession = PEPSession()) {
        button.setTitleColor(.black, for: .normal)
        if let color = PEPUtil.pEpColor(identity: self, session: session).uiColor() {
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
        let md = PEPUtil.pEp(identity: self)
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

    public var displayString: String {
        return userName ?? address.trimmed()
    }
}
