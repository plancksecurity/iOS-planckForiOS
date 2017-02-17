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
            id.isMySelf = (pEpIdentity[kPepIsMe] as? NSNumber)?.boolValue ?? false
            id.commType = (pEpIdentity[kPepCommType] as? NSNumber)?.intValue
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
    
    public var pEpDefaultScheme: (color: UIColor, image: UIImage) {
        return (color: .pEpNoColor, image: UIImage(named: "pep-user-status-gray")!)
    }
    
    public var pEpScheme: (color: UIColor, image: UIImage?) {
        get {
            switch self.pEpColor() {
            case PEP_color_no_color:
                return (color: .pEpNoColor, image: nil)
            case PEP_color_yellow:
                return (color: .pEpYellow, image: UIImage(named: "pep-user-status-yellow")!)
            case PEP_color_green:
                return (color: .pEpGreen, image: UIImage(named: "pep-user-status-green")!)
            case PEP_color_red:
                return (color: .pEpRed, image: UIImage(named: "pep-user-status-red")!)
            default:
                return (color: .pEpNoColor, image: nil)
            }
        }
    }

    open func fingerPrint(session: PEPSession? = PEPSession()) -> String? {
        return PEPUtil.fingerPrint(identity: self, session: session ?? PEPSession())
    }

    public func canHandshakeOn(session: PEPSession? = PEPSession()) -> Bool {
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
}
