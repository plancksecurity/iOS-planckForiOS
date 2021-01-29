//
//  Dictionary+Extension.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 29/1/21.
//  Copyright © 2021 pEp Security SA. All rights reserved.
//

import Foundation

extension Dictionary {
    #if DEBUG
    /// Pretty print dictionary in console as json.
    ///
    /// Only for debug.
    public func printJson() {
        if let string = String(data: try! JSONSerialization.data(withJSONObject: self, options: .prettyPrinted), encoding: .utf8) {
            print(string)
        }
    }
    #endif
}
