//
//  Rating+UI.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension Rating {
    var isNoColor: Bool {
        get {
            return pEpColor() == .noColor
        }
    }

    func statusIcon() -> UIImage? {
        let color = pEpColor()
        return color.statusIconForMessage()
    }
}
