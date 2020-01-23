//
//  Enum+Iterable.swift
//  pEp
//
//  Created by Martin Brude on 21/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension CaseIterable where Self: Equatable {

    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
