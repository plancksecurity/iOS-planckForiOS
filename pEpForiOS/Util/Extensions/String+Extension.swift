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
        return self.contains { Int(String($0)) == nil }
    }
}
