//
//  Color+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension Color {
    static func from(pEpRating: PEPColor) -> Color {
        switch pEpRating {
        case .noColor:
            return noColor
        case .yellow:
            return yellow
        case .green:
            return green
        case .red:
            return red
        }
    }
}
