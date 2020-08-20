//
//  TrustwordsLanguage+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension TrustwordsLanguage {
    init(pEpLanguage: PEPLanguage) {
        self.code = pEpLanguage.code
        self.name = pEpLanguage.name
        self.sentence = pEpLanguage.sentence
    }
}
