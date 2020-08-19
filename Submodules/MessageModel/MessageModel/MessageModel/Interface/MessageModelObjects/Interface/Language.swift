//
//  Language.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Wraps `PEPLanguage`, indicating a trustwords language.
public struct Language {
    /// ISO 639-1 language code
    public let code: String

    /// Name of the language.
    public let name: String

    /// Sentence of the form "I want to display the trustwords in <lang>".
    public let sentence: String
}
