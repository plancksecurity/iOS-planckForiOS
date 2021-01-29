//
//  Dictionary+PrettyPrint.swift.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 29/1/21.
//  Copyright © 2021 pEp Security SA. All rights reserved.
//

import Foundation

extension Dictionary {

    /// Pretty print dictionary in console as json.
    /// If the dictionary is not json compatible, does nothing.
    /// Only for Debug.
    ///
    /// Usage example:
    /// ["foo": [ "bar": [ "baz", 1.0, 2 ] ] ].printJson() prints the folllowing
    /// {
    ///    "foo" : {
    ///      "bar" : [
    ///        "baz",
    ///        1,
    ///        2
    ///      ]
    ///    }
    ///  }
    ///
    public func printJson() {
        #if DEBUG
        if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) {
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        }
        #endif
    }
}
