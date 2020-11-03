//
//  String+NSAttributedString.swift
//  pEp
//
//  Created by Adam Kowalski on 27/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    /// Create NSAttributedString with preffered default font face and size attributes (default option)
    /// - Parameter withDefaultFont: use preferred UIFont for body text
    func attribString(withDefaultFont: Bool = true) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)]

        return NSAttributedString(string: self,
                                  attributes: withDefaultFont ? attributes : [:])
    }
}
