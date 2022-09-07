//
//  OutgoingRatingChangedDelegate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 07.09.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

protocol OutgoingRatingChangedDelegate: NSObject {
    /// This gets called when the echo protocol determined in the background
    /// that some partner identities changed their rating, so outgoing ratings have to be re-computed.
    func outgoingRatingChanged()
}
