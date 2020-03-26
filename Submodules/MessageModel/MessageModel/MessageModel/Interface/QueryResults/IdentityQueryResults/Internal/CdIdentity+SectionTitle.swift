//
//  CdIdentity+firstLetterOfName.swift
//  MessageModel
//
//  Created by Xavier Algarra on 09/10/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

// Mark: - CdIdentity+firstLetterOfName

extension CdIdentity {
    /// The first letter of the user name, or "#" if the first character
    /// is not a letter or empty, or there is no user name at all.
    private typealias UnicodeScalarValue = UInt32
    private typealias LetterToMapTo = String
    /// The first letter of the name if exists and actuall _is_ a letter, "#" otherwize.
    /// Used for FetchedResutlsController index its corresponding sections for displaying sorted
    /// identities.
    @objc
    var sectionTitle: String {
        get {
            // We have problems with different interpretation of certain characters. This method is
            // used to create the sections of a tableview which is sorted alphabethically.
            //
            // Example of problem:
            // This would return "Ｂ" (unicode scalar value 65314) for `userName` = "Ｂｉｔｃ０ｉｎ　Ｓｔｏｒｍ"
            // and thus a indevidual section with title "Ｂ" would be created in addition to the existing
            // "B" (normal B, unicode scalar value 66) section.
            //
            // Sorting the data using Core Data sort descriptor, the strange "Ｂ" (unicode scalar
            // value 65314) is interpreted as "B" (normal B, unicode scalar value 66), thus the
            // number of sections does not fit the data.
            //
            // Thus we are manually dealing with those problem charactes.
            let problemCharacterList: [UnicodeScalarValue:LetterToMapTo] =
                [65314:"B", //65314 is "Ｂ" (not "B")
                    223: "S"] // 223 i "ß"
            let sectionNameForNonAlphabeticCharacters = "#"
            guard let firstChar: String = userName?.prefix(ofLength: 1) else {
                return sectionNameForNonAlphabeticCharacters
            }
            let unicodeValue = firstChar.unicodeScalars.first?.value ?? 0

            if problemCharacterList.keys.contains(unicodeValue) {
                guard let result = problemCharacterList[unicodeValue] else {
                    Log.shared.errorAndCrash("No value for existing key")
                    return sectionNameForNonAlphabeticCharacters
                }
                return result
            } else if firstChar.isLetter, firstChar != "" {
                return firstChar.uppercased()
            } else {
                return "#"
            }
        }
    }
}
