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
            self = .noColor
        case .green:
            self = .green
        case .red:
            self = .red
        case .yellow:
            // This is not an error: please see PEMA-89.
            self = .green
        }
    }

    func pEpColor() -> PEPColor {
        switch self {
        case .noColor:
            return .noColor
        case .green:
            return .green
        case .red:
            return .red
        }
    }
}
