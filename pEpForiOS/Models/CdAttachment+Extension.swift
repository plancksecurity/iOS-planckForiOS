//
//  CdAttachment+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

extension CdAttachment {
    override open var description: String {
        let s = NSMutableString()
        s.append("Part \(size) bytes")
        if let fn = filename {
            s.append(", \(fn)")
        }
        if let ct = contentType {
            s.append(", \(ct)")
        }
        return String(s)
    }

    override open var debugDescription: String {
        return description
    }
}
