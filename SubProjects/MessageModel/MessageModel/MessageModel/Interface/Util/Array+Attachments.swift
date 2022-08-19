//
//  Array+Attachments.swift
//  MessageModel
//
//  Created by Martín Brude on 14/6/21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

extension Array where Element == Attachment {

    /// - Returns: The sum of the attachment sizes in bytes.
    public func size() -> Double {
        return Double(compactMap { $0.data?.count }.reduce(0, +))
    }
}
