//
//  Language+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension Language {
    static func from(pEpLanguage: PEPLanguage) -> Language {
        return Language(code: pEpLanguage.code,
                        name: pEpLanguage.name,
                        sentence: pEpLanguage.sentence)
    }
}
