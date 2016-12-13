//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Identity {
 
    public func pEpRating(session: PEPSession? = nil) -> PEP_rating {
        return PEPUtil.pEpRating(identity: self, session: session)
    }

    public func pEpColor(session: PEPSession? = nil) -> PEP_color {
        return PEPUtil.pEpColor(identity: self, session: session)
    }

    public func pEpIdentity() -> PEPIdentity {
        return PEPUtil.pEp(identity: self)
    }
    
    public var pEpDefaultScheme: (color: UIColor, image: UIImage) {
        return (color: .pEpNoColor, image: UIImage(named: "pep-user-status-gray")!)
    }
    
    public var pEpScheme: (color: UIColor, image: UIImage) {
        get {
            switch self.pEpColor() {
            case PEP_color_no_color:
                return (color: .pEpNoColor, image: UIImage(named: "pep-user-status-gray")!)
            case PEP_color_yellow:
                return (color: .pEpYellow, image: UIImage(named: "pep-user-status-yellow")!)
            case PEP_color_green:
                return (color: .pEpColor, image: UIImage(named: "pep-user-status-green")!)
            case PEP_color_red:
                return (color: .pEpRed, image: UIImage(named: "pep-user-status-red")!)
            default:
                return (color: .pEpNoColor, image: UIImage(named: "pep-user-status-gray")!)
            }
        }
    }
}
