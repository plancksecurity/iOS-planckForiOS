//
//  ReplyAllPossibleCheckerProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol ReplyAllPossibleCheckerProtocol {
    func isReplyAllPossible() -> Bool
}
