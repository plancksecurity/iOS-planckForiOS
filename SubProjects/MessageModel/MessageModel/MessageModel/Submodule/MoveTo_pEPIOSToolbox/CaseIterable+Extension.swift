//
//  CaseIterable+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 7/12/20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension CaseIterable where Self: Equatable {

    /// Returns the index of a case in the enum.
    public var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
