//
//  PEPRating+Utils.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

// MARK: - PEPRating+Utils

extension PEPRating {

    /// Compares the pEp colors for this and a given rating.
    /// - Parameter rating: rating to compare pEp color with
    /// - returns:  true if the pEp color represents a less secure communication channel than the given one.
    ///             false otherwize.
    public func hasLessSecurePepColor(than rating: PEPRating) -> Bool {
        if rating.pEpColor() == .green &&
            self.pEpColor() != .green {
            return true
        } else if rating.pEpColor() == .yellow &&
            (self.pEpColor() != .green && self.pEpColor() != .yellow) {
            return true
        }
        else if rating.pEpColor() == .noColor &&
            (self.pEpColor() != .green && self.pEpColor() != .yellow && self.pEpColor() != .noColor) {
            return true
        }
        return false
    }
}
