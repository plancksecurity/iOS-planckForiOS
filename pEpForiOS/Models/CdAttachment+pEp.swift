//
//  CdAttachment+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdAttachment {
    public func pEpAttachment() -> [String: AnyObject] {
        return PEPUtil.pEp(cdAttachment: self)
    }
}
