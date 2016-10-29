//
//  SendLayerError+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension SendLayerError {
    func asString() -> String {
        switch self {
        case .ConnectionProblem: return NSLocalizedString(
            "Connection problem", comment: "Error message")
        }
    }
}
