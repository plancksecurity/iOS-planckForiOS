//
//  URL+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 24.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension URL {
    public func fileName(includingExtension incl: Bool = false) -> String {
        if incl {
            return self.lastPathComponent
        }
        return self.deletingPathExtension().lastPathComponent
    }
}
