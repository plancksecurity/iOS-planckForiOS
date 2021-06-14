//
//  Array+Attachments.swift
//  MessageModel
//
//  Created by Martín Brude on 14/6/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

extension Array where Element == Attachment {

    /// - Returns: The sum of the attachment sizes
    public func size() -> Double {
        return Double(compactMap { $0.data }.reduce(0) { $0 + $1.count })
    }
}
