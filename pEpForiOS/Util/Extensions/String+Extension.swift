//
//  String+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 05/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {

    var isDigits: Bool {
        return self.contains { Int(String($0)) != nil }
    }

    var isBackspace: Bool {
        guard let char = cString(using: .utf8) else {
            return false
        }
        let isBackSpace = strcmp(char, "\\b")
        if (isBackSpace == -92) {
            return true
        }
        return false
    }
    
}

