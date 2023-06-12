//
//  Color+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapter


extension Color {

    init(pEpColor: PEPColor) {
        switch pEpColor {
        case .noColor:
            self = .red
        case .yellow:
            self = .yellow
        case .green:
            self = .green
        case .red:
            self = .red
        }
    }
}
