//
//  NSSecureCoding+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSSecureCoding {
    /**
     Reconstructs an object from a string, that was created using `persistBase64Encoded()`.
     */
    public static func from(base64Encoded: String) -> Any? {
        guard let data = Data(base64Encoded: base64Encoded) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }

    /**
     Persists itself into a string, using Base64 as the encoding.
     Works in tandem with `from(base64Encoded:)`.
     */
    public func persistBase64Encoded() -> String {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return data.base64EncodedString()
    }
}
