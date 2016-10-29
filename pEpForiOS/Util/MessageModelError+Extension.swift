//
//  MessageModelError+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension MessageModelError {
    func asString() -> String {
        switch self {
        case .sendLayerError(let error):
            return error.asString()
        }
    }
}
