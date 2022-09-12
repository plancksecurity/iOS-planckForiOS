//
//  OutgoingRatingServiceProtocol.swift
//  MessageModel
//
//  Created by Martín Brude on 12/9/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol OutgoingRatingServiceProtocol: AnyObject {

    /// Handle changes in outgoing messages ratings
    func handleOutgoingRatingChange()
}
