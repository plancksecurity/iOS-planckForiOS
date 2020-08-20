//
//  Language.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// Wraps `PEPLanguage`, indicating a trustwords language.
public struct Language {
    /// ISO 639-1 language code
    public let code: String

    /// Name of the language
    public let name: String

    /// Sentence of the form "I want to display the trustwords in <lang>"
    public let sentence: String

    /// Retrieves all known languages, calling the completion block on the main queue.
    static public func languages(completion: @escaping ([Language]) -> ()) {
        PEPAsyncSession().languageList({ error in
            Log.shared.errorAndCrash("%@", error.localizedDescription)
            DispatchQueue.main.async {
                completion([])
            }
        }) { theLangs in
            DispatchQueue.main.async {
                completion(theLangs.map { Language(pEpLanguage: $0) })
            }
        }
    }
}
